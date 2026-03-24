//
//  AppleIntelligenceBackend.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import FoundationModels

/// On-device inference backend using Apple Intelligence (Foundation Models framework).
///
/// Uses `LanguageModelSession.respond()` (non-streaming) to avoid rate limiting.
/// The on-device model has a 4,096 token context window, so prompts are kept minimal
/// and the model uses tools to discover section content incrementally.
public struct AppleIntelligenceBackend: AgentInferenceBackend {

    /// Whether Apple Intelligence is available on this device.
    public static var isAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    public init() {}

    public func run(
        projectName: String,
        systemPrompt: String?,
        sections: [AgentSection],
        instructions: String
    ) -> AsyncThrowingStream<AgentEvent, any Error> {
        let (stream, continuation) = AsyncThrowingStream.makeStream(of: AgentEvent.self)

        let aiInstructions = Self.buildInstructions(
            projectName: projectName,
            systemPrompt: systemPrompt
        )
        let userMessage = Self.buildPrompt(
            sections: sections,
            instructions: instructions
        )
        Task { @MainActor in
            do {
                let tracker = SectionReadTracker()
                let tools = makeFoundationModelTools(
                    sections: sections,
                    systemPrompt: systemPrompt,
                    tracker: tracker
                )
                let session = LanguageModelSession(
                    tools: tools,
                    instructions: aiInstructions
                )

                continuation.yield(.statusUpdate("Apple Intelligence is generating…"))

                let response = try await session.respond(to: userMessage)
                let content = response.content

                guard !Task.isCancelled else {
                    continuation.finish()
                    return
                }

                continuation.yield(.statusUpdate(""))

                // Extract tool calls from the transcript
                for entry in session.transcript {
                    if case .toolCalls(let toolCalls) = entry {
                        for call in toolCalls {
                            let callId = UUID().uuidString
                            continuation.yield(.toolCallCompleted(
                                callId: callId,
                                name: call.toolName,
                                result: "",
                                duration: .zero
                            ))
                        }
                    }
                }

                // Report section reads from tracker
                for section in sections where section.isEnabled {
                    let unread = await tracker.unreadSections(from: [section])
                    if unread.isEmpty {
                        continuation.yield(.sectionRead(sectionName: section.name))
                    }
                }

                // Produce final content
                let finalContent: String
                if content.isEmpty {
                    finalContent = "[Apple Intelligence produced no content. The on-device model has a limited context window (4,096 tokens). Try with fewer sections or shorter instructions.]"
                } else {
                    finalContent = content
                }

                continuation.yield(.completed(finalContent))
                continuation.finish()

            } catch {
                let formatted = Self.formatError(error)
                continuation.yield(.failed(formatted))
                continuation.finish()
            }
        }

        return stream
    }

    // MARK: - Prompt Building

    private static func buildInstructions(projectName: String, systemPrompt: String?) -> String {
        var lines = [
            "You generate content for '\(projectName)'. Use tools to read sections, then write content.",
        ]
        if let sp = systemPrompt, !sp.isEmpty {
            lines.append("Context: \(sp)")
        }
        return lines.joined(separator: " ")
    }

    private static func buildPrompt(sections: [AgentSection], instructions: String) -> String {
        let enabledNames = sections.filter(\.isEnabled).map(\.name)
        let userInstructions = instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? "Generate content for this project."
            : instructions

        return [
            userInstructions,
            "Sections (\(enabledNames.count)): \(enabledNames.joined(separator: ", ")).",
            "Call listSections then readSection for each to get their content before writing.",
        ].joined(separator: " ")
    }

    // MARK: - Error Formatting

    private static func formatError(_ error: any Error) -> String {
        if let genError = error as? LanguageModelSession.GenerationError {
            switch genError {
            case .assetsUnavailable:
                return "Apple Intelligence model assets are unavailable. Check that Apple Intelligence is enabled in System Settings."
            case .exceededContextWindowSize:
                return "The request exceeded the on-device model's context window. Try with fewer or shorter specification sections."
            case .guardrailViolation:
                return "Apple Intelligence safety guardrails were triggered. Try rephrasing your instructions."
            case .rateLimited:
                return "Apple Intelligence is rate limited. Please wait a moment and try again."
            case .refusal:
                return "Apple Intelligence declined to generate content for this request. Try different instructions."
            case .concurrentRequests:
                return "Another Apple Intelligence request is already in progress. Please wait for it to complete."
            case .unsupportedGuide:
                return "An unsupported generation guide was used. This is an internal error."
            case .unsupportedLanguageOrLocale:
                return "Apple Intelligence does not support the current language or locale."
            case .decodingFailure:
                return "Apple Intelligence failed to produce a valid response. Try re-running."
            @unknown default:
                return "Apple Intelligence error: \(genError.localizedDescription)"
            }
        }
        if let toolError = error as? LanguageModelSession.ToolCallError {
            return "Tool '\(toolError.tool.name)' failed during Apple Intelligence execution: \(toolError.underlyingError.localizedDescription)"
        }
        return "Apple Intelligence error: \(error.localizedDescription)"
    }
}
