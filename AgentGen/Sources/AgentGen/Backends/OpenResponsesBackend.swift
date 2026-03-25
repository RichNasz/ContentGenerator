//
//  OpenResponsesBackend.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import Foundation
import SwiftOpenResponsesDSL
import SwiftLLMToolMacros

/// Cloud inference backend using the Open Responses API via SwiftOpenResponsesDSL.
///
/// Transforms `ToolSessionEvent` values from the DSL stream into `AgentEvent` values
/// that the view can consume without knowing the underlying API.
public struct OpenResponsesBackend: AgentInferenceBackend {

    private let config: CloudConnectionConfig
    private let telemetry: any AgentBackendTelemetry

    public init(
        config: CloudConnectionConfig,
        telemetry: any AgentBackendTelemetry = DisabledAgentTelemetry()
    ) {
        self.config = config
        self.telemetry = telemetry
    }

    public func run(
        projectName: String,
        systemPrompt: String?,
        sections: [AgentSection],
        instructions: String
    ) -> AsyncThrowingStream<AgentEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: AgentEvent.self)
        let config = self.config
        let telemetry = self.telemetry

        Task { @MainActor in
            do {
                let client = try LLMClient(
                    baseURL: config.apiURL,
                    apiKey: config.apiKey,
                    sessionConfiguration: telemetry.makeSessionConfiguration()
                )

                let tracker = SectionReadTracker()
                let agentTools = makeAgentTools(
                    sections: sections,
                    systemPrompt: systemPrompt,
                    tracker: tracker
                )
                let toolDefs = agentTools.map(\.tool)
                let handlers = Dictionary(
                    uniqueKeysWithValues: agentTools.map { ($0.tool.name, $0.handler) }
                )

                let enabledSections = sections.filter(\.isEnabled)
                let maxIterations = enabledSections.count + 5
                let session = ToolSession(
                    client: client,
                    tools: toolDefs,
                    maxIterations: maxIterations,
                    handlers: handlers
                )

                let userInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Please review the specification sections and generate comprehensive content for this project."
                    : instructions
                let manifest = XMLSpecFormatter.formatSectionManifest(sections: sections)
                let xmlSpec = XMLSpecFormatter.formatSectionsAsXML(sections: sections)
                let userMessage = [
                    userInstructions,
                    manifest,
                    "Project Specification:\n\n\(xmlSpec)",
                    manifest,
                    "Ensure every section listed above is addressed in your response. If any section's content could not be parsed from the XML above, use the read_section_tool to retrieve it.",
                ].joined(separator: "\n\n")

                let validRequestTimeout = max(10, min(900, TimeInterval(config.requestTimeoutSeconds)))
                let validResourceTimeout = max(30, min(3600, TimeInterval(config.requestTimeoutSeconds)))
                let builtSystemPrompt = Self.buildSystemPrompt(projectName: projectName, systemPrompt: systemPrompt)
                var configParams: [ResponseConfigParameter] = [
                    try RequestTimeout(validRequestTimeout),
                    try ResourceTimeout(validResourceTimeout),
                    try Instructions(builtSystemPrompt),
                ]
                if let effort = config.reasoningEffort {
                    configParams.append(Reasoning(effort: effort, summary: .auto))
                }

                telemetry.promptSent(systemPrompt: builtSystemPrompt, userMessage: userMessage)

                let toolStream = session.stream(
                    model: config.model,
                    input: [
                        User(userMessage),
                    ],
                    configParams: configParams
                )

                var cumulativeInput = 0
                var cumulativeOutput = 0
                var cumulativeReasoning = 0
                var cumulativeCached = 0
                var iterationCount = 0
                var generatedContent = ""

                telemetry.runBegan(
                    projectName: projectName,
                    model: config.model,
                    maxIterations: maxIterations
                )

                for try await event in toolStream {
                    guard !Task.isCancelled else { break }

                    switch event {
                    case .iterationStarted(let n):
                        if n > 1 { telemetry.iterationEnded(n - 1) }
                        telemetry.iterationBegan(n)
                        Self.extractCompletedThinkBlocks(from: &generatedContent, continuation: continuation)
                        iterationCount = n
                        continuation.yield(.statusUpdate("Thinking (iteration \(n))…"))
                        generatedContent = ""

                    case .toolCallStarted(let callId, let name, let arguments):
                        telemetry.toolCallBegan(name: name, callId: callId)
                        continuation.yield(.activeToolChanged(name))
                        continuation.yield(.statusUpdate("Calling \(name)…"))
                        continuation.yield(.toolCallStarted(callId: callId, name: name, arguments: arguments))

                    case .toolCallCompleted(let callId, let name, let output, let duration):
                        telemetry.toolCallEnded(name: name, callId: callId, duration: duration)
                        continuation.yield(.activeToolChanged(nil))
                        continuation.yield(.statusUpdate("Tool \(name) finished. Waiting for model…"))
                        continuation.yield(.toolCallCompleted(callId: callId, name: name, result: output, duration: duration))
                        if name == "read_section_tool" {
                            if let data = output.data(using: .utf8),
                               let parsed = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let sectionName = parsed["sectionName"] as? String {
                                continuation.yield(.sectionRead(sectionName: sectionName))
                            }
                        }

                    case .llm(let streamEvent):
                        Self.processLLMEvent(
                            streamEvent,
                            generatedContent: &generatedContent,
                            continuation: continuation,
                            telemetry: telemetry
                        )

                    case .usageUpdate(let usage, let iteration):
                        cumulativeInput += usage.inputTokens
                        cumulativeOutput += usage.outputTokens
                        cumulativeReasoning += usage.outputTokensDetails?.reasoningTokens ?? 0
                        cumulativeCached += usage.inputTokensDetails?.cachedTokens ?? 0
                        telemetry.tokenUsageUpdated(
                            iteration: iteration,
                            inputTokens: usage.inputTokens,
                            outputTokens: usage.outputTokens,
                            reasoningTokens: usage.outputTokensDetails?.reasoningTokens ?? 0,
                            cachedTokens: usage.inputTokensDetails?.cachedTokens ?? 0
                        )
                        continuation.yield(.tokenUsage(TokenUsageSnapshot(
                            input: cumulativeInput,
                            output: cumulativeOutput,
                            reasoning: cumulativeReasoning,
                            cached: cumulativeCached
                        )))
                    }
                }

                if iterationCount > 0 { telemetry.iterationEnded(iterationCount) }
                telemetry.runEnded(
                    totalIterations: iterationCount,
                    totalInputTokens: cumulativeInput,
                    totalOutputTokens: cumulativeOutput
                )

                continuation.yield(.activeToolChanged(nil))
                continuation.yield(.statusUpdate(""))

                // Final post-processing
                let finalContent: String
                if !generatedContent.isEmpty {
                    let parsed = generatedContent.extractingThinkingBlocks()
                    for block in parsed.thinkingBlocks {
                        continuation.yield(.thinkingBlock(block))
                    }
                    if parsed.content.isEmpty && !parsed.thinkingBlocks.isEmpty {
                        finalContent = "[Model produced only reasoning content with no final output. See the Thinking Process panel above.]"
                    } else {
                        finalContent = parsed.content
                    }
                    if !parsed.thinkingBlocks.isEmpty {
                        for block in parsed.thinkingBlocks {
                            continuation.yield(.thinkingSummary(block))
                        }
                    }
                } else {
                    finalContent = """
                        [Agent completed tool call(s) across \
                        \(iterationCount) iteration(s) but produced no text content. \
                        The model returned an empty response. Try re-running, or check \
                        whether the model supports multi-turn tool calling.]
                        """
                }

                continuation.yield(.completed(finalContent))
                continuation.finish()

            } catch let error as LLMError {
                telemetry.runFailed(reason: Self.formatLLMError(error))
                continuation.yield(.failed(Self.formatLLMError(error)))
                continuation.finish()
            } catch {
                telemetry.runFailed(reason: error.localizedDescription)
                continuation.yield(.failed(error.localizedDescription))
                continuation.finish()
            }
        }

        return stream
    }

    // MARK: - LLM Stream Event Processing

    private static func processLLMEvent(
        _ streamEvent: StreamEvent,
        generatedContent: inout String,
        continuation: AsyncThrowingStream<AgentEvent, any Error>.Continuation,
        telemetry: any AgentBackendTelemetry
    ) {
        switch streamEvent {
        case .contentPartDelta(let delta, _, _):
            generatedContent += delta
            telemetry.contentDeltaReceived(characterCount: delta.count)
            continuation.yield(.contentDelta(delta))
            extractCompletedThinkBlocks(from: &generatedContent, continuation: continuation)

        case .outputItemDone(let item, _):
            if case .reasoning(let reasoningItem) = item {
                if let content = reasoningItem.contentText, !content.isEmpty {
                    continuation.yield(.thinkingBlock(content))
                }
                if let summaries = reasoningItem.summary {
                    for summary in summaries {
                        continuation.yield(.thinkingSummary(summary.text))
                    }
                }
            } else if case .message(let msg) = item {
                for content in msg.content {
                    if case .outputText(let textContent) = content {
                        let parsed = textContent.text.extractingThinkingBlocks()
                        for block in parsed.thinkingBlocks {
                            continuation.yield(.thinkingSummary(block))
                        }
                    }
                }
            }

        case .responseCompleted(let response):
            for item in response.output {
                if case .reasoning(let reasoningItem) = item,
                   let summaries = reasoningItem.summary {
                    for summary in summaries {
                        continuation.yield(.thinkingSummary(summary.text))
                    }
                } else if case .message(let msg) = item {
                    for content in msg.content {
                        if case .outputText(let textContent) = content {
                            let parsed = textContent.text.extractingThinkingBlocks()
                            for block in parsed.thinkingBlocks {
                                continuation.yield(.thinkingSummary(block))
                            }
                        }
                    }
                }
            }

        case .reasoningSummaryPartAdded:
            break

        case .reasoningSummaryPartDone(let part, _, _):
            let summary = part.text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !summary.isEmpty {
                continuation.yield(.thinkingSummary(summary))
            }

        default:
            break
        }
    }

    // MARK: - Think Block Extraction

    /// Extracts completed `<think>...</think>` blocks from content during streaming.
    private static func extractCompletedThinkBlocks(
        from content: inout String,
        continuation: AsyncThrowingStream<AgentEvent, any Error>.Continuation
    ) {
        let closeTag = "</think>"
        while let closeRange = content.range(of: closeTag, options: .caseInsensitive) {
            let prefix = String(content[content.startIndex..<closeRange.lowerBound])
            let openTag = "<think>"
            if let openRange = prefix.range(of: openTag, options: .caseInsensitive) {
                let thinking = String(prefix[openRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinking.isEmpty {
                    continuation.yield(.thinkingSummary(thinking))
                }
                let beforeOpen = String(content[content.startIndex..<openRange.lowerBound])
                let afterClose = String(content[closeRange.upperBound...])
                content = beforeOpen + afterClose
            } else {
                break
            }
        }
    }

    // MARK: - Prompt Building

    private static func buildSystemPrompt(projectName: String, systemPrompt: String?) -> String {
        var lines = [
            "You are an AI agent generating content for the project '\(projectName)'.",
            "",
            "The full project specification is included in the first user message as XML-wrapped sections,",
            "along with a manifest listing all enabled section names and their count.",
            "",
            "Tools available (use only if a section is missing or unparseable):",
            "  - list_sections_tool: lists all sections with names and enabled status",
            "  - read_section_tool: reads content, generation prompt, and usage prompt for a named section",
            "  - read_system_prompt_tool: reads the project system prompt for additional context",
            "  - get_unread_sections_tool: returns names of enabled sections not yet read via read_section_tool",
        ]

        if let sp = systemPrompt, !sp.isEmpty {
            lines += ["", "Project System Prompt:", sp]
        }

        lines += [
            "",
            "Parse the XML sections, verify the count matches the manifest, and generate content addressing every section.",
            "If any section is missing or unparseable, call read_section_tool before generating.",
        ]

        return lines.joined(separator: "\n")
    }

    // MARK: - Error Formatting

    private static func formatLLMError(_ error: LLMError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL. Check the LLM connection settings."
        case .encodingFailed(let msg):
            return "Request encoding failed: \(msg)"
        case .networkError(let msg):
            return "Network error: \(msg)"
        case .decodingFailed(let msg):
            return "Response decoding failed: \(msg)"
        case .serverError(let code, let msg):
            return "Server error (\(code)): \(msg ?? "Unknown")"
        case .rateLimit:
            return "Rate limit exceeded. Please wait and try again."
        case .invalidResponse:
            return "Invalid response from server."
        case .invalidValue(let msg):
            return "Invalid parameter: \(msg)"
        case .missingBaseURL:
            return "Base URL is missing. Check the LLM connection settings."
        case .missingModel:
            return "Model name is missing. Check the LLM connection settings."
        case .maxIterationsExceeded(let n):
            return "Agent exceeded maximum tool iterations (\(n)). Try a simpler request."
        case .unknownTool(let name):
            let quoted = name.debugDescription
            return "Unknown tool requested: \(quoted). This model may format tool names differently from what is registered."
        case .toolExecutionFailed(let tool, let msg):
            return "Tool '\(tool)' failed: \(msg)"
        }
    }
}
#endif
