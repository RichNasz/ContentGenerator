//
//  ExportableProject.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// The root transfer object for project import/export.
///
/// This is the main type for serializing ContentGenerator projects to JSON.
/// It is designed to be independent of SwiftData for cross-application reusability.
///
/// ## Schema Versioning
/// The `schemaVersion` field allows detection of older or newer export formats
/// and enables migration logic for compatibility.
///
/// ## LLM Connections
/// - `llmConnectionId` references the project's LLM for content generation
/// - `llmConfigurations` contains all unique LLM connections used (project + sections)
/// - Section-level `llmConnectionId` references LLM for assistant functionality
///
/// ## Security
/// - API keys are never included (see `ExportableLLMConfiguration`)
/// - Security-scoped bookmarks are not exported (not portable)
/// - File contents are not embedded (metadata only)
/// - Generated content is not exported (users regenerate after import)
///
/// ## JSON Format
/// Output uses prettyPrinted formatting for human readability.
/// Note: Key order is not guaranteed as Swift's JSONEncoder does not
/// preserve insertion order for keyed containers.
public struct ExportableProject: Codable, Sendable {

    // MARK: - Properties

    public let schemaVersion: String
    public let name: String
    public let projectDescription: String?
    public let status: ExportableProjectStatus
    public let systemPrompt: String?
    public let specification: ExportableSpecification?
    public let attachmentMetadata: [ExportableFileAttachment]
    public let llmConnectionId: UUID?
    public let llmConfigurations: [ExportableLLMConfiguration]
    public let createdAt: Date
    public let modifiedAt: Date

    /// Current schema version constant
    public static let currentSchemaVersion = "1.0.0"

    // MARK: - Initialization

    public init(
        name: String,
        projectDescription: String?,
        status: ExportableProjectStatus,
        systemPrompt: String?,
        createdAt: Date,
        modifiedAt: Date,
        specification: ExportableSpecification?,
        attachmentMetadata: [ExportableFileAttachment],
        llmConnectionId: UUID?,
        llmConfigurations: [ExportableLLMConfiguration],
        schemaVersion: String = ExportableProject.currentSchemaVersion
    ) {
        self.schemaVersion = schemaVersion
        self.name = name
        self.projectDescription = projectDescription
        self.status = status
        self.systemPrompt = systemPrompt
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.specification = specification
        self.attachmentMetadata = attachmentMetadata
        self.llmConnectionId = llmConnectionId
        self.llmConfigurations = llmConfigurations
    }

}
