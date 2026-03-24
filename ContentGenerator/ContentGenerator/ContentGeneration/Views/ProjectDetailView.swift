//
//  ProjectDetailView.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData
import Foundation
import LLMmanagement
import UniformTypeIdentifiers
import ProjectExchange
import AgentGen

/// Comprehensive project editing interface for the NavigationSplitView detail section
struct ProjectDetailView: View {
    @Bindable var project: ContentProject
    @Environment(ProjectDataManager.self) private var dataManager
    @Environment(GlobalSettingsService.self) private var settingsService
    @Environment(ProjectExportService.self) private var exportService
    @Environment(ContentGenerationWindowState.self) private var windowState
    @Environment(ProjectContentGenerationWindowState.self) private var projectWindowState
    @Environment(AgentGen.AgentGenerationWindowState.self) private var agentWindowState
    @Environment(\.openWindow) private var openWindow

    // Query for available LLM connections
    @Query(sort: \LLMConnection.name) private var llmConnections: [LLMConnection]

    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var specificationSections: [SpecificationSectionData] = []

    // Export state
    @State private var isExporting = false
    @State private var showingExportSuccess = false
    @State private var successMessage = ""

    // Auto-save state
    @State private var saveState: SaveState = .saved
    @State private var saveTask: Task<Void, Never>?
    @State private var expandedSections: Set<UUID> = []

    // Add section state
    @State private var isAddingSection = false
    @State private var newSectionName = ""
    @State private var newSectionContent = ""

    // Content generation settings state
    @State private var isSystemPromptExpanded = false

    // Drag and drop state
    @State private var draggingSectionId: UUID?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Project Properties Section
                projectPropertiesSection

                // Reference Content Section
                FileAttachmentSection(project: project)

                // Specification Overview Section
                specificationOverviewSection

                // Content Generation Settings Section
                contentGenerationSettingsSection

                // Action Buttons Section
                actionButtonsSection
            }
            .padding()
        }
        .navigationTitle(project.name)
#if os(iOS)
        .navigationBarTitleDisplayMode(.large)
#endif
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
        .alert("Success", isPresented: $showingExportSuccess) {
            Button("OK") { }
        } message: {
            Text(successMessage)
        }
        .task {
            await loadSpecificationData()
            await validateAndCleanupLLMSelection()
        }
    }

    // MARK: - Project Properties Section

    private var projectPropertiesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Project Details", systemImage: "doc.text.viewfinder")
                    .font(.headline)

                Spacer()

                // Save state indicator replaces "Edit" button
                SaveStateIndicator(state: saveState)
            }

            // Inline editor for project properties
            InlineProjectPropertyEditor(
                project: project,
                onChanged: scheduleSave
            )
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Specification Overview Section

    private var specificationOverviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Content Specification", systemImage: "list.clipboard")
                    .font(.headline)

                Spacer()

                // LLM Assistant button with section selector
                Menu {
                    ForEach(Array(specificationSections.enumerated()), id: \.element.id) { index, section in
                        Button(action: {
                            openLLMAssistantForSection(at: index)
                        }) {
                            Text(section.name)
                        }
                    }
                } label: {
                    Label("LLM Assistant", systemImage: "sparkles")
                } primaryAction: {
                    // If there's only one section, open it directly
                    if specificationSections.count == 1 {
                        openLLMAssistantForSection(at: 0)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(specificationSections.isEmpty)
                .help("Get AI assistance to generate content for a section")

                // Add section button replaces "Edit" button
                Button(action: startAddingSection) {
                    Label("Add Section", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }

            if specificationSections.isEmpty && !isAddingSection {
                ContentUnavailableView(
                    "No Specification Sections",
                    systemImage: "doc.text.below.ecg",
                    description: Text("Click 'Add Section' to define the content you want to generate")
                )
                .frame(minHeight: 100)
            } else {
                VStack(spacing: 12) {
                    // Existing sections with drag-and-drop support
                    ForEach(Array(specificationSections.enumerated()), id: \.element.id) { index, section in
                        ExpandableSpecificationSection(
                            section: bindingForSection(at: index),
                            isExpanded: bindingForExpanded(section.id),
                            projectLLMConnectionId: project.llmConnectionId,
                            onChanged: scheduleSave,
                            onDelete: { deleteSection(at: index) },
                            onMoveUp: index > 0 ? { moveSection(from: index, to: index - 1) } : nil,
                            onMoveDown: index < specificationSections.count - 1 ? { moveSection(from: index, to: index + 1) } : nil
                        )
                        .opacity(draggingSectionId == section.id ? 0.5 : 1.0)
                        .onDrag {
                            draggingSectionId = section.id
                            return NSItemProvider(object: section.id.uuidString as NSString)
                        }
                        .onDrop(of: [.text], isTargeted: nil) { providers in
                            guard let dragId = draggingSectionId,
                                  let sourceIndex = specificationSections.firstIndex(where: { $0.id == dragId }) else {
                                draggingSectionId = nil
                                return false
                            }
                            let destinationIndex = index
                            draggingSectionId = nil

                            guard sourceIndex != destinationIndex else { return true }

                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                moveSection(from: sourceIndex, to: destinationIndex)
                            }
                            return true
                        }
                    }

                    // New section being added
                    if isAddingSection {
                        newSectionEditor
                    }
                }
                .onDrop(of: [.text], isTargeted: nil) { _ in
                    // Clear drag state when dropped on container but not on a section
                    draggingSectionId = nil
                    return false
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - New Section Editor

    private var newSectionEditor: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("New Section")
                    .font(.subheadline)
                    .fontWeight(.medium)

                Spacer()

                // Save and cancel buttons
                HStack(spacing: 8) {
                    Button(action: cancelAddSection) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Cancel")

                    Button(action: saveNewSection) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    }
                    .buttonStyle(.plain)
                    .disabled(newSectionName.isEmpty || newSectionContent.isEmpty)
                    .help("Save section")
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Section Name")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                SpellCheckingTextField(placeholder: "e.g., Target Audience, Tone, Key Messages", text: $newSectionName)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Content")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                SpellCheckingTextEditor(text: $newSectionContent)
                    .frame(minHeight: 100, maxHeight: 200)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Content Generation Settings Section

    private var contentGenerationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Label("Content Generation Settings", systemImage: "gearshape")
                    .font(.headline)

                Spacer()

                // Toggle expansion button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if project.systemPrompt?.isEmpty != false {
                            // If no prompt, expand automatically when user wants to add one
                            isSystemPromptExpanded = true
                        } else {
                            // If prompt exists, toggle expansion
                            isSystemPromptExpanded.toggle()
                        }
                    }
                }) {
                    Image(systemName: isSystemPromptExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }

            // Show prompt editor when expanded or when there's content
            if isSystemPromptExpanded || project.systemPrompt?.isEmpty == false {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("System/Developer Role Prompt")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        if project.systemPrompt?.isEmpty == false {
                            Button("Clear") {
                                project.systemPrompt = nil
                                scheduleSave()
                            }
                            .font(.caption)
                            .foregroundStyle(.red)
                            .buttonStyle(.plain)
                        }
                    }

                    SpellCheckingTextEditor(text: Binding(
                        get: { project.systemPrompt ?? "" },
                        set: { newValue in
                            project.systemPrompt = newValue.isEmpty ? nil : newValue
                            scheduleSave()
                        }
                    ))
                    .frame(minHeight: 60, maxHeight: 200)
                    .padding(8)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        // Placeholder text overlay
                        Group {
                            if project.systemPrompt?.isEmpty != false {
                                VStack {
                                    HStack {
                                        Text("You are a professional content writer. Write in a clear, engaging style that speaks directly to your target audience...")
                                            .foregroundStyle(.secondary)
                                            .font(.body)
                                            .padding(.leading, 12)
                                            .padding(.top, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                        .allowsHitTesting(false)
                    )
                }
            } else {
                // Collapsed state - show add prompt button
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSystemPromptExpanded = true
                    }
                }) {
                    HStack {
                        Image(systemName: "plus.circle")
                        Text("Add System Prompt")
                    }
                    .foregroundStyle(.blue)
                }
                .buttonStyle(.plain)
                .padding(.vertical, 8)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Action Buttons Section

    private var actionButtonsSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Button("Generate Content") {
                    generateContentWithXMLFormat()
                }
                .buttonStyle(.borderedProminent)
                .disabled(specificationSections.isEmpty)

                Button("Generate with Agent") {
                    generateContentWithAgent()
                }
                .buttonStyle(.bordered)
                .disabled(specificationSections.isEmpty)

                Menu {
                    Button("Export Markdown File", systemImage: "doc.text") {
                        exportProjectMarkdown()
                    }
                    Button("Copy to Clipboard", systemImage: "doc.on.clipboard") {
                        copyProjectToClipboard()
                    }

                    Divider()

                    Button("Export Project (JSON)", systemImage: "square.and.arrow.up.on.square") {
                        exportProjectJSON()
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                .disabled(specificationSections.isEmpty)


                Spacer()
            }

        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Computed Properties

    /// Returns only configured LLM connections that are ready to use
    private var configuredLLMConnections: [LLMConnection] {
        llmConnections.filter { $0.isConfigured }
    }


    // MARK: - Helper Methods

    private func loadSpecificationData() async {
        guard let specification = project.specification else {
            specificationSections = []
            return
        }

        let sections = specification.sections.sorted { $0.orderIndex < $1.orderIndex }
        specificationSections = sections.map { section in
            SpecificationSectionData(
                name: section.name,
                content: section.content,
                orderIndex: Int(section.orderIndex),
                isEnabled: section.isEnabled,
                contentGenerationPrompt: section.contentGenerationPrompt,
                contentUsagePrompt: section.contentUsagePrompt
            )
        }
    }

    /// Validates that the stored LLM connection ID is still valid and clears it if not
    ///
    /// This function ensures data integrity by checking that:
    /// 1. The stored LLM connection still exists in the database
    /// 2. The connection is properly configured (has required fields)
    ///
    /// If the stored LLM is invalid (deleted or misconfigured), it's automatically
    /// cleared to prevent the user from attempting to use an unavailable connection.
    private func validateAndCleanupLLMSelection() async {
        // If no LLM is selected, nothing to validate
        guard let storedId = project.llmConnectionId else {
            return
        }

        // Check if the stored LLM connection is still valid
        let isValid = configuredLLMConnections.contains { $0.id == storedId }

        // If invalid, clear the selection to force user to choose a new one
        if !isValid {
            project.llmConnectionId = nil
            // The auto-save will be triggered by the onChange modifier
        }
    }

    /// Opens the project content generation window
    private func generateContentWithXMLFormat() {
        // Generate project markdown content for display in the window
        // Use buildForUserMessage() to avoid system prompt duplication since window handles system prompt separately
        let builder = ProjectMarkdownBuilder(project: project)
        let projectMarkdown = builder.buildForUserMessage()

        // Open the project content generation window
        projectWindowState.openProjectWindow(
            projectName: project.name,
            projectSystemPrompt: project.systemPrompt,
            projectLLMConnectionId: project.llmConnectionId,
            projectMarkdownContent: projectMarkdown,
            onContentGenerated: { content in
                // Handle generated content (could be extended for additional functionality)
                print("Project content generated: \(content.prefix(100))...")
            },
            onLLMSelectionChanged: { llmId in
                // Persist the selected LLM connection back to the project
                project.llmConnectionId = llmId
                scheduleSave()
            }
        )

        openWindow(id: "project-content-generation")
    }



    /// Opens the project agent generation window
    private func generateContentWithAgent() {
        let agentSections = specificationSections.map { section in
            AgentGen.AgentSection(
                name: section.name,
                content: section.content,
                contentGenerationPrompt: section.contentGenerationPrompt,
                contentUsagePrompt: section.contentUsagePrompt,
                isEnabled: section.isEnabled
            )
        }

        agentWindowState.openAgentWindow(
            projectName: project.name,
            systemPrompt: project.systemPrompt,
            llmConnectionId: project.llmConnectionId,
            sections: agentSections,
            onContentGenerated: { content in
                print("Agent content generated: \(content.prefix(100))…")
            },
            onLLMSelectionChanged: { llmId in
                project.llmConnectionId = llmId
                scheduleSave()
            }
        )

        openWindow(id: "project-agent-generation")
    }

    /// Exports the project as a markdown file
    private func exportProjectMarkdown() {
        // Generate shareable content using shared helper
        let markdown = generateShareContent()

        // Create and configure the save panel
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [UTType.plainText]
        savePanel.nameFieldStringValue = "\(project.name).md"
        savePanel.title = "Export Project as Markdown"
        savePanel.prompt = "Export"

        // Show the save panel
        savePanel.begin { response in
            if response == .OK, let url = savePanel.url {
                do {
                    try markdown.write(to: url, atomically: true, encoding: .utf8)
                    self.showSuccess("Project exported successfully to \(url.lastPathComponent)")
                } catch {
                    self.showError("Failed to export markdown: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Generates shareable content (markdown with system prompt + XML sections)
    /// - Returns: Formatted markdown content ready for sharing
    private func generateShareContent() -> String {
        let builder = ProjectMarkdownBuilder(project: project)
        return builder.buildForExport(systemPrompt: project.systemPrompt)
    }

    /// Copies the project content to clipboard in markdown format
    private func copyProjectToClipboard() {
        // Generate shareable content using shared helper
        let content = generateShareContent()

        // Copy to clipboard
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)

        showSuccess("Project content copied to clipboard")
    }

    /// Exports the project as a JSON file for import into other applications
    private func exportProjectJSON() {
        isExporting = true

        Task {
            defer { isExporting = false }

            // Create and configure the save panel
            let savePanel = NSSavePanel()
            savePanel.allowedContentTypes = [.json]
            savePanel.nameFieldStringValue = "\(project.name).json"
            savePanel.title = "Export Project"
            savePanel.prompt = "Export"

            // Show the save panel
            let response = await savePanel.beginSheetModal(for: NSApp.keyWindow!)

            if response == .OK, let url = savePanel.url {
                do {
                    try await exportService.exportProject(project, to: url)
                    print("Successfully exported project to: \(url.path)")
                } catch {
                    showError("Failed to export project: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Shows an error message to the user
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }

    /// Shows a success message to the user
    private func showSuccess(_ message: String) {
        successMessage = message
        showingExportSuccess = true
    }

    // MARK: - Section Operations

    /// Creates a binding for a section at the given index
    private func bindingForSection(at index: Int) -> Binding<SpecificationSectionData> {
        Binding(
            get: { self.specificationSections[index] },
            set: { self.specificationSections[index] = $0 }
        )
    }

    /// Creates a binding for the expanded state of a section
    private func bindingForExpanded(_ sectionId: UUID) -> Binding<Bool> {
        Binding(
            get: { self.expandedSections.contains(sectionId) },
            set: { isExpanded in
                if isExpanded {
                    self.expandedSections.insert(sectionId)
                } else {
                    self.expandedSections.remove(sectionId)
                }
            }
        )
    }

    /// Starts the process of adding a new section
    private func startAddingSection() {
        isAddingSection = true
        newSectionName = ""
        newSectionContent = ""
    }

    /// Opens the LLM Assistant window for a specific section
    private func openLLMAssistantForSection(at index: Int) {
        guard index >= 0 && index < specificationSections.count else { return }

        let section = specificationSections[index]

        windowState.openWindow(
            sectionName: section.name,
            sectionContent: section.content,
            contentGenerationPrompt: section.contentGenerationPrompt,
            projectLLMConnectionId: project.llmConnectionId,
            projectAttachments: project.sortedAttachments,
            onContentGenerated: { [self] content, mode, updatedPrompt in
                handleContentGenerated(at: index, content: content, mode: mode, updatedPrompt: updatedPrompt)
            }
        )
        openWindow(id: "content-generation")
    }

    /// Handles content generated from the LLM Assistant
    private func handleContentGenerated(at index: Int, content: String, mode: ContentInsertMode, updatedPrompt: String?) {
        guard index >= 0 && index < specificationSections.count else { return }

        // Update content based on mode
        switch mode {
        case .replace:
            specificationSections[index].content = content
        case .append:
            if specificationSections[index].content.isEmpty {
                specificationSections[index].content = content
            } else {
                specificationSections[index].content += "\n\n" + content
            }
        }

        // Save the updated user prompt
        specificationSections[index].contentGenerationPrompt = updatedPrompt

        scheduleSave()
    }

    /// Cancels adding a new section
    private func cancelAddSection() {
        isAddingSection = false
        newSectionName = ""
        newSectionContent = ""
    }

    /// Saves the new section being added
    private func saveNewSection() {
        guard !newSectionName.isEmpty && !newSectionContent.isEmpty else { return }

        let newSection = SpecificationSectionData(
            name: newSectionName,
            content: newSectionContent,
            orderIndex: specificationSections.count
        )

        specificationSections.append(newSection)
        cancelAddSection()
        scheduleSave()
    }

    /// Deletes a section at the given index
    private func deleteSection(at index: Int) {
        specificationSections.remove(at: index)

        // Reorder remaining sections
        for i in index..<specificationSections.count {
            specificationSections[i].orderIndex = i
        }

        scheduleSave()
    }

    /// Moves a section from one index to another
    private func moveSection(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex != destinationIndex else { return }
        guard sourceIndex >= 0 && sourceIndex < specificationSections.count else { return }
        guard destinationIndex >= 0 && destinationIndex < specificationSections.count else { return }

        let section = specificationSections.remove(at: sourceIndex)
        specificationSections.insert(section, at: destinationIndex)

        // Update order indices
        for (index, _) in specificationSections.enumerated() {
            specificationSections[index].orderIndex = index
        }

        scheduleSave()
    }

    // MARK: - Auto-Save Methods

    /// Schedules a save operation with debouncing to prevent excessive saves
    private func scheduleSave() {
        // Cancel any pending save
        saveTask?.cancel()

        // Schedule save after 0.5 second delay
        saveTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await performSave()
        }
    }

    /// Performs the actual save operation with validation
    private func performSave() async {
        saveState = .saving

        // Validate project data
        guard validateProject() else {
            saveState = .error("Invalid data")
            return
        }

        // Update modification timestamp
        project.modifiedAt = Date()

        // Save to SwiftData
        do {
            let context = dataManager.createContext()

            // Sync specification sections to SwiftData
            await syncSpecificationToSwiftData(context: context)

            try context.save()
            saveState = .saved

            // Clear "saved" indicator after 2 seconds
            Task {
                try? await Task.sleep(for: .seconds(2))
                if saveState == .saved {
                    saveState = .saved // Could transition to hidden state here
                }
            }
        } catch {
            saveState = .error(error.localizedDescription)
        }
    }

    /// Syncs specification sections from UI state to SwiftData
    private func syncSpecificationToSwiftData(context: ModelContext) async {
        // Get or create specification
        var specification: ContentSpecification
        if let existingSpec = project.specification {
            specification = existingSpec

            // Remove existing sections
            for section in specification.sections {
                context.delete(section)
            }
            specification.sections.removeAll()
        } else {
            specification = ContentSpecification()
            specification.project = project
            project.specification = specification
            context.insert(specification)
        }

        // Add current sections from UI state
        for sectionData in specificationSections {
            _ = specification.addSection(
                name: sectionData.name,
                content: sectionData.content,
                contentGenerationPrompt: sectionData.contentGenerationPrompt,
                contentUsagePrompt: sectionData.contentUsagePrompt,
                isEnabled: sectionData.isEnabled
            )
        }

        specification.modifiedAt = Date()
    }

    /// Validates project data before saving
    private func validateProject() -> Bool {
        let trimmedName = project.name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty
    }

}

// MARK: - Supporting Views

struct ProjectPropertyRow: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body)
            }

            Spacer()
        }
    }
}

struct SpecificationSectionSummary: View {
    let section: SpecificationSectionData

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "text.alignleft")
                .foregroundStyle(.secondary)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(section.name)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(section.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}



#Preview {
    Group {
        if let dataManager = try? ProjectDataManager(bundleURL: FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs")) {
            let settingsService = GlobalSettingsService(dataManager: dataManager)
            let fileAttachmentManager = FileAttachmentManager(dataManager: dataManager)
            let exportService = ProjectExportService(
                dataManager: dataManager,
                fileAttachmentManager: fileAttachmentManager
            )
            let project = ContentProject(name: "Sample Project")

            ProjectDetailView(project: project)
                .environment(dataManager)
                .environment(settingsService)
                .environment(exportService)
        } else {
            Text("Preview Error: Could not initialize data manager")
        }
    }
}
