//
//  ProjectExportService.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//
//  Service for importing and exporting projects to/from JSON format.
//

import Foundation
import SwiftData
import Observation
import ProjectExchange
import LLMmanagement

// MARK: - LLM Connection Conflict Types

/// Represents a conflict when importing a project with an LLM configuration
/// that matches an existing connection name.
struct LLMConnectionConflict: Sendable {
    let existingConnection: LLMConnectionInfo
    let importingConfig: ExportableLLMConfiguration

    struct LLMConnectionInfo: Sendable {
        let id: UUID
        let name: String
        let selectedModel: String
        let baseUrl: String
        let endpointType: String
        let urlPath: String?
        let requestTimeoutSeconds: Int
    }
}

/// User's choice for resolving an LLM connection conflict
enum LLMConflictResolution: Sendable {
    /// Use the existing connection, ignore imported config
    case useExisting(connectionId: UUID)
    /// Overwrite existing connection with imported values
    case overwriteExisting(connectionId: UUID)
    /// Create a new connection with imported values
    case createNew
    /// Skip LLM connection import entirely
    case skip
}

/// Result of importing a project
struct ProjectImportResult: Sendable {
    let project: ContentProject
    let llmConnectionId: UUID?
    let warnings: [String]
}

// MARK: - Project Export Service

@MainActor
@Observable
final class ProjectExportService {
    private let dataManager: ProjectDataManager
    private let fileAttachmentManager: FileAttachmentManager
    private let serializer = ProjectSerializer()

    init(dataManager: ProjectDataManager, fileAttachmentManager: FileAttachmentManager) {
        self.dataManager = dataManager
        self.fileAttachmentManager = fileAttachmentManager
    }

    // MARK: - Export

    /// Export a project to JSON Data
    func exportProject(_ project: ContentProject) async throws -> Data {
        let exportable = try await convertToExportable(project)
        return try serializer.export(exportable)
    }

    /// Export a project to a file URL
    func exportProject(_ project: ContentProject, to fileURL: URL) async throws {
        let exportable = try await convertToExportable(project)
        try serializer.export(exportable, to: fileURL)
    }

    /// Export a project to a JSON string (for preview/debugging)
    func exportProjectToString(_ project: ContentProject) async throws -> String {
        let exportable = try await convertToExportable(project)
        return try serializer.exportToString(exportable)
    }

    // MARK: - Import

    /// Import a project from JSON Data
    /// Returns the ExportableProject for conflict checking before final import
    func previewImport(from data: Data) throws -> ExportableProject {
        return try serializer.importProject(from: data)
    }

    /// Import a project from a file URL
    /// Returns the ExportableProject for conflict checking before final import
    func previewImport(from fileURL: URL) throws -> ExportableProject {
        return try serializer.importProject(from: fileURL)
    }

    /// Check if importing would cause LLM connection conflicts
    /// Returns conflicts for all LLM configurations that match existing connections by name
    func checkForLLMConflicts(_ exportable: ExportableProject) -> [LLMConnectionConflict] {
        guard !exportable.llmConfigurations.isEmpty else {
            return []
        }

        let context = dataManager.createContext()
        var conflicts: [LLMConnectionConflict] = []

        do {
            let descriptor = FetchDescriptor<LLMConnection>()
            let existingConnections = try context.fetch(descriptor)

            for importingConfig in exportable.llmConfigurations {
                let searchName = importingConfig.name.lowercased()

                // Case-insensitive name match
                if let existing = existingConnections.first(where: { $0.name.lowercased() == searchName }) {
                    conflicts.append(LLMConnectionConflict(
                        existingConnection: LLMConnectionConflict.LLMConnectionInfo(
                            id: existing.id,
                            name: existing.name,
                            selectedModel: existing.selectedModel,
                            baseUrl: existing.baseUrl,
                            endpointType: existing.endpointType.displayName,
                            urlPath: existing.urlPath,
                            requestTimeoutSeconds: existing.requestTimeoutSeconds
                        ),
                        importingConfig: importingConfig
                    ))
                }
            }
        } catch {
            // If fetch fails, return empty conflicts
            return []
        }

        return conflicts
    }

    /// Check if a project with the same name already exists
    /// - Parameter exportable: The project to check
    /// - Returns: True if a project with the same name (case-insensitive) already exists
    func checkForProjectNameConflict(_ exportable: ExportableProject) -> Bool {
        let context = dataManager.createContext()
        let importingName = exportable.name.lowercased()

        do {
            let descriptor = FetchDescriptor<ContentProject>()
            let existingProjects = try context.fetch(descriptor)
            return existingProjects.contains { $0.name.lowercased() == importingName }
        } catch {
            return false
        }
    }

    /// Complete the import of a project with the given conflict resolutions
    /// - Parameters:
    ///   - exportable: The project to import
    ///   - conflictResolutions: Dictionary mapping config IDs to their resolutions
    ///   - renameForConflict: If true, appends timestamp to project name to avoid duplicate names
    func completeImport(
        _ exportable: ExportableProject,
        conflictResolutions: [UUID: LLMConflictResolution] = [:],
        renameForConflict: Bool = false
    ) async throws -> ProjectImportResult {
        let context = dataManager.createContext()
        var warnings: [String] = []
        var finalLLMConnectionId: UUID?

        // Build a mapping from imported config IDs to resolved connection IDs
        var configIdToConnectionId: [UUID: UUID] = [:]

        // Process each LLM configuration
        for config in exportable.llmConfigurations {
            let resolution = conflictResolutions[config.id]

            switch resolution {
            case .useExisting(let connectionId):
                configIdToConnectionId[config.id] = connectionId

            case .overwriteExisting(let connectionId):
                // Update existing connection
                let descriptor = FetchDescriptor<LLMConnection>(
                    predicate: #Predicate { $0.id == connectionId }
                )
                if let existing = try context.fetch(descriptor).first {
                    existing.selectedModel = config.selectedModel
                    existing.baseUrl = config.baseUrl
                    existing.endpointType = mapEndpointType(config.endpointType)
                    existing.urlPath = config.urlPath
                    existing.requestTimeoutSeconds = config.requestTimeoutSeconds
                    // Note: API key preserved
                    configIdToConnectionId[config.id] = connectionId
                }

            case .createNew:
                // Create new connection with modified name
                let newConnection = LLMConnection(
                    name: "\(config.name) (Imported)",
                    endpointType: mapEndpointType(config.endpointType),
                    baseUrl: config.baseUrl,
                    urlPath: config.urlPath,
                    apiKey: "", // User must provide
                    selectedModel: config.selectedModel,
                    requestTimeoutSeconds: config.requestTimeoutSeconds
                )
                context.insert(newConnection)
                configIdToConnectionId[config.id] = newConnection.id
                warnings.append("New LLM connection '\(newConnection.name)' created. Please provide the API key.")

            case .skip, .none:
                // No conflict - try to find or create the connection
                let searchName = config.name.lowercased()
                let descriptor = FetchDescriptor<LLMConnection>()
                let existingConnections = try context.fetch(descriptor)

                if let existing = existingConnections.first(where: { $0.name.lowercased() == searchName }) {
                    // Use existing connection with same name
                    configIdToConnectionId[config.id] = existing.id
                } else {
                    // Create new connection
                    let newConnection = LLMConnection(
                        name: config.name,
                        endpointType: mapEndpointType(config.endpointType),
                        baseUrl: config.baseUrl,
                        urlPath: config.urlPath,
                        apiKey: "", // User must provide
                        selectedModel: config.selectedModel,
                        requestTimeoutSeconds: config.requestTimeoutSeconds
                    )
                    context.insert(newConnection)
                    configIdToConnectionId[config.id] = newConnection.id
                    warnings.append("New LLM connection '\(config.name)' created. Please provide the API key.")
                }
            }
        }

        // Resolve project's LLM connection
        if let projectLLMId = exportable.llmConnectionId,
           let resolvedId = configIdToConnectionId[projectLLMId] {
            finalLLMConnectionId = resolvedId
        }

        // Determine final project name (append timestamp if renaming for conflict)
        var finalName = exportable.name
        if renameForConflict {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timestamp = formatter.string(from: Date())
            finalName = "\(exportable.name) (\(timestamp))"
        }

        // Create the project
        let project = ContentProject(name: finalName)
        project.projectDescription = exportable.projectDescription
        project.status = ProjectStatus(rawValue: exportable.status.rawValue) ?? .draft
        project.systemPrompt = exportable.systemPrompt
        project.createdAt = exportable.createdAt
        project.modifiedAt = Date() // Update to import time
        project.llmConnectionId = finalLLMConnectionId

        // Import specification
        if let exportableSpec = exportable.specification {
            let specification = ContentSpecification()
            specification.project = project
            project.specification = specification

            for exportableSection in exportableSpec.sections.sorted(by: { $0.orderIndex < $1.orderIndex }) {
                let section = specification.addSection(
                    name: exportableSection.name,
                    content: exportableSection.content,
                    contentGenerationPrompt: exportableSection.contentGenerationPrompt,
                    contentUsagePrompt: exportableSection.contentUsagePrompt,
                    isEnabled: exportableSection.isEnabled
                )
                section.sectionDescription = exportableSection.sectionDescription
                // Note: Section llmConnectionId not yet supported in app model
            }
        }

        // Note: Generated content is not imported (users regenerate after import)

        // Import file attachments — write embedded content to bundle when available
        var inaccessibleCount = 0
        for attachmentMeta in exportable.attachmentMetadata {
            let attachment = FileAttachment(
                originalFileName: attachmentMeta.originalFileName,
                fileSizeBytes: attachmentMeta.fileSizeBytes
            )
            attachment.fileExtension = attachmentMeta.fileExtension
            attachment.project = project

            if let base64 = attachmentMeta.fileContentBase64,
               let fileData = Data(base64Encoded: base64) {
                // Write the embedded file into the new bundle
                do {
                    let attachmentsDir = try dataManager.attachmentsDirectory(for: project.id)
                    let destURL = attachmentsDir.appendingPathComponent(attachmentMeta.originalFileName)
                    try fileData.write(to: destURL)
                    attachment.relativeBundlePath = "projects/\(project.id.uuidString)/attachments/\(attachmentMeta.originalFileName)"
                    attachment.isAccessible = true
                } catch {
                    attachment.isAccessible = false
                    inaccessibleCount += 1
                    warnings.append("Could not restore '\(attachmentMeta.originalFileName)': \(error.localizedDescription)")
                }
            } else {
                // No embedded content (legacy export) — user must locate manually
                attachment.isAccessible = false
                inaccessibleCount += 1
            }

            project.attachments.append(attachment)
        }

        if inaccessibleCount > 0 {
            warnings.append("\(inaccessibleCount) file attachment(s) could not be restored automatically. Use 'Locate' to re-link them.")
        }

        if finalLLMConnectionId == nil && !exportable.llmConfigurations.isEmpty {
            warnings.append("Project LLM connection was not set. Please select an LLM connection for this project.")
        }

        // Insert and save
        context.insert(project)
        try context.save()

        return ProjectImportResult(
            project: project,
            llmConnectionId: finalLLMConnectionId,
            warnings: warnings
        )
    }

    // MARK: - Private Conversion Methods

    private func convertToExportable(_ project: ContentProject) async throws -> ExportableProject {
        // Collect all unique LLM connection IDs (project + sections)
        var llmConnectionIds: Set<UUID> = []
        if let projectLLMId = project.llmConnectionId {
            llmConnectionIds.insert(projectLLMId)
        }
        // Note: Section llmConnectionIds not yet supported in app model
        // When added, collect them here: spec.sections.forEach { if let id = $0.llmConnectionId { llmConnectionIds.insert(id) } }

        // Fetch and convert all unique LLM configurations
        let llmConfigurations = llmConnectionIds.compactMap { fetchLLMConfiguration(for: $0) }

        // Convert specification
        let exportableSpec: ExportableSpecification? = project.specification.map { spec in
            let sections = spec.sections.sorted { $0.orderIndex < $1.orderIndex }.map { section in
                ExportableSection(
                    name: section.name,
                    sectionDescription: section.sectionDescription,
                    content: section.content,
                    orderIndex: section.orderIndex,
                    contentGenerationPrompt: section.contentGenerationPrompt,
                    contentUsagePrompt: section.contentUsagePrompt,
                    isEnabled: section.isEnabled,
                    llmConnectionId: nil, // Not yet supported in app model
                    createdAt: section.createdAt,
                    modifiedAt: section.modifiedAt
                )
            }
            return ExportableSpecification(
                createdAt: spec.createdAt,
                modifiedAt: spec.modifiedAt,
                sections: sections
            )
        }

        // Note: Generated content is not exported (users regenerate after import)

        // Convert attachments, embedding file contents when available
        var exportableAttachments: [ExportableFileAttachment] = []
        for attachment in project.attachments {
            let fileContentBase64 = await readFileContentBase64(for: attachment)
            let resolvedPath: String? = attachment.relativeBundlePath.map {
                dataManager.bundleURL.appendingPathComponent($0).path
            }
            exportableAttachments.append(
                ExportableFileAttachment(
                    originalFileName: attachment.originalFileName,
                    originalFilePath: resolvedPath,
                    fileExtension: attachment.fileExtension,
                    fileSizeBytes: attachment.fileSizeBytes,
                    createdAt: attachment.createdAt,
                    modifiedAt: attachment.modifiedAt,
                    fileContentBase64: fileContentBase64
                )
            )
        }

        return ExportableProject(
            name: project.name,
            projectDescription: project.projectDescription,
            status: ExportableProjectStatus(rawValue: project.status.rawValue) ?? .draft,
            systemPrompt: project.systemPrompt,
            createdAt: project.createdAt,
            modifiedAt: project.modifiedAt,
            specification: exportableSpec,
            attachmentMetadata: exportableAttachments,
            llmConnectionId: project.llmConnectionId,
            llmConfigurations: llmConfigurations
        )
    }

    /// Reads raw file bytes and returns them as a base64 string for embedding in the export JSON.
    /// Returns `nil` if the file is not accessible.
    private func readFileContentBase64(for attachment: FileAttachment) async -> String? {
        // Bundle-based: read directly from the bundle path
        if let relativePath = attachment.relativeBundlePath {
            let fileURL = dataManager.bundleURL.appendingPathComponent(relativePath)
            do {
                let data = try Data(contentsOf: fileURL)
                return data.base64EncodedString()
            } catch {
                return nil
            }
        }

        // Legacy bookmark-based: resolve via security-scoped bookmark
        do {
            if let url = try await fileAttachmentManager.accessFile(attachment: attachment) {
                defer { url.stopAccessingSecurityScopedResource() }
                let data = try Data(contentsOf: url)
                return data.base64EncodedString()
            }
        } catch {
            // File not accessible
        }
        return nil
    }

    private func fetchLLMConfiguration(for connectionId: UUID?) -> ExportableLLMConfiguration? {
        guard let connectionId = connectionId else { return nil }

        let context = dataManager.createContext()

        do {
            let descriptor = FetchDescriptor<LLMConnection>(
                predicate: #Predicate { $0.id == connectionId }
            )
            guard let connection = try context.fetch(descriptor).first else { return nil }

            return ExportableLLMConfiguration(
                id: connection.id,
                name: connection.name,
                selectedModel: connection.selectedModel,
                baseUrl: connection.baseUrl,
                endpointType: mapEndpointType(connection.endpointType),
                urlPath: connection.urlPath,
                requestTimeoutSeconds: connection.requestTimeoutSeconds
            )
        } catch {
            return nil
        }
    }

    private func mapEndpointType(_ type: OpenAIEndpointType) -> ExportableEndpointType {
        switch type {
        case .chatCompletions:
            return .chatCompletions
        case .responses:
            return .responses
        }
    }

    private func mapEndpointType(_ type: ExportableEndpointType) -> OpenAIEndpointType {
        switch type {
        case .chatCompletions:
            return .chatCompletions
        case .responses:
            return .responses
        }
    }
}
