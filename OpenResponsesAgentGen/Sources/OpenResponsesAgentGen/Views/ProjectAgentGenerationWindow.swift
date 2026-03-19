//
//  ProjectAgentGenerationWindow.swift
//  OpenResponsesAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import SwiftUI
import SwiftData
import LLMmanagement
import SwiftOpenResponsesDSL
import SwiftLLMToolMacros
import UniformTypeIdentifiers

/// Three-column agent generation window for project-level content creation using the Open Responses API.
///
/// The agent inspects specification sections via tool calls before producing final content.
/// Column 1: project overview (readonly). Column 2: LLM controls and tool call log.
/// Column 3: generated content.
public struct ProjectAgentGenerationWindow: View {
    public let projectName: String
    public let projectSystemPrompt: String?
    public let projectLLMConnectionId: UUID?
    public let sections: [AgentSection]
    public let onContentGenerated: (String) -> Void
    public let onLLMSelectionChanged: ((UUID?) -> Void)?

    @Environment(\.dismissWindow) private var dismissWindow

    private let modelContext: ModelContext
    @State private var llmConnections: [LLMConnection] = []
    @State private var selectedLLMId: UUID?
    @State private var instructions: String = ""
    @State private var isRunning: Bool = false
    @State private var generatedContent: String = ""
    @State private var toolCallLog: [LocalToolCallLogEntry] = []
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false
    @State private var thinkingBlocks: [String] = []
    @State private var hasThinkingContent: Bool = false
    @State private var tokenUsageSummary: String = ""
    @State private var liveStatus: String = ""
    @State private var activeToolName: String? = nil
    @State private var pendingToolArgs: [String: String] = [:]
    @State private var sectionReadCounts: [String: Int] = [:]
    @State private var thinkingSummaries: [String] = []
    @State private var selectedReasoningEffort: ReasoningEffort? = .medium
    @State private var cumulativeReasoning: Int = 0
    @State private var cumulativeCached: Int = 0

    public init(
        projectName: String,
        projectSystemPrompt: String?,
        projectLLMConnectionId: UUID?,
        sections: [AgentSection],
        modelContext: ModelContext,
        onContentGenerated: @escaping (String) -> Void,
        onLLMSelectionChanged: ((UUID?) -> Void)? = nil
    ) {
        self.projectName = projectName
        self.projectSystemPrompt = projectSystemPrompt
        self.projectLLMConnectionId = projectLLMConnectionId
        self.sections = sections
        self.modelContext = modelContext
        self.onContentGenerated = onContentGenerated
        self.onLLMSelectionChanged = onLLMSelectionChanged
    }

    // MARK: - Body

    public var body: some View {
        VStack(spacing: 0) {
            headerSection
            Divider()
            HSplitView {
                projectOverviewColumn
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)
                agentControlsColumn
                    .frame(minWidth: 300, idealWidth: 350)
                generatedContentColumn
                    .frame(minWidth: 350, idealWidth: 450)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footerSection
        }
        .frame(minWidth: 1000, idealWidth: 1200, minHeight: 700)
        .task {
            loadLLMConnections()
            initializeLLMSelection()
            if instructions.isEmpty {
                instructions = "Please review the specification sections and generate comprehensive content for this project."
            }
        }
        .alert("Generation Error", isPresented: $showingError) {
            Button("OK") { showingError = false }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Project Agent (Responses)", systemImage: "brain.fill")
                .font(.title2)
                .fontWeight(.semibold)
            Text("Agent-assisted generation for: \(projectName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Column 1: Project Overview

    private var projectOverviewColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Project Overview")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("System Prompt")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text(projectSystemPrompt?.isEmpty == false ? projectSystemPrompt! : "No system prompt configured")
                        .font(.caption)
                        .foregroundStyle(projectSystemPrompt?.isEmpty == false ? .primary : .secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Specification Sections (\(sections.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    ForEach(sections, id: \.name) { section in
                        HStack(spacing: 6) {
                            Image(systemName: section.isEnabled ? "checkmark.circle.fill" : "circle")
                                .font(.caption2)
                                .foregroundStyle(section.isEnabled ? .green : .secondary)
                            Text(section.name)
                                .font(.caption)
                                .foregroundStyle(section.isEnabled ? .primary : .secondary)
                            Spacer()
                            if let count = sectionReadCounts[section.name], count > 0 {
                                Text("\(count)×")
                                    .font(.caption2)
                                    .monospacedDigit()
                                    .foregroundStyle(.blue)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(.blue.opacity(0.12), in: Capsule())
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }

    // MARK: - Column 2: Agent Controls

    private var agentControlsColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Agent Controls")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            // LLM Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("LLM Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Select LLM", selection: $selectedLLMId) {
                    Text("Select Model").tag(nil as UUID?)
                    ForEach(configuredLLMConnections, id: \.id) { connection in
                        Text(connection.name).tag(connection.id as UUID?)
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            // Reasoning Effort Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Reasoning Effort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Reasoning Effort", selection: $selectedReasoningEffort) {
                    Text("None").tag(Optional<ReasoningEffort>.none)
                    Text("Low").tag(Optional<ReasoningEffort>.some(.low))
                    Text("Medium").tag(Optional<ReasoningEffort>.some(.medium))
                    Text("High").tag(Optional<ReasoningEffort>.some(.high))
                    Text("xHigh").tag(Optional<ReasoningEffort>.some(.xhigh))
                }
                .pickerStyle(.menu)
                .disabled(isRunning)
            }
            .padding(.horizontal)

            // Instructions
            VStack(alignment: .leading, spacing: 4) {
                Text("Instructions")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $instructions)
                    .font(.body)
                    .frame(minHeight: 80, maxHeight: 120)
                    .padding(4)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
            }
            .padding(.horizontal)

            // Run Button
            Button(action: runAgent) {
                HStack(spacing: 8) {
                    if isRunning {
                        ProgressView().scaleEffect(0.8)
                        Text("Running Agent...")
                    } else {
                        Image(systemName: "brain.fill")
                        Text("Run Agent")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canRun)
            .padding(.horizontal)

            // Token Usage (live during generation, final after completion)
            if isRunning || !tokenUsageSummary.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "gauge.with.dots.needle.33percent")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text(tokenUsageSummary.isEmpty ? "Waiting for first iteration…" : tokenUsageSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
            }

            // Live Thinking Steps
            if !thinkingSummaries.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Thinking Steps")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)

                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 4) {
                            ForEach(Array(thinkingSummaries.enumerated()), id: \.offset) { index, summary in
                                HStack(alignment: .top, spacing: 6) {
                                    Image(systemName: "brain")
                                        .font(.caption)
                                        .foregroundStyle(.purple)
                                    Text("\(index + 1). \(summary)")
                                        .font(.caption2)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(6)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    }
                    .frame(maxHeight: 150)
                    .background(Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal)
                }
            }

            // Tool Call Log
            VStack(alignment: .leading, spacing: 4) {
                Text("Tool Call Log")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                AgentToolCallLogView(entries: toolCallLog, inProgressTool: activeToolName)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
                    .padding(.horizontal)
            }

            Spacer()
        }
        .padding(.bottom)
    }

    // MARK: - Column 3: Generated Content

    private var generatedContentColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Content")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            if hasThinkingContent {
                ThinkingBlockView(blocks: thinkingBlocks)
                    .padding(.horizontal)
            }

            ScrollView {
                let state = contentDisplayState
                Text(state.text)
                    .font(.body)
                    .foregroundStyle(state.isPlaceholder ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(Color.secondary.opacity(0.04), in: RoundedRectangle(cornerRadius: 6))
            .padding(.horizontal)
            .padding(.bottom)
        }
    }

    // MARK: - Footer

    private var footerSection: some View {
        HStack {
            Spacer()

            if !generatedContent.isEmpty {
                Button("Save to File") { saveGeneratedContent() }
                    .buttonStyle(.bordered)
                Button("Copy to Clipboard") { copyToClipboard() }
                    .buttonStyle(.bordered)
            }

            Button("Done") { dismissWindow() }
                .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    private var configuredLLMConnections: [LLMConnection] {
        llmConnections.filter { $0.isConfigured }
    }

    private var selectedLLMConnection: LLMConnection? {
        guard let id = selectedLLMId else { return nil }
        return configuredLLMConnections.first { $0.id == id }
    }

    private var canRun: Bool {
        selectedLLMId != nil && !isRunning && !sections.isEmpty
    }

    /// Text and placeholder state for the generated content column while running or idle.
    private var contentDisplayState: (text: String, isPlaceholder: Bool) {
        if isRunning && generatedContent.isEmpty {
            let text = liveStatus.isEmpty ? "Agent is starting…" : liveStatus
            return (text, true)
        } else if generatedContent.isEmpty {
            return ("Generated content will appear here after the agent completes.", true)
        } else {
            return (generatedContent, false)
        }
    }

    // MARK: - Agent Execution

    private func runAgent() {
        guard canRun, let llmConnection = selectedLLMConnection else { return }

        Task {
            isRunning = true
            toolCallLog = []
            generatedContent = ""
            thinkingBlocks = []
            hasThinkingContent = false
            errorMessage = nil
            tokenUsageSummary = ""
            liveStatus = ""
            activeToolName = nil
            pendingToolArgs = [:]
            sectionReadCounts = [:]
            thinkingSummaries = []
            cumulativeReasoning = 0
            cumulativeCached = 0

            do {
                // Always use the Responses API path, regardless of the connection's endpointType
                let responsesUrl = llmConnection.urlPath != nil
                    ? llmConnection.fullApiUrl
                    : {
                        let base = llmConnection.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                        let baseWithoutSlash = base.hasSuffix("/") ? String(base.dropLast()) : base
                        return baseWithoutSlash + OpenAIEndpointType.responses.defaultPath
                    }()
                let client = try LLMClient(
                    baseURL: responsesUrl,
                    apiKey: llmConnection.apiKey
                )

                let tracker = SectionReadTracker()
                let agentTools = makeAgentTools(
                    sections: sections,
                    systemPrompt: projectSystemPrompt,
                    tracker: tracker
                )
                let toolDefs = agentTools.map(\.tool)
                let handlers = Dictionary(
                    uniqueKeysWithValues: agentTools.map { ($0.tool.name, $0.handler) }
                )

                let session = ToolSession(
                    client: client,
                    tools: toolDefs,
                    maxIterations: (sections.filter(\.isEnabled).count * 2) + 5,
                    handlers: handlers
                )

                let userMessage = instructions.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    ? "Please review the specification sections and generate comprehensive content for this project."
                    : instructions

                let validRequestTimeout = max(10, min(900, TimeInterval(llmConnection.requestTimeoutSeconds)))
                let validResourceTimeout = max(30, min(3600, TimeInterval(llmConnection.requestTimeoutSeconds)))
                var configParams: [ResponseConfigParameter] = [
                    try RequestTimeout(validRequestTimeout),
                    try ResourceTimeout(validResourceTimeout),
                    try Instructions(buildSystemPrompt()),
                ]
                if let effort = selectedReasoningEffort {
                    configParams.append(Reasoning(effort: effort, summary: .auto))
                }

                let stream = session.stream(
                    model: llmConnection.selectedModel,
                    input: [
                        User(userMessage),
                    ],
                    configParams: configParams
                )

                var cumulativeInput = 0
                var cumulativeOutput = 0
                var iterationUsages: [(iteration: Int, usage: ResponseObject.Usage)] = []
                var iterationCount = 0

                for try await event in stream {
                    switch event {
                    case .iterationStarted(let n):
                        extractCompletedThinkBlocks()
                        iterationCount = n
                        liveStatus = "Thinking (iteration \(n))…"
                        generatedContent = ""

                    case .toolCallStarted(let callId, let name, let arguments):
                        activeToolName = name
                        liveStatus = "Calling \(name)…"
                        pendingToolArgs[callId] = arguments

                    case .toolCallCompleted(let callId, let name, let output, let duration):
                        if activeToolName == name { activeToolName = nil }
                        liveStatus = "Tool \(name) finished. Waiting for model…"
                        let args = pendingToolArgs.removeValue(forKey: callId) ?? ""
                        toolCallLog.append(LocalToolCallLogEntry(
                            name: name,
                            arguments: args,
                            result: output,
                            duration: duration
                        ))
                        if name == "read_section_tool" {
                            if let data = args.data(using: .utf8),
                               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                               let sectionName = json["sectionName"] as? String {
                                sectionReadCounts[sectionName, default: 0] += 1
                            }
                        }

                    case .llm(let streamEvent):
                        switch streamEvent {
                        case .contentPartDelta(let delta, _, _):
                            generatedContent += delta
                            // Live extraction of completed <think> blocks
                            extractCompletedThinkBlocks()
                        case .outputItemDone(let item, _):
                            if case .reasoning(let reasoningItem) = item {
                                // Prefer contentText (full reasoning) for thinkingBlocks display
                                if let content = reasoningItem.contentText, !content.isEmpty {
                                    thinkingBlocks.append(content)
                                    hasThinkingContent = true
                                }
                                // Still capture summaries for the Thinking Steps panel
                                if let summaries = reasoningItem.summary {
                                    for summary in summaries {
                                        thinkingSummaries.append(summary.text)
                                    }
                                }
                            } else if case .message(let msg) = item {
                                for content in msg.content {
                                    if case .outputText(let textContent) = content {
                                        let parsed = textContent.text.extractingThinkingBlocks()
                                        thinkingSummaries.append(contentsOf: parsed.thinkingBlocks)
                                    }
                                }
                            }
                        case .responseCompleted(let response):
                            for item in response.output {
                                if case .reasoning(let reasoningItem) = item,
                                   let summaries = reasoningItem.summary {
                                    for summary in summaries {
                                        if !thinkingSummaries.contains(summary.text) {
                                            thinkingSummaries.append(summary.text)
                                        }
                                    }
                                } else if case .message(let msg) = item {
                                    for content in msg.content {
                                        if case .outputText(let textContent) = content {
                                            let parsed = textContent.text.extractingThinkingBlocks()
                                            for block in parsed.thinkingBlocks {
                                                if !thinkingSummaries.contains(block) {
                                                    thinkingSummaries.append(block)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        case .reasoningSummaryPartAdded:
                            break
                        case .reasoningSummaryPartDone(let part, _, _):
                            let summary = part.text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if !summary.isEmpty && !thinkingSummaries.contains(summary) {
                                thinkingSummaries.append(summary)
                            }
                        default:
                            break
                        }

                    case .usageUpdate(let usage, let iteration):
                        cumulativeInput += usage.inputTokens
                        cumulativeOutput += usage.outputTokens
                        let reasoning = usage.outputTokensDetails?.reasoningTokens ?? 0
                        let cached = usage.inputTokensDetails?.cachedTokens ?? 0
                        cumulativeReasoning += reasoning
                        cumulativeCached += cached
                        iterationUsages.append((iteration, usage))

                        var parts = ["Input: \(cumulativeInput)"]
                        if cumulativeCached > 0 { parts[0] += " (\(cumulativeCached) cached)" }
                        if cumulativeReasoning > 0 { parts.append("Reasoning: \(cumulativeReasoning)") }
                        parts.append("Output: \(cumulativeOutput)")
                        parts.append("Total: \(cumulativeInput + cumulativeOutput)")
                        tokenUsageSummary = "Tokens — " + parts.joined(separator: " | ")
                    }
                }

                activeToolName = nil
                liveStatus = ""

                // Extract thinking blocks from accumulated content
                if !generatedContent.isEmpty {
                    let parsed = generatedContent.extractingThinkingBlocks()
                    // Append <think>-tag blocks to any structured reasoning already collected
                    thinkingBlocks.append(contentsOf: parsed.thinkingBlocks)
                    hasThinkingContent = !thinkingBlocks.isEmpty
                    let finalContent = parsed.content.isEmpty && !thinkingBlocks.isEmpty
                        ? "[Model produced only reasoning content with no final output. See the Thinking Process panel above.]"
                        : parsed.content
                    generatedContent = finalContent
                    if thinkingSummaries.isEmpty && !thinkingBlocks.isEmpty {
                        thinkingSummaries = thinkingBlocks
                    }
                } else {
                    generatedContent = """
                        [Agent completed \(toolCallLog.count) tool call(s) across \
                        \(iterationCount) iteration(s) but produced no text content. \
                        The model returned an empty response. Try re-running, or check \
                        whether the model supports multi-turn tool calling.]
                        """
                }

                let totalTokens = cumulativeInput + cumulativeOutput
                if totalTokens > 0 {
                    tokenUsageSummary = "Input: \(cumulativeInput) | Output: \(cumulativeOutput) | Total: \(totalTokens) tokens (\(iterationUsages.count) iterations)"
                } else {
                    tokenUsageSummary = "Token usage unavailable"
                }

                llmConnection.updateLastUsed()
                onContentGenerated(generatedContent)
                onLLMSelectionChanged?(selectedLLMId)

            } catch let error as LLMError {
                activeToolName = nil
                liveStatus = ""
                errorMessage = formatLLMError(error)
                showingError = true
            } catch {
                activeToolName = nil
                liveStatus = ""
                errorMessage = error.localizedDescription
                showingError = true
            }

            isRunning = false
        }
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt() -> String {
        var lines = [
            "You are an AI agent generating content for the project '\(projectName)'.",
            "",
            "You MUST follow these steps in order:",
            "  1. Call list_sections_tool to get the full list of sections and their enabled status.",
            "  2. For EVERY section where isEnabled is true, call read_section_tool with that section's name.",
            "  3. Call get_unread_sections_tool. If it returns any section names, read each of them with",
            "     read_section_tool, then call get_unread_sections_tool again. Repeat until it returns [].",
            "  4. Only after get_unread_sections_tool returns [] may you write your final comprehensive response.",
            "",
            "Optionally call read_system_prompt_tool at any point for additional project context.",
            "",
            "Tools available:",
            "  - list_sections_tool: lists all sections with names and enabled status",
            "  - read_section_tool: reads content, generation prompt, and usage prompt for a named section",
            "  - read_system_prompt_tool: reads the project system prompt for additional context",
            "  - get_unread_sections_tool: returns names of enabled sections not yet read via read_section_tool; empty array means all have been read",
        ]

        if let sp = projectSystemPrompt, !sp.isEmpty {
            lines += ["", "Project System Prompt:", sp]
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Data Loading

    private func loadLLMConnections() {
        let descriptor = FetchDescriptor<LLMConnection>(
            sortBy: [SortDescriptor(\LLMConnection.name)]
        )
        llmConnections = (try? modelContext.fetch(descriptor)) ?? []
    }

    // MARK: - Initialization

    private func initializeLLMSelection() {
        if let projectId = projectLLMConnectionId,
           configuredLLMConnections.contains(where: { $0.id == projectId }) {
            selectedLLMId = projectId
        } else {
            selectedLLMId = configuredLLMConnections.first?.id
        }
    }

    // MARK: - Export

    private func saveGeneratedContent() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [UTType.plainText]
        panel.nameFieldStringValue = "\(projectName)_agent_generated.md"
        panel.title = "Save Generated Content"
        panel.prompt = "Save"

        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            do {
                try generatedContent.write(to: url, atomically: true, encoding: .utf8)
            } catch {
                errorMessage = "Failed to save: \(error.localizedDescription)"
                showingError = true
            }
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedContent, forType: .string)
    }

    // MARK: - Live Think Block Extraction

    /// Extracts completed `<think>...</think>` blocks from `generatedContent` into `thinkingSummaries` during streaming.
    private func extractCompletedThinkBlocks() {
        let closeTag = "</think>"
        while let closeRange = generatedContent.range(of: closeTag, options: .caseInsensitive) {
            let prefix = String(generatedContent[generatedContent.startIndex..<closeRange.lowerBound])
            let openTag = "<think>"
            if let openRange = prefix.range(of: openTag, options: .caseInsensitive) {
                let thinking = String(prefix[openRange.upperBound...])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinking.isEmpty {
                    thinkingSummaries.append(thinking)
                }
                // Remove the entire <think>...</think> block from generatedContent
                let beforeOpen = String(generatedContent[generatedContent.startIndex..<openRange.lowerBound])
                let afterClose = String(generatedContent[closeRange.upperBound...])
                generatedContent = beforeOpen + afterClose
            } else {
                // Malformed — close tag without open tag, stop processing
                break
            }
        }
    }

    // MARK: - Error Formatting

    private func formatLLMError(_ error: LLMError) -> String {
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
