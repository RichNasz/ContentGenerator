//
//  ContentView.swift
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
import ProjectExchange
import UniformTypeIdentifiers

// MARK: - Navigation Destination

enum NavigationDestination: Hashable {
    case project(ContentProject)
    case llmConnections
    case applicationSettings
}

// MARK: - Content View

struct ContentView: View {
    @Environment(ProjectDataManager.self) private var dataManager
    @Environment(GlobalSettingsService.self) private var settingsService
    @Environment(ProjectExportService.self) private var exportService
    @Environment(BundleManager.self) private var bundleManager

    // Add SwiftData query for projects
    @Query(sort: \ContentProject.modifiedAt, order: .reverse)
    private var projects: [ContentProject]

    @State private var selectedDestination: NavigationDestination?
    @State private var environmentReady = false
    @State private var projectsToDelete: IndexSet?
    @State private var projectNamesToDelete: [String] = []
    @State private var showingDeleteConfirmation = false

    // Import state
    @State private var isImporting = false
    @State private var pendingImport: ExportableProject?
    @State private var llmConflicts: [LLMConnectionConflict] = []
    @State private var llmConflictResolutions: [UUID: LLMConflictResolution] = [:]
    @State private var currentConflictIndex = 0
    @State private var showingLLMConflictSheet = false
    @State private var importWarnings: [String] = []
    @State private var showingImportResult = false
    @State private var hasProjectNameConflict = false
    @State private var showingProjectNameConflictDialog = false

    var body: some View {
        NavigationSplitView {
            // Sidebar with projects and settings
            List(selection: $selectedDestination) {
                Section {
                    ForEach(projects) { project in
                        NavigationLink(value: NavigationDestination.project(project)) {
                            HStack {
                                Text(project.name)
                                Spacer()
                            }
                        }
                        .contextMenu {
                            Button("Delete Project", systemImage: "trash", role: .destructive) {
                                deleteProjectFromContextMenu(project)
                            }
                        }
                    }
                    .onDelete(perform: deleteProjects)
                } header: {
                    HStack {
                        Text("Projects")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundStyle(.secondary)

                        Spacer()

                        Button(action: { importProject() }) {
                            Image(systemName: "square.and.arrow.down")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(!environmentReady || isImporting)
                        .help("Import Project")

                        Button(action: { createNewProject() }) {
                            Image(systemName: "plus")
                                .font(.footnote)
                                .fontWeight(.medium)
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(!environmentReady)
                        .help("New Project")
                    }
                }

                Section("Settings") {
                    NavigationLink("LLM Connections", value: NavigationDestination.llmConnections)
                    NavigationLink("Application Settings", value: NavigationDestination.applicationSettings)
                }
            }
#if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 350)
#endif
            .navigationTitle(bundleName)
        } detail: {
            // Detail view switches based on selection
            if let destination = selectedDestination {
                switch destination {
                case .project(let project):
                    ProjectDetailView(project: project)
                        .id(project.id)
                case .llmConnections:
                    LLMConnectionListView(
                        modelContext: dataManager.createContext(),
                        embedInNavigationStack: false
                    )
                case .applicationSettings:
                    Text("Application Settings")
                }
            } else {
                ContentUnavailableView(
                    "No Project Selected",
                    systemImage: "folder.badge.plus",
                    description: Text("Select a project from the sidebar or create a new one to get started")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
#if os(macOS)
        .background(WindowTitle(title: bundleName))
#endif
        .confirmationDialog(
            projectNamesToDelete.count == 1 ?
                "Delete \"\(projectNamesToDelete.first ?? "")\"?" :
                "Delete \(projectNamesToDelete.count) projects?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                confirmDeleteProjects()
            }
            Button("Cancel", role: .cancel) {
                projectsToDelete = nil
                projectNamesToDelete = []
            }
        } message: {
            Text(projectNamesToDelete.count == 1 ?
                "This action cannot be undone. The project and all its content will be permanently deleted." :
                "This action cannot be undone. These projects and all their content will be permanently deleted.")
        }
        .task {
            await initializeEnvironment()
        }
        .sheet(isPresented: $showingLLMConflictSheet) {
            if currentConflictIndex < llmConflicts.count {
                LLMConnectionConflictSheet(conflict: llmConflicts[currentConflictIndex]) { resolution in
                    resolveCurrentConflict(with: resolution)
                }
            }
        }
        .alert("Project Imported", isPresented: $showingImportResult) {
            Button("OK") {
                importWarnings = []
            }
        } message: {
            if importWarnings.isEmpty {
                Text("Project imported successfully.")
            } else {
                Text(importWarnings.joined(separator: "\n"))
            }
        }
        .confirmationDialog(
            "Project Already Exists",
            isPresented: $showingProjectNameConflictDialog,
            titleVisibility: .visible
        ) {
            Button("Import with New Name") {
                continueImportAfterNameConflict()
            }
            Button("Cancel", role: .cancel) {
                pendingImport = nil
                hasProjectNameConflict = false
            }
        } message: {
            if let name = pendingImport?.name {
                Text("A project named \"\(name)\" already exists. The imported project will be renamed with a timestamp.")
            }
        }
    }

    private var bundleName: String {
        guard let url = bundleManager.bundleURL else { return "" }
        return url.deletingPathExtension().lastPathComponent
    }

    // Generate intelligent project name avoiding conflicts
    private func generateProjectName() -> String {
        let baseName = "Project"
        let existingNames = projects.map { $0.name }
        var counter = 1

        while existingNames.contains("\(baseName) \(counter)") {
            counter += 1
        }

        return "\(baseName) \(counter)"
    }

    // Direct project creation without modal
    private func createNewProject() {
        guard environmentReady else { return }

        Task {
            let context = dataManager.createContext()

            do {
                // Create project with intelligent name
                let project = ContentProject(name: generateProjectName())

                // Create empty specification (sections will be added by user)
                let specification = ContentSpecification()
                specification.project = project
                project.specification = specification

                // Insert specification and project
                context.insert(specification)
                context.insert(project)

                try context.save()

                // Auto-select on main thread
                await MainActor.run {
                    selectedDestination = .project(project)
                }

            } catch {
                await MainActor.run {
                    print("Failed to create project: \(error)")
                }
            }
        }
    }

    // Handle swipe-to-delete for projects
    private func deleteProjects(offsets: IndexSet) {
        projectsToDelete = offsets
        projectNamesToDelete = offsets.map { projects[$0].name }
        showingDeleteConfirmation = true
    }

    // Handle context menu delete for individual project
    private func deleteProjectFromContextMenu(_ project: ContentProject) {
        guard let index = projects.firstIndex(where: { $0.id == project.id }) else { return }
        projectsToDelete = IndexSet([index])
        projectNamesToDelete = [project.name]
        showingDeleteConfirmation = true
    }

    private func confirmDeleteProjects() {
        guard let offsets = projectsToDelete else { return }

        Task {
            let context = dataManager.createContext()

            do {
                // Get projects to delete
                let projectsToRemove = offsets.map { projects[$0] }
                let projectIdsToRemove = projectsToRemove.map { $0.id }

                // If the selected project is being deleted, clear selection
                if case .project(let selectedProject) = selectedDestination,
                   projectsToRemove.contains(where: { $0.id == selectedProject.id }) {
                    await MainActor.run {
                        self.selectedDestination = nil
                    }
                }

                // Delete each project
                let allProjects = try context.fetch(FetchDescriptor<ContentProject>())
                for project in projectsToRemove {
                    if let projectToDelete = allProjects.first(where: { $0.id == project.id }) {
                        context.delete(projectToDelete)
                    }
                }

                try context.save()

                // Delete each project's bundle directory (non-fatal)
                let bundleURL = dataManager.bundleURL
                for projectId in projectIdsToRemove {
                    let projectDir = bundleURL
                        .appendingPathComponent("projects")
                        .appendingPathComponent(projectId.uuidString)
                    try? FileManager.default.removeItem(at: projectDir)
                }

                await MainActor.run {
                    projectsToDelete = nil
                    projectNamesToDelete = []
                }

            } catch {
                await MainActor.run {
                    print("Failed to delete projects: \(error)")
                    projectsToDelete = nil
                    projectNamesToDelete = []
                }
            }
        }
    }

    // MARK: - Import Methods

    /// Initiates the project import flow
    private func importProject() {
        isImporting = true

        Task {
            defer { isImporting = false }

            // Show file picker
            let openPanel = NSOpenPanel()
            openPanel.allowedContentTypes = [.json]
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseFiles = true
            openPanel.canChooseDirectories = false
            openPanel.title = "Import Project"
            openPanel.prompt = "Import"

            let response = await openPanel.beginSheetModal(for: NSApp.keyWindow!)

            guard response == .OK, let url = openPanel.url else {
                return
            }

            do {
                // Preview the import to check for conflicts
                let exportable = try exportService.previewImport(from: url)
                pendingImport = exportable

                // Check for project name conflict FIRST
                hasProjectNameConflict = exportService.checkForProjectNameConflict(exportable)

                if hasProjectNameConflict {
                    // Show name conflict dialog - user must confirm before proceeding
                    showingProjectNameConflictDialog = true
                } else {
                    // Check for LLM connection conflicts
                    let conflicts = exportService.checkForLLMConflicts(exportable)
                    if !conflicts.isEmpty {
                        llmConflicts = conflicts
                        llmConflictResolutions = [:]
                        currentConflictIndex = 0
                        showingLLMConflictSheet = true
                    } else {
                        // No conflicts, proceed with import
                        completeImport()
                    }
                }
            } catch {
                print("Failed to import project: \(error.localizedDescription)")
            }
        }
    }

    /// Continues import after user confirms name conflict (rename with timestamp)
    private func continueImportAfterNameConflict() {
        guard let exportable = pendingImport else { return }

        // Now check for LLM conflicts before proceeding
        let conflicts = exportService.checkForLLMConflicts(exportable)
        if !conflicts.isEmpty {
            llmConflicts = conflicts
            llmConflictResolutions = [:]
            currentConflictIndex = 0
            showingLLMConflictSheet = true
        } else {
            // No LLM conflict, proceed with import (with rename)
            completeImport()
        }
    }

    /// Stores the resolution for the current conflict and advances to the next, or completes the import
    private func resolveCurrentConflict(with resolution: LLMConflictResolution) {
        let conflict = llmConflicts[currentConflictIndex]
        llmConflictResolutions[conflict.importingConfig.id] = resolution

        if currentConflictIndex + 1 < llmConflicts.count {
            currentConflictIndex += 1
            showingLLMConflictSheet = true
        } else {
            completeImport()
        }
    }

    /// Completes the import with all collected conflict resolutions
    private func completeImport() {
        guard let exportable = pendingImport else { return }

        Task {
            do {
                let result = try await exportService.completeImport(
                    exportable,
                    conflictResolutions: llmConflictResolutions,
                    renameForConflict: hasProjectNameConflict
                )

                // Store warnings for display
                importWarnings = result.warnings

                // Select the imported project
                await MainActor.run {
                    selectedDestination = .project(result.project)
                    showingImportResult = true
                }
            } catch {
                print("Failed to complete import: \(error.localizedDescription)")
            }

            // Clear pending state
            pendingImport = nil
            llmConflicts = []
            llmConflictResolutions = [:]
            currentConflictIndex = 0
            hasProjectNameConflict = false
        }
    }

    // Initialize environment objects following async best practices
    private func initializeEnvironment() async {
        // Allow environment objects to initialize
        try? await Task.sleep(for: .milliseconds(100))

        await MainActor.run {
            environmentReady = true
        }
    }
}


#if os(macOS)
private struct WindowTitle: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setFrameSize(.zero)
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.update(title: title, view: nsView)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject {
        private var pendingTitle = ""
        private var observation: NSKeyValueObservation?

        func update(title: String, view: NSView) {
            pendingTitle = title
            if let window = view.window {
                window.title = title
                observation = nil
            } else {
                observation = view.observe(\.window, options: [.new]) { [weak self] observedView, _ in
                    guard let self else { return }
                    let title = self.pendingTitle
                    Task { @MainActor in
                        observedView.window?.title = title
                        self.observation = nil
                    }
                }
            }
        }
    }
}
#endif

#Preview {
    do {
        let previewURL = FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs")
        let dataManager = try ProjectDataManager(bundleURL: previewURL)
        let settingsService = GlobalSettingsService(dataManager: dataManager)
        let fileAttachmentManager = FileAttachmentManager(dataManager: dataManager)
        let exportService = ProjectExportService(
            dataManager: dataManager,
            fileAttachmentManager: fileAttachmentManager
        )

        let bundleManager = BundleManager()

        return ContentView()
            .environment(dataManager)
            .environment(settingsService)
            .environment(exportService)
            .environment(bundleManager)
    } catch {
        return Text("Preview Error: \(error.localizedDescription)")
    }
}

