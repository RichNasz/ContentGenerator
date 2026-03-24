//
//  ContentGeneratorApp.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData
import AgentGen

@main
struct ContentGeneratorApp: App {
    @State private var bundleManager = BundleManager()
    @State private var dataManager: ProjectDataManager?
    @State private var settingsService: GlobalSettingsService?
    @State private var fileAttachmentManager: FileAttachmentManager?
    @State private var projectExportService: ProjectExportService?
    @State private var contentGenerationWindowState = ContentGenerationWindowState()
    @State private var projectContentGenerationWindowState = ProjectContentGenerationWindowState()
    @State private var agentWindowState = AgentGen.AgentGenerationWindowState()

    var body: some Scene {
        WindowGroup {
            Group {
                if let dataManager, let settingsService, let fileAttachmentManager,
                   let projectExportService {
                    ContentView()
                        .environment(dataManager)
                        .environment(settingsService)
                        .environment(fileAttachmentManager)
                        .environment(projectExportService)
                        .environment(contentGenerationWindowState)
                        .environment(projectContentGenerationWindowState)
                        .environment(agentWindowState)
                        .modelContainer(dataManager.getContainer())
                } else {
                    BundleWelcomeView()
                }
            }
            .frame(minWidth: 700, minHeight: 500)
            .environment(bundleManager)
            .task {
                _ = bundleManager.restoreSavedBundle()
            }
            .onChange(of: bundleManager.bundleURL) { _, newURL in
                if let url = newURL {
                    initializeServices(with: url)
                }
            }
        }
        #if os(macOS)
        .windowResizability(.contentMinSize)
        .defaultSize(width: 1200, height: 800)
        .commands {
            TextEditingCommands()
            CommandGroup(after: .newItem) {
                Divider()
                Button("New Specification Bundle...") {
                    Task {
                        _ = await bundleManager.createNewBundle()
                    }
                }
                .keyboardShortcut("n", modifiers: [.command, .shift])
                Button("Open Specification Bundle...") {
                    Task {
                        _ = await bundleManager.openExistingBundle()
                    }
                }
                .keyboardShortcut("o", modifiers: [.command, .shift])
            }
        }
        #endif

        // Content Generation Window
        WindowGroup(id: "content-generation") {
            if let dataManager, let fileAttachmentManager {
                SectionContentGenerationWindow(
                    sectionName: contentGenerationWindowState.sectionName,
                    sectionContent: contentGenerationWindowState.sectionContent,
                    contentGenerationPrompt: contentGenerationWindowState.contentGenerationPrompt,
                    projectLLMConnectionId: contentGenerationWindowState.projectLLMConnectionId,
                    projectAttachments: contentGenerationWindowState.projectAttachments,
                    onContentGenerated: { content, mode, updatedPrompt in
                        contentGenerationWindowState.onContentGenerated?(content, mode, updatedPrompt)
                    }
                )
                .environment(dataManager)
                .environment(fileAttachmentManager)
                .modelContainer(dataManager.getContainer())
                .onDisappear {
                    contentGenerationWindowState.reset()
                }
            }
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 900, height: 600)
        #endif

        // Project Agent Generation Window
        WindowGroup(id: "project-agent-generation") {
            if let dataManager {
                AgentGen.ProjectAgentGenerationWindow(
                    projectName: agentWindowState.projectName,
                    projectSystemPrompt: agentWindowState.projectSystemPrompt,
                    projectLLMConnectionId: agentWindowState.projectLLMConnectionId,
                    sections: agentWindowState.sections,
                    modelContext: dataManager.createContext(),
                    onContentGenerated: { content in
                        agentWindowState.onContentGenerated?(content)
                    },
                    onLLMSelectionChanged: { llmId in
                        agentWindowState.onLLMSelectionChanged?(llmId)
                    }
                )
                .environment(dataManager)
                .modelContainer(dataManager.getContainer())
                .onDisappear {
                    agentWindowState.reset()
                }
            }
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 700)
        #endif

        // Project Content Generation Window
        WindowGroup(id: "project-content-generation") {
            if let dataManager {
                ProjectContentGenerationWindow(
                    projectName: projectContentGenerationWindowState.projectName,
                    projectSystemPrompt: projectContentGenerationWindowState.projectSystemPrompt,
                    projectLLMConnectionId: projectContentGenerationWindowState.projectLLMConnectionId,
                    projectMarkdownContent: projectContentGenerationWindowState.projectMarkdownContent,
                    onContentGenerated: { content in
                        projectContentGenerationWindowState.onContentGenerated?(content)
                    },
                    onLLMSelectionChanged: { llmId in
                        projectContentGenerationWindowState.onLLMSelectionChanged?(llmId)
                    }
                )
                .environment(dataManager)
                .modelContainer(dataManager.getContainer())
                .onDisappear {
                    projectContentGenerationWindowState.reset()
                }
            }
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .defaultSize(width: 1200, height: 700)
        #endif
    }

    private func initializeServices(with bundleURL: URL) {
        do {
            let dm = try ProjectDataManager(bundleURL: bundleURL)
            let ss = GlobalSettingsService(dataManager: dm)
            let fam = FileAttachmentManager(dataManager: dm)
            let pes = ProjectExportService(dataManager: dm, fileAttachmentManager: fam)

            dataManager = dm
            settingsService = ss
            fileAttachmentManager = fam
            projectExportService = pes
        } catch {
            bundleManager.bundleState = .error("Failed to initialize data services: \(error.localizedDescription)")
        }
    }
}
