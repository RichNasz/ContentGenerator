//
//  ExportableSection.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// A specification section for import/export operations.
/// Contains all section data including content generation prompts.
///
/// ## LLM Connection
/// The `llmConnectionId` references the LLM connection used for assistant
/// functionality within this section. The actual connection configuration
/// is stored in the parent project's `llmConfigurations` array.
public struct ExportableSection: Codable, Sendable {

    // MARK: - CodingKeys for Human-Readable JSON Ordering

    private enum CodingKeys: String, CodingKey {
        case name               // 1. Main content
        case content
        case orderIndex         // 2. Display settings
        case isEnabled
        case sectionDescription // 3. Optional details
        case contentGenerationPrompt  // 4. Prompts
        case contentUsagePrompt
        case llmConnectionId    // 5. LLM reference
        case createdAt          // 6. Technical metadata
        case modifiedAt
    }

    // MARK: - Properties

    public let name: String
    public let sectionDescription: String?
    public let content: String
    public let orderIndex: Int
    public let contentGenerationPrompt: String?
    public let contentUsagePrompt: String?
    public let isEnabled: Bool
    public let createdAt: Date
    public let modifiedAt: Date

    /// Reference to the LLM connection for assistant functionality in this section
    public let llmConnectionId: UUID?

    // MARK: - Initialization

    public init(
        name: String,
        sectionDescription: String?,
        content: String,
        orderIndex: Int,
        contentGenerationPrompt: String?,
        contentUsagePrompt: String?,
        isEnabled: Bool,
        llmConnectionId: UUID?,
        createdAt: Date,
        modifiedAt: Date
    ) {
        self.name = name
        self.sectionDescription = sectionDescription
        self.content = content
        self.orderIndex = orderIndex
        self.contentGenerationPrompt = contentGenerationPrompt
        self.contentUsagePrompt = contentUsagePrompt
        self.isEnabled = isEnabled
        self.llmConnectionId = llmConnectionId
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }
}
