//
//  SectionContentGenerationWindow.swift
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
import AppKit
import UniformTypeIdentifiers

/// Window for LLM-assisted content generation for specification sections
struct SectionContentGenerationWindow: View {
    let sectionName: String
    let sectionContent: String
    let contentGenerationPrompt: String?
    let projectLLMConnectionId: UUID?
    let projectAttachments: [FileAttachment]
    let onContentGenerated: (String, ContentInsertMode, String?) -> Void
    @Environment(\.dismissWindow) private var dismissWindow
    @Environment(FileAttachmentManager.self) private var fileAttachmentManager

    // Query for available LLM connections
    @Query(sort: \LLMConnection.name) private var llmConnections: [LLMConnection]

    @State private var generatedContent: String = ""
    @State private var userPrompt: String = ""
    @State private var originalPrompt: String = ""
    @State private var isGenerating: Bool = false
    @State private var selectedLLMId: UUID?
    @State private var showingLLMWarning: Bool = false
    @State private var errorMessage: String?
    @State private var showingError: Bool = false
    @State private var feedbackEntries: [GenerationFeedbackEntry] = []

    // Reference file selection state
    @State private var selectedAttachmentIds: Set<UUID> = []
    @State private var fileAccessErrors: [UUID: String] = [:]

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Main content area
            HSplitView {
                // Column 1: Current Content (readonly)
                currentContentColumn
                    .frame(minWidth: 250, idealWidth: 300, maxWidth: 400)

                // Column 2: LLM Controls
                llmControlsColumn
                    .frame(minWidth: 300, idealWidth: 350)

                // Column 3: Generated Content
                generatedContentColumn
                    .frame(minWidth: 300, idealWidth: 400)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            // Footer with action buttons
            footerSection
        }
        .frame(minWidth: 900, idealWidth: 1200, idealHeight: 600)
        .onAppear {
            // Initialize user prompt from the section's content generation prompt
            userPrompt = contentGenerationPrompt ?? ""
            originalPrompt = contentGenerationPrompt ?? ""

            // Reset file selection state (don't persist selections across sessions)
            selectedAttachmentIds = []
            fileAccessErrors = [:]
        }
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

    private var chatCompletionsConnections: [LLMConnection] {
        configuredLLMConnections.filter { $0.endpointType == .chatCompletions }
    }

    private var responsesConnections: [LLMConnection] {
        configuredLLMConnections.filter { $0.endpointType == .responses }
    }

    private func isLocalConnection(_ connection: LLMConnection) -> Bool {
        guard let components = URLComponents(string: connection.baseUrl),
              let host = components.host?.lowercased() else { return false }
        return host == "localhost" || host == "127.0.0.1"
            || host == "0.0.0.0" || host == "::1" || host == "[::1]"
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
        return !userPrompt.isEmpty && isSelectedLLMValid && !isGenerating
    }

    /// Checks if the user prompt has unsaved changes
    private var hasUnsavedPromptChanges: Bool {
        return userPrompt != originalPrompt
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("LLM Content Assistant", systemImage: "sparkles")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Generate content for: \(sectionName)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - LLM Controls Column

    private var llmControlsColumn: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("LLM Controls")
                    .font(.headline)

                // User prompt input
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Instructions")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextEditor(text: $userPrompt)
                    .font(.body)
                    .frame(minHeight: 120)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )

                // Show Undo/Save buttons when prompt has unsaved changes
                if hasUnsavedPromptChanges {
                    HStack(spacing: 8) {
                        Button(action: revertToOriginalPrompt) {
                            Label("Undo", systemImage: "arrow.uturn.backward")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        .help("Discard changes and revert to original prompt")

                        Button(action: savePromptChanges) {
                            Label("Save", systemImage: "checkmark")
                                .font(.caption)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .help("Save these instructions to the section template")
                    }
                    .padding(.top, 4)
                }
            }

            // Reference File Selection
            ReferenceFileSelectionSection(
                attachments: projectAttachments,
                selectedAttachmentIds: $selectedAttachmentIds,
                fileAttachmentManager: fileAttachmentManager,
                fileAccessErrors: $fileAccessErrors
            )

            // LLM Selection
            VStack(alignment: .leading, spacing: 4) {
                Text("LLM Model")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("LLM", selection: $selectedLLMId) {
                    Text("Select LLM").tag(nil as UUID?)

                    if !chatCompletionsConnections.isEmpty {
                        Section("Chat Completions") {
                            ForEach(chatCompletionsConnections, id: \.id) { connection in
                                Label(connection.name, systemImage: isLocalConnection(connection) ? "house.fill" : "cloud")
                                    .tag(connection.id as UUID?)
                            }
                        }
                    }

                    if !responsesConnections.isEmpty {
                        Section("Responses") {
                            ForEach(responsesConnections, id: \.id) { connection in
                                Label(connection.name, systemImage: isLocalConnection(connection) ? "house.fill" : "cloud")
                                    .tag(connection.id as UUID?)
                            }
                        }
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity)
                .onChange(of: selectedLLMId) { oldValue, newValue in
                    validateLLMSelection()
                }

                // LLM status/warning message
                if selectedLLMId != nil {
                    if isSelectedLLMValid {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                            if let connection = selectedLLMConnection {
                                Text("Using: \(connection.name)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                            Text("Selected LLM is no longer available. Please choose another.")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                            .font(.caption)
                        Text("No LLM selected. Please select one to generate content.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Generate and export buttons
            HStack(spacing: 8) {
                // Generate button
                Button(action: generateContent) {
                    HStack {
                        if isGenerating {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 16, height: 16)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isGenerating ? "Generating..." : "Generate Content")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canGenerate)
                .controlSize(.large)

                // Export menu
                Menu {
                    Button("Copy to Clipboard", systemImage: "doc.on.clipboard") {
                        copyPromptToClipboard()
                    }
                    Button("Save to File", systemImage: "doc.text") {
                        savePromptToFile()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .help("Export complete LLM prompt")
            }

            // Activity feedback log
            if !feedbackEntries.isEmpty {
                GenerationFeedbackView(entries: feedbackEntries)
                    .frame(maxHeight: 300)
            }
            }
            .padding()
        }
        .frame(maxHeight: .infinity)
    }

    // MARK: - Generated Content Column

    private var generatedContentColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Generated Content")
                .font(.headline)

            if generatedContent.isEmpty {
                ContentUnavailableView(
                    "No Content Generated Yet",
                    systemImage: "doc.text",
                    description: Text("Enter your instructions and click 'Generate Content' to get started")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    Text(generatedContent)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    // MARK: - Current Content Column

    private var currentContentColumn: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Content")
                .font(.headline)

            if sectionContent.isEmpty {
                ContentUnavailableView(
                    "No Content Yet",
                    systemImage: "doc.text",
                    description: Text("This section doesn't have any content")
                )
            } else {
                ScrollView {
                    Text(sectionContent)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(8)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        HStack {
            Spacer()

            if !generatedContent.isEmpty {
                Button("Append to Content") {
                    onContentGenerated(generatedContent, .append, userPrompt.isEmpty ? nil : userPrompt)
                    dismissWindow(id: "content-generation")
                }
                .buttonStyle(.bordered)
                .help("Add generated content to the end of existing content")

                Button("Replace Content") {
                    onContentGenerated(generatedContent, .replace, userPrompt.isEmpty ? nil : userPrompt)
                    dismissWindow(id: "content-generation")
                }
                .buttonStyle(.borderedProminent)
                .help("Replace existing content with generated content")
            }
        }
        .padding()
        .background(.regularMaterial)
    }

    // MARK: - Actions

    private func generateContent() {
        guard canGenerate, let llmConnection = selectedLLMConnection else {
            return
        }

        feedbackEntries = []

        switch llmConnection.endpointType {
        case .chatCompletions:
            Task {
                isGenerating = true
                generatedContent = ""
                errorMessage = nil
                feedbackEntries.append(GenerationFeedbackEntry(kind: .status("Generating…")))

                do {
                    let client = try SwiftChatCompletionsDSL.LLMClient(
                        baseURL: llmConnection.fullApiUrl,
                        apiKey: llmConnection.apiKey
                    )

                    let userMessage = await buildUserMessage()

                    let validRequestTimeout = max(10, min(900, TimeInterval(llmConnection.requestTimeoutSeconds)))
                    let validResourceTimeout = max(30, min(3600, TimeInterval(llmConnection.requestTimeoutSeconds)))

                    let request = try ChatRequest(model: llmConnection.selectedModel, stream: true) {
                        try SwiftChatCompletionsDSL.Temperature(0.7)
                        try SwiftChatCompletionsDSL.RequestTimeout(validRequestTimeout)
                        try SwiftChatCompletionsDSL.ResourceTimeout(validResourceTimeout)
                    } messages: {
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

                    // Extract <think> blocks from accumulated content
                    let parsed = extractThinkingBlocks(from: fullContent)
                    for block in parsed.blocks {
                        feedbackEntries.append(GenerationFeedbackEntry(kind: .thinkingBlock(block)))
                    }
                    let finalContent = parsed.content

                    await MainActor.run {
                        generatedContent = finalContent
                    }

                    if finalContent.isEmpty && !parsed.blocks.isEmpty {
                        await MainActor.run {
                            isGenerating = false
                            errorMessage = "The model produced only reasoning content with no final output."
                            showingError = true
                        }
                        feedbackEntries.append(GenerationFeedbackEntry(kind: .failed("Only reasoning content returned — no final text.")))
                        return
                    }

                    if finalContent.isEmpty {
                        await MainActor.run {
                            isGenerating = false
                            errorMessage = "No content was generated. The connection may have timed out or the server did not respond. Please check:\n\n• Network connectivity\n• LLM service is running and accessible\n• API key is valid (if required)\n• Model name is correct\n• Timeout values are sufficient (currently: \(llmConnection.requestTimeoutSeconds)s)\n\nTry increasing the timeout values if the request times out."
                            showingError = true
                        }
                        return
                    }

                    feedbackEntries.append(GenerationFeedbackEntry(kind: .completed))
                    llmConnection.updateLastUsed()

                    await MainActor.run {
                        isGenerating = false
                    }

                } catch let error as SwiftChatCompletionsDSL.LLMError {
                    let message = formatLLMError(error)
                    feedbackEntries.append(GenerationFeedbackEntry(kind: .failed(message)))
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = message
                        showingError = true
                    }
                } catch {
                    let message = "Unexpected error: \(error.localizedDescription)"
                    feedbackEntries.append(GenerationFeedbackEntry(kind: .failed(message)))
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = message
                        showingError = true
                    }
                }
            }

        case .responses:
            Task {
                isGenerating = true
                generatedContent = ""
                errorMessage = nil
                feedbackEntries.append(GenerationFeedbackEntry(kind: .status("Generating…")))

                do {
                    let client = try SwiftOpenResponsesDSL.LLMClient(
                        baseURL: llmConnection.fullApiUrl,
                        apiKey: llmConnection.apiKey
                    )

                    let userMessage = await buildUserMessage()

                    let validRequestTimeout = max(10, min(900, TimeInterval(llmConnection.requestTimeoutSeconds)))
                    let validResourceTimeout = max(30, min(3600, TimeInterval(llmConnection.requestTimeoutSeconds)))

                    let configParams: [any ResponseConfigParameter] = [
                        try RequestTimeout(validRequestTimeout),
                        try ResourceTimeout(validResourceTimeout),
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
                        switch event {
                        case .llm(let se):
                            switch se {
                            case .contentPartDelta(let delta, _, _):
                                fullContent += delta
                                let now = Date()
                                if now.timeIntervalSince(lastUpdateTime) >= updateInterval {
                                    lastUpdateTime = now
                                    await MainActor.run { generatedContent = fullContent }
                                }
                            case .reasoningSummaryPartDone(let part, _, _):
                                let summary = part.text.trimmingCharacters(in: .whitespacesAndNewlines)
                                if !summary.isEmpty {
                                    feedbackEntries.append(GenerationFeedbackEntry(kind: .thinkingSummary(summary)))
                                }
                            case .outputItemDone(let item, _):
                                if case .reasoning(let r) = item {
                                    if let content = r.contentText, !content.isEmpty {
                                        feedbackEntries.append(GenerationFeedbackEntry(kind: .thinkingBlock(content)))
                                    }
                                    for s in (r.summary ?? []) {
                                        feedbackEntries.append(GenerationFeedbackEntry(kind: .thinkingSummary(s.text)))
                                    }
                                }
                            default:
                                break
                            }
                        case .usageUpdate(let usage, _):
                            feedbackEntries.append(GenerationFeedbackEntry(kind: .tokenUsage(formatResponseUsage(usage))))
                        default:
                            break
                        }
                    }

                    await MainActor.run { generatedContent = fullContent }
                    feedbackEntries.append(GenerationFeedbackEntry(kind: .completed))
                    llmConnection.updateLastUsed()
                    await MainActor.run { isGenerating = false }

                } catch let error as SwiftOpenResponsesDSL.LLMError {
                    let message = formatLLMError(error)
                    feedbackEntries.append(GenerationFeedbackEntry(kind: .failed(message)))
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = message
                        showingError = true
                    }
                } catch {
                    let message = "Unexpected error: \(error.localizedDescription)"
                    feedbackEntries.append(GenerationFeedbackEntry(kind: .failed(message)))
                    await MainActor.run {
                        isGenerating = false
                        errorMessage = message
                        showingError = true
                    }
                }
            }
        }
    }

    private func formatResponseUsage(_ usage: ResponseObject.Usage) -> String {
        var parts = ["Input: \(usage.inputTokens)"]
        if let cached = usage.inputTokensDetails?.cachedTokens, cached > 0 {
            parts[0] += " (\(cached) cached)"
        }
        if let reasoning = usage.outputTokensDetails?.reasoningTokens, reasoning > 0 {
            parts.append("Reasoning: \(reasoning)")
        }
        parts.append("Output: \(usage.outputTokens)")
        parts.append("Total: \(usage.inputTokens + usage.outputTokens)")
        return parts.joined(separator: " | ")
    }

    /// Reverts the user prompt to the original content generation prompt
    private func revertToOriginalPrompt() {
        userPrompt = originalPrompt
    }

    /// Saves the current prompt changes to the section template
    private func savePromptChanges() {
        // Save the prompt to the section template by calling the callback with empty content
        // and the updated prompt. This persists the prompt without changing section content.
        onContentGenerated("", .append, userPrompt.isEmpty ? nil : userPrompt)
        // Update the original prompt to match the saved version
        originalPrompt = userPrompt
    }

    // MARK: - Prompt Building

    /// Builds the system prompt for content generation
    private func buildSystemPrompt() -> String {
        var prompt = "You are an AI assistant helping to generate content for a specification section."

        // Add section-specific generation instructions if available
        if let generationPrompt = contentGenerationPrompt, !generationPrompt.isEmpty {
            prompt += "\n\n" + generationPrompt
        }

        return prompt
    }

    /// Builds the user message with user instructions and reference files only
    private func buildUserMessage() async -> String {
        var message = userPrompt // User instructions only

        // Add selected reference files directly after user prompt
        if !selectedAttachmentIds.isEmpty {
            for attachment in projectAttachments where selectedAttachmentIds.contains(attachment.id) {
                do {
                    let content = try await fileAttachmentManager.readFileContent(attachment: attachment)
                    message += "<ReferenceFile>\n\(content)\n</ReferenceFile>"
                } catch {
                    // Track error for UI display but continue with other files
                    await MainActor.run {
                        fileAccessErrors[attachment.id] = error.localizedDescription
                    }
                }
            }
        }

        return message // No trimming to preserve exact user format
    }

    /// Builds the complete LLM prompt for export - same format as sent to LLM
    private func buildCompletePrompt() async -> String {
        // Use the same simplified format for consistency across all operations
        return await buildUserMessage()
    }

    /// Formats LLMError into user-friendly error messages
    private func formatLLMError(_ error: SwiftChatCompletionsDSL.LLMError) -> String {
        switch error {
        case .invalidURL:
            return "Invalid URL configuration. Please check the LLM connection settings."
        case .encodingFailed(let message):
            return "Request encoding failed: \(message)"
        case .decodingFailed(let message):
            return "Response decoding failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let statusCode, let message):
            if let msg = message {
                return "Server error (\(statusCode)): \(msg)"
            } else {
                return "Server error: HTTP \(statusCode)"
            }
        case .rateLimit:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Received invalid response from the server."
        case .missingBaseURL:
            return "Missing base URL configuration."
        case .missingModel:
            return "Missing model selection."
        case .invalidValue(let message):
            return "Invalid parameter: \(message)"
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
        case .decodingFailed(let message):
            return "Response decoding failed: \(message)"
        case .networkError(let message):
            return "Network error: \(message)"
        case .serverError(let statusCode, let message):
            if let msg = message {
                return "Server error (\(statusCode)): \(msg)"
            } else {
                return "Server error: HTTP \(statusCode)"
            }
        case .rateLimit:
            return "Rate limit exceeded. Please try again later."
        case .invalidResponse:
            return "Received invalid response from the server."
        case .missingBaseURL:
            return "Missing base URL configuration."
        case .missingModel:
            return "Missing model selection."
        case .invalidValue(let message):
            return "Invalid parameter: \(message)"
        case .maxIterationsExceeded(let iterations):
            return "Tool-calling loop exceeded maximum iterations (\(iterations)). Please try again."
        case .unknownTool(let name):
            return "Unknown tool requested: \(name). Please check your LLM configuration."
        case .toolExecutionFailed(let toolName, let message):
            return "Tool execution failed (\(toolName)): \(message)"
        }
    }

    // MARK: - LLM Management

    /// Initializes the LLM selection, defaulting to the project's LLM if valid
    private func initializeLLMSelection() {
        // Try to use project's LLM connection first
        if let projectLLMId = projectLLMConnectionId {
            if configuredLLMConnections.contains(where: { $0.id == projectLLMId }) {
                selectedLLMId = projectLLMId
                return
            }
        }

        // If project LLM is not available, select the first available LLM
        if let firstLLM = configuredLLMConnections.first {
            selectedLLMId = firstLLM.id
        }
    }

    /// Validates the current LLM selection and shows warnings if needed
    private func validateLLMSelection() {
        guard let selectedId = selectedLLMId else {
            showingLLMWarning = false
            return
        }

        // Check if selected LLM is still valid
        let isValid = configuredLLMConnections.contains { $0.id == selectedId }

        if !isValid {
            showingLLMWarning = true
            // Clear invalid selection
            selectedLLMId = nil
        } else {
            showingLLMWarning = false
        }
    }

    // MARK: - Export Functionality

    /// Copies the complete LLM prompt to clipboard
    private func copyPromptToClipboard() {
        Task {
            let completePrompt = await buildCompletePrompt()

            await MainActor.run {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(completePrompt, forType: .string)
                print("LLM prompt copied to clipboard successfully")
            }
        }
    }

    /// Saves the complete LLM prompt to a file
    private func savePromptToFile() {
        Task {
            let completePrompt = await buildCompletePrompt()

            await MainActor.run {
                let savePanel = NSSavePanel()
                savePanel.allowedContentTypes = [UTType.plainText]
                savePanel.nameFieldStringValue = "\(sectionName) - LLM Prompt.md"
                savePanel.title = "Export LLM Prompt"
                savePanel.prompt = "Export"

                savePanel.begin { response in
                    if response == .OK, let url = savePanel.url {
                        do {
                            try completePrompt.write(to: url, atomically: true, encoding: .utf8)
                            print("Successfully exported LLM prompt to: \(url.path)")
                        } catch {
                            // Update error state for UI display
                            self.errorMessage = "Failed to export prompt: \(error.localizedDescription)"
                            self.showingError = true
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Types

/// Determines how generated content should be inserted
enum ContentInsertMode {
    case replace
    case append
}

// MARK: - Preview

#Preview {
    SectionContentGenerationWindow(
        sectionName: "Target Audience",
        sectionContent: "Young professionals aged 25-35",
        contentGenerationPrompt: "Focus on demographic details and psychographic characteristics",
        projectLLMConnectionId: nil,
        projectAttachments: [],
        onContentGenerated: { content, mode, updatedPrompt in
            print("Generated: \(content), Mode: \(mode), Updated Prompt: \(updatedPrompt ?? "nil")")
        }
    )
    .modelContainer(for: [LLMConnection.self])
}
