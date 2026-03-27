//
//  ProjectAgentGenerationWindow.swift
//  AgentGen
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
import UniformTypeIdentifiers

/// Two-column agent generation window for project-level content creation.
///
/// The agent inspects specification sections via tool calls before producing final content.
/// Column 1: controls and activity feed. Column 2: generated content streaming in real time.
///
/// Inference logic is delegated to ``AgentInferenceBackend`` implementations
/// (e.g., ``AppleIntelligenceBackend``, ``OpenResponsesBackend``).
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
    @State private var selectedBackend: AgentBackend? = nil
    @State private var instructions: String = ""
    @State private var isRunning: Bool = false
    @State private var generatedContent: String = ""
    @State private var activityLog: [ActivityLogEntry] = []
    @State private var errorMessage: String? = nil
    @State private var showingError: Bool = false
    @State private var tokenUsageSummary: String = ""
    @State private var selectedReasoningEffort: ReasoningEffort? = .medium
    @State private var activeTask: Task<Void, Never>?
    @AppStorage("agentTelemetryEnabled") private var isTelemetryEnabled: Bool = false

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
                agentControlsColumn
                    .frame(minWidth: 320, idealWidth: 380)
                generatedContentColumn
                    .frame(minWidth: 350, idealWidth: 500)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            Divider()
            footerSection
        }
        .frame(minWidth: 800, idealWidth: 1000, minHeight: 600)
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
            Label("Project Agent", systemImage: "brain.fill")
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

    // MARK: - Column 1: Agent Controls

    private var agentControlsColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Controls")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            // Backend Picker
            VStack(alignment: .leading, spacing: 4) {
                Text("Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Select Model", selection: $selectedBackend) {
                    Text("Select Model").tag(nil as AgentBackend?)

                    Section("On-Device") {
                        if AppleIntelligenceBackend.isAvailable {
                            Text("Apple Intelligence").tag(AgentBackend.appleIntelligence as AgentBackend?)
                        } else {
                            Text("Apple Intelligence (Unavailable)").tag(nil as AgentBackend?)
                        }
                        ForEach(localLLMConnections, id: \.id) { connection in
                            Text(connection.name).tag(AgentBackend.cloudConnection(connection.id) as AgentBackend?)
                        }
                    }

                    if !cloudLLMConnections.isEmpty {
                        Section("Cloud Connections") {
                            ForEach(cloudLLMConnections, id: \.id) { connection in
                                Text(connection.name).tag(AgentBackend.cloudConnection(connection.id) as AgentBackend?)
                            }
                        }
                    }
                }
                .pickerStyle(.menu)
            }
            .padding(.horizontal)

            // Reasoning Effort Picker (cloud connections only)
            if isCloudBackendSelected {
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
            }

            // Instruments Telemetry Toggle (cloud connections only)
            if isCloudBackendSelected {
                Toggle("Enable Instruments Telemetry", isOn: $isTelemetryEnabled)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .disabled(isRunning)
                    .padding(.horizontal)
            }

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

            // Token Usage (cloud connections only — persistent summary)
            if isCloudBackendSelected, isRunning || !tokenUsageSummary.isEmpty {
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

            // Activity Feed
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Activity")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    if !activityLog.isEmpty {
                        Text("\(activityLog.count) events")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal)

                if isRunning {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text("Agent is working…")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                }

                ActivityLogView(entries: activityLog)
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
        llmConnections.filter { $0.isConfigured && $0.endpointType == .responses }
    }

    private var localLLMConnections: [LLMConnection] {
        configuredLLMConnections.filter { isLocalConnection($0) }
    }

    private var cloudLLMConnections: [LLMConnection] {
        configuredLLMConnections.filter { !isLocalConnection($0) }
    }

    private func isLocalConnection(_ connection: LLMConnection) -> Bool {
        guard let components = URLComponents(string: connection.baseUrl),
              let host = components.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1"
            || host == "0.0.0.0" || host == "::1" || host == "[::1]"
    }

    private var selectedLLMConnection: LLMConnection? {
        guard case .cloudConnection(let id) = selectedBackend else { return nil }
        return configuredLLMConnections.first { $0.id == id }
    }

    private var canRun: Bool {
        selectedBackend != nil && !isRunning && !sections.isEmpty
    }

    private var isCloudBackendSelected: Bool {
        if case .cloudConnection = selectedBackend { return true }
        return false
    }

    private var contentDisplayState: (text: String, isPlaceholder: Bool) {
        if isRunning && generatedContent.isEmpty {
            return ("Agent is running…", true)
        } else if generatedContent.isEmpty {
            return ("Generated content will appear here after the agent completes.", true)
        } else {
            return (generatedContent, false)
        }
    }

    // MARK: - Agent Execution

    private func runAgent() {
        guard canRun, let backend = selectedBackend else { return }

        activeTask?.cancel()
        activeTask = Task {
            resetRunState()

            let inferenceBackend = makeBackend(for: backend)
            let stream = inferenceBackend.run(
                projectName: projectName,
                systemPrompt: projectSystemPrompt,
                sections: sections,
                instructions: instructions
            )

            do {
                for try await event in stream {
                    guard !Task.isCancelled else { break }
                    handleEvent(event)
                }
            } catch {
                errorMessage = error.localizedDescription
                showingError = true
            }

            // Post-run side effects
            if case .cloudConnection(let id) = backend {
                if let conn = selectedLLMConnection {
                    conn.updateLastUsed()
                }
                onLLMSelectionChanged?(id)
            }

            isRunning = false
        }
    }

    private func resetRunState() {
        isRunning = true
        activityLog = []
        generatedContent = ""
        errorMessage = nil
        tokenUsageSummary = ""
    }

    // MARK: - Backend Factory

    private func makeBackend(for backend: AgentBackend) -> any AgentInferenceBackend {
        switch backend {
        case .appleIntelligence:
            return AppleIntelligenceBackend()
        case .cloudConnection(let id):
            guard let conn = configuredLLMConnections.first(where: { $0.id == id }) else {
                return FailingBackend(message: "Selected connection not found.")
            }
            let apiURL = conn.urlPath != nil
                ? conn.fullApiUrl
                : {
                    let base = conn.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
                    let baseWithoutSlash = base.hasSuffix("/") ? String(base.dropLast()) : base
                    return baseWithoutSlash + OpenAIEndpointType.responses.defaultPath
                }()
            let config = CloudConnectionConfig(
                apiURL: apiURL,
                apiKey: conn.apiKey,
                model: conn.selectedModel,
                requestTimeoutSeconds: conn.requestTimeoutSeconds,
                reasoningEffort: selectedReasoningEffort
            )
            let telemetry: any AgentBackendTelemetry = isTelemetryEnabled
                ? OpenResponsesTelemetry()
                : DisabledAgentTelemetry()
            return OpenResponsesBackend(config: config, telemetry: telemetry)
        }
    }

    // MARK: - Event Handling

    private func handleEvent(_ event: AgentEvent) {
        switch event {
        case .statusUpdate(let status):
            if !status.isEmpty {
                activityLog.append(ActivityLogEntry(kind: .status(status)))
            }

        case .toolCallStarted(_, let name, _):
            activityLog.append(ActivityLogEntry(kind: .status("→ \(name)")))

        case .toolCallCompleted:
            break

        case .contentDelta(let delta):
            generatedContent += delta

        case .thinkingBlock(let block):
            activityLog.append(ActivityLogEntry(kind: .thinkingBlock(block)))

        case .thinkingSummary(let summary):
            let isDuplicate = activityLog.contains {
                if case .thinkingSummary(let existing) = $0.kind { return existing == summary }
                return false
            }
            if !isDuplicate {
                activityLog.append(ActivityLogEntry(kind: .thinkingSummary(summary)))
            }

        case .tokenUsage(let snapshot):
            tokenUsageSummary = formatTokenUsage(snapshot)
            activityLog.append(ActivityLogEntry(kind: .tokenUsage(tokenUsageSummary)))

        case .activeToolChanged:
            break

        case .sectionRead:
            break

        case .completed(let content):
            generatedContent = content
            activityLog.append(ActivityLogEntry(kind: .completed))
            onContentGenerated(content)

        case .failed(let message):
            errorMessage = message
            showingError = true
            activityLog.append(ActivityLogEntry(kind: .failed(message)))
            if generatedContent.isEmpty {
                generatedContent = "[Error] \(message)"
            }
        }
    }

    // MARK: - Token Usage Formatting

    private func formatTokenUsage(_ snapshot: TokenUsageSnapshot) -> String {
        var parts = ["Input: \(snapshot.input)"]
        if snapshot.cached > 0 { parts[0] += " (\(snapshot.cached) cached)" }
        if snapshot.reasoning > 0 { parts.append("Reasoning: \(snapshot.reasoning)") }
        parts.append("Output: \(snapshot.output)")
        parts.append("Total: \(snapshot.input + snapshot.output)")
        return "Tokens — " + parts.joined(separator: " | ")
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
            selectedBackend = .cloudConnection(projectId)
        } else if let firstConnection = configuredLLMConnections.first {
            selectedBackend = .cloudConnection(firstConnection.id)
        } else if AppleIntelligenceBackend.isAvailable {
            selectedBackend = .appleIntelligence
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
}

// MARK: - Failing Backend

/// A backend that immediately yields a failure event. Used when configuration is invalid.
private struct FailingBackend: AgentInferenceBackend {
    let message: String

    func run(
        projectName: String,
        systemPrompt: String?,
        sections: [AgentSection],
        instructions: String
    ) -> AsyncThrowingStream<AgentEvent, any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(.failed(message))
            continuation.finish()
        }
    }
}
#endif
