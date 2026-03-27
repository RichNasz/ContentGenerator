//
//  ProjectContentGenerationWindow.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData
import LLMmanagement
import SwiftChatCompletionsDSL
import SwiftOpenResponsesDSL
import UniformTypeIdentifiers

/// Window for LLM-assisted content generation for entire projects
struct ProjectContentGenerationWindow: View {
    let projectName: String
    let projectSystemPrompt: String?
    let projectLLMConnectionId: UUID?
    let projectMarkdownContent: String
    let onContentGenerated: (String) -> Void
    let onLLMSelectionChanged: ((UUID?) -> Void)?
    @Environment(\.dismissWindow) private var dismissWindow

    // Query for available LLM connections
    @Query(sort: \LLMConnection.name) private var llmConnections: [LLMConnection]

    @State private var generatedContent: String = ""
    @State private var isGenerating: Bool = false
    @State private var selectedLLMId: UUID?
    @State private var errorMessage: String?
    @State private var showingError: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Main content area
            HSplitView {
                // Column 1: Project Overview (readonly)
                projectOverviewColumn
                    .frame(minWidth: 300, idealWidth: 400, maxWidth: 500)

                // Column 2: LLM Controls
                llmControlsColumn
                    .frame(minWidth: 350, idealWidth: 400)

                // Column 3: Generated Content
                generatedContentColumn
                    .frame(minWidth: 400, idealWidth: 500)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with action buttons
            footerSection
        }
        .frame(minWidth: 1000, idealWidth: 1400, idealHeight: 700)
        .task {
            initializeLLMSelection()
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") {
                showingError = false
            }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
    }

    // MARK: - Computed Properties

    /// Returns only configured LLM connections that are ready to use
    private var configuredLLMConnections: [LLMConnection] {
        llmConnections.filter { $0.isConfigured }
    }

    /// Validates whether the currently selected LLM connection is valid
    private var isSelectedLLMValid: Bool {
        guard let selectedId = selectedLLMId else {
            return false
        }
        return configuredLLMConnections.contains { $0.id == selectedId }
    }

    /// Returns the selected LLM connection if valid
    private var selectedLLMConnection: LLMConnection? {
        guard let selectedId = selectedLLMId else { return nil }
        return configuredLLMConnections.first { $0.id == selectedId }
    }

    /// Determines if generation can proceed
    private var canGenerate: Bool {
        return isSelectedLLMValid && !isGenerating
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Project Content Assistant", systemImage: "sparkles")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Generate content for project: \(projectName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Project Overview Column

    private var projectOverviewColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Project Overview")
                    .font(.headline)

                Text("System Prompt:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let systemPrompt = projectSystemPrompt, !systemPrompt.isEmpty {
                    Text(systemPrompt)
                        .font(.body)
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                } else {
                    Text("No system prompt configured")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .italic()
                        .padding(8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .cornerRadius(6)
                }

                Text("Project Specification:")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(projectMarkdownContent.isEmpty ? "No specification content" : projectMarkdownContent)
                    .font(.body)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .cornerRadius(6)
                    .textSelection(.enabled)
            }
            .padding()
        }
    }

    // MARK: - LLM Controls Column

    private var llmControlsColumn: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("LLM Controls")
                .font(.headline)

            // LLM Selection
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

            // Generate button
            Button(action: generateContent) {
                HStack(spacing: 8) {
                    if isGenerating {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Generating...")
                    } else {
                        Image(systemName: "sparkles")
                        Text("Generate Content")
                    }
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canGenerate)

            if !configuredLLMConnections.isEmpty && selectedLLMId == nil {
                Text("Please select an LLM model to continue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Generated Content Column

    private var generatedContentColumn: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Generated Content")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top)

            ScrollView {
                Text(generatedContent.isEmpty ? "Generated content will appear here..." : generatedContent)
                    .font(.body)
                    .foregroundStyle(generatedContent.isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .textSelection(.enabled)
            }
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
        }
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            Spacer()

            if !generatedContent.isEmpty {
                Button("Save to File") {
                    saveGeneratedContent()
                }
                .buttonStyle(.bordered)

                Button("Copy to Clipboard") {
                    copyGeneratedContentToClipboard()
                }
                .buttonStyle(.bordered)
            }

            Button("Done") {
                dismissWindow()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Content Generation

    private func generateContent() {
        guard canGenerate, let llmConnection = selectedLLMConnection else {
            return
        }

        switch llmConnection.endpointType {
        case .chatCompletions:
            Task {
                isGenerating = true
                generatedContent = ""
                errorMessage = nil

                do {
                    let client = try SwiftChatCompletionsDSL.LLMClient(
                        baseURL: llmConnection.fullApiUrl,
                        apiKey: llmConnection.apiKey
                    )

                    let systemPrompt = buildSystemPrompt()
                    let userMessage = buildUserMessage()

                    let validRequestTimeout = max(10, min(900, TimeInterval(llmConnection.requestTimeoutSeconds)))
                    let validResourceTimeout = max(30, min(3600, TimeInterval(llmConnection.requestTimeoutSeconds)))

                    let request = try ChatRequest(model: llmConnection.selectedModel, stream: true) {
                        try SwiftChatCompletionsDSL.Temperature(0.7)
                        try SwiftChatCompletionsDSL.RequestTimeout(validRequestTimeout)
                        try SwiftChatCompletionsDSL.ResourceTimeout(validResourceTimeout)
                    } messages: {
                        TextMessage(role: .system, content: systemPrompt)
                        TextMessage(role: .user, content: userMessage)
                    }

                    let stream = client.stream(request)
                    var fullContent = ""
                    var lastUpdateTime = Date.distantPast
                    let updateInterval: TimeInterval = 0.05

                    for try await delta in stream {
                        let contentPiece = delta.choices.first?.delta.content
                        let finishReason = delta.choices.first?.finishReason

                        if let content = contentPiece {
                            fullContent += content

                            let now = Date()
                            if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                                lastUpdateTime = now
                                await MainActor.run {
                                    generatedContent = fullContent
                                }
                            }
                        }

                        if finishReason != nil {
                            break
                        }
                    }

                    await MainActor.run {
                        generatedContent = fullContent
                    }

                    llmConnection.updateLastUsed()

                    await MainActor.run {
                        isGenerating = false
                        onContentGenerated(fullContent)
                        onLLMSelectionChanged?(selectedLLMId)
                    }

                } catch let error as SwiftChatCompletionsDSL.LLMError {
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = formatLLMError(error)
                        showingError = true
                    }
                } catch {
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = "Unexpected error: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }

        case .responses:
            Task {
                isGenerating = true
                generatedContent = ""
                errorMessage = nil

                do {
                    let client = try SwiftOpenResponsesDSL.LLMClient(
                        baseURL: llmConnection.fullApiUrl,
                        apiKey: llmConnection.apiKey
                    )

                    let userMessage = buildUserMessage()

                    let validRequestTimeout = max(10, min(900, TimeInterval(llmConnection.requestTimeoutSeconds)))
                    let validResourceTimeout = max(30, min(3600, TimeInterval(llmConnection.requestTimeoutSeconds)))

                    let configParams: [any ResponseConfigParameter] = [
                        try RequestTimeout(validRequestTimeout),
                        try ResourceTimeout(validResourceTimeout),
                        try Instructions(buildSystemPrompt()),
                    ]

                    let session = ToolSession(client: client, tools: [], maxIterations: 1, handlers: [:])
                    let toolStream = session.stream(
                        model: llmConnection.selectedModel,
                        input: [User(userMessage)],
                        configParams: configParams
                    )

                    var fullContent = ""
                    var lastUpdateTime = Date.distantPast
                    let updateInterval: TimeInterval = 0.05

                    for try await event in toolStream {
                        if case .llm(let se) = event,
                           case .contentPartDelta(let delta, _, _) = se {
                            fullContent += delta
                            let now = Date()
                            if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                                lastUpdateTime = now
                                await MainActor.run { generatedContent = fullContent }
                            }
                        }
                    }

                    await MainActor.run { generatedContent = fullContent }
                    llmConnection.updateLastUsed()
                    await MainActor.run {
                        isGenerating = false
                        onContentGenerated(fullContent)
                        onLLMSelectionChanged?(selectedLLMId)
                    }

                } catch let error as SwiftOpenResponsesDSL.LLMError {
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = formatLLMError(error)
                        showingError = true
                    }
                } catch {
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = "Unexpected error: \(error.localizedDescription)"
                        showingError = true
                    }
                }
            }
        }
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt() -> String {
        var prompt = "You are an AI assistant helping to generate comprehensive content for a project specification."

        if let systemPrompt = projectSystemPrompt, !systemPrompt.isEmpty {
            prompt += "\n\nProject Context:\n" + systemPrompt
        }

        return prompt
    }

    private func buildUserMessage() -> String {
        var message = "Generate comprehensive, well-structured content for the project '\(projectName)'."

        if !projectMarkdownContent.isEmpty {
            message += "\n\nProject Specification:\n\(projectMarkdownContent)"
        }

        message += "\n\nPlease generate content that addresses all aspects of the project specification."

        return message
    }

    // MARK: - Error Handling

    private func formatLLMError(_ error: SwiftChatCompletionsDSL.LLMError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL configuration. Please check the LLM connection settings."
        case .encodingFailed(let message):
            return "Request encoding failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingFailed(let message):
            return "Response decoding failed: \(message)"
        case .serverError(let statusCode, let message):
            return "Server error (status \(statusCode)): \(message ?? "Unknown server error")"
        case .rateLimit:
            return "Rate limit exceeded. Please wait before making another request."
        case .invalidResponse:
            return "Invalid response from server. Please check your LLM configuration."
        case .invalidValue(let message):
            return "Invalid parameter value: \(message)"
        case .missingBaseURL:
            return "Base URL is missing. Please check your LLM connection settings."
        case .missingModel:
            return "Model name is missing. Please check your LLM connection settings."
        case .maxIterationsExceeded(let iterations):
            return "Tool-calling loop exceeded maximum iterations (\(iterations)). Please try again."
        case .unknownTool(let name):
            return "Unknown tool requested: \(name). Please check your LLM configuration."
        case .toolExecutionFailed(let toolName, let message):
            return "Tool execution failed (\(toolName)): \(message)"
        }
    }

    private func formatLLMError(_ error: SwiftOpenResponsesDSL.LLMError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL configuration. Please check the LLM connection settings."
        case .encodingFailed(let message):
            return "Request encoding failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .decodingFailed(let message):
            return "Response decoding failed: \(message)"
        case .serverError(let statusCode, let message):
            return "Server error (status \(statusCode)): \(message ?? "Unknown server error")"
        case .rateLimit:
            return "Rate limit exceeded. Please wait before making another request."
        case .invalidResponse:
            return "Invalid response from server. Please check your LLM configuration."
        case .invalidValue(let message):
            return "Invalid parameter value: \(message)"
        case .missingBaseURL:
            return "Base URL is missing. Please check your LLM connection settings."
        case .missingModel:
            return "Model name is missing. Please check your LLM connection settings."
        case .maxIterationsExceeded(let iterations):
            return "Tool-calling loop exceeded maximum iterations (\(iterations)). Please try again."
        case .unknownTool(let name):
            return "Unknown tool requested: \(name). Please check your LLM configuration."
        case .toolExecutionFailed(let toolName, let message):
            return "Tool execution failed (\(toolName)): \(message)"
        }
    }

    // MARK: - Export Functions

    private func saveGeneratedContent() {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.plainText]
        savePanel.nameFieldStringValue = "\(projectName)_generated.md"
        savePanel.title = "Save Generated Content"
        savePanel.prompt = "Save"

        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try generatedContent.write(to: url, atomically: true, encoding: .utf8)
                    print("Successfully saved generated content to: \(url.path)")
                } catch {
                    errorMessage = "Failed to save generated content: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func copyGeneratedContentToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(generatedContent, forType: .string)
        print("Generated content copied to clipboard successfully")
    }

    // MARK: - Initialization

    private func initializeLLMSelection() {
        // Use project's preferred LLM if available
        if let projectLLMId = projectLLMConnectionId,
           configuredLLMConnections.contains(where: { $0.id == projectLLMId }) {
            selectedLLMId = projectLLMId
        } else if let firstConnection = configuredLLMConnections.first {
            selectedLLMId = firstConnection.id
        }
    }
}
