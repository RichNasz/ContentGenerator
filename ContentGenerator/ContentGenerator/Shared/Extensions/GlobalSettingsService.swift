//
//  GlobalSettingsService.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftData
import Observation
import LLMmanagement

// MARK: - Global Settings Service

@MainActor
@Observable
final class GlobalSettingsService {
    private let dataManager: ProjectDataManager

    init(dataManager: ProjectDataManager) {
        self.dataManager = dataManager
    }

    func getSettings() async throws -> ApplicationSettings {
        let context = dataManager.createContext()

        let descriptor = FetchDescriptor<ApplicationSettings>()

        do {
            let settings = try context.fetch(descriptor)
            return settings.first ?? ApplicationSettings.defaultSettings()
        } catch {
            return ApplicationSettings.defaultSettings()
        }
    }

    func updateSettings(_ settings: ApplicationSettings) async throws {
        let context = dataManager.createContext()

        settings.modifiedAt = Date()

        let existingDescriptor = FetchDescriptor<ApplicationSettings>()
        let existing = try context.fetch(existingDescriptor)

        if existing.isEmpty {
            context.insert(settings)
        }

        try context.save()
    }
}

// MARK: - Project Data Manager

@MainActor
@Observable
final class ProjectDataManager {
    private let container: ModelContainer

    init(bundleURL: URL) throws {
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: bundleURL.path) {
            try fileManager.createDirectory(at: bundleURL, withIntermediateDirectories: true)
        }

        // Ensure bundle subdirectories exist
        let swiftdataDir = bundleURL.appendingPathComponent("swiftdata")
        if !fileManager.fileExists(atPath: swiftdataDir.path) {
            try fileManager.createDirectory(at: swiftdataDir, withIntermediateDirectories: true)
        }
        let projectsDir = bundleURL.appendingPathComponent("projects")
        if !fileManager.fileExists(atPath: projectsDir.path) {
            try fileManager.createDirectory(at: projectsDir, withIntermediateDirectories: true)
        }

        let storeURL = swiftdataDir.appendingPathComponent("default.store")

        // Single container for all application data
        container = try ModelContainer(
            for: Schema([
                ContentProject.self,
                ContentSpecification.self,
                SpecificationSection.self,
                GeneratedContentData.self,
                FileAttachment.self,
                ApplicationSettings.self,
                LLMConnection.self
            ]),
            configurations: ModelConfiguration(
                url: storeURL,
                allowsSave: true
            )
        )
    }

    /// Get the unified application container
    func getContainer() -> ModelContainer {
        return container
    }

    /// Create a context for data operations
    func createContext() -> ModelContext {
        return ModelContext(container)
    }
}

// MARK: - Application Settings

@Model
final class ApplicationSettings {
    var id: UUID
    var aiServiceEndpoint: String
    var aiServiceAPIKey: String
    var appearanceTheme: AppearanceTheme
    var autoSaveEnabled: Bool
    var dataBackupLocation: String?
    var createdAt: Date
    var modifiedAt: Date

    init(
        aiServiceEndpoint: String = "",
        aiServiceAPIKey: String = "",
        appearanceTheme: AppearanceTheme = .system,
        autoSaveEnabled: Bool = true,
        dataBackupLocation: String? = nil
    ) {
        self.id = UUID()
        self.aiServiceEndpoint = aiServiceEndpoint
        self.aiServiceAPIKey = aiServiceAPIKey
        self.appearanceTheme = appearanceTheme
        self.autoSaveEnabled = autoSaveEnabled
        self.dataBackupLocation = dataBackupLocation
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    static func defaultSettings() -> ApplicationSettings {
        return ApplicationSettings()
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

enum AppearanceTheme: String, CaseIterable, Codable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}