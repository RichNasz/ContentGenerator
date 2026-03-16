//
//  ContentProject+Extensions.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftData

@Model
final class ContentProject {
    var id: UUID
    var name: String
	var projectDescription: String?
    var createdAt: Date
    var modifiedAt: Date
    var status: ProjectStatus

    // LLM connection selection for content generation
    // Stored as UUID to handle cases where LLM connection is deleted
    var llmConnectionId: UUID?

    // System/developer role prompt for content generation
    // Used as context for LLM requests and preamble for markdown export
    var systemPrompt: String?

    // Proper relationship syntax (prevents ERR-DATA-001)
    @Relationship(deleteRule: .cascade, inverse: \ContentSpecification.project)
    var specification: ContentSpecification?

    @Relationship(deleteRule: .cascade, inverse: \GeneratedContentData.project)
    var generatedContent: [GeneratedContentData]

    @Relationship(deleteRule: .cascade, inverse: \FileAttachment.project)
    var attachments: [FileAttachment]

    init(name: String) {
        self.id = UUID()
        self.name = name
		 self.projectDescription = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.status = .draft
        self.llmConnectionId = nil
        self.systemPrompt = nil
        self.generatedContent = []
        self.attachments = []
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class SpecificationSection {
    var id: UUID
    var name: String
	var sectionDescription: String?
    var content: String
    var orderIndex: Int
    var createdAt: Date
    var modifiedAt: Date

    // LLM Prompts for AI-assisted content generation
    /// Prompt used when asking AI to help generate content FOR this section
    var contentGenerationPrompt: String?
    /// Prompt describing how to USE this section's content when generating project content
    var contentUsagePrompt: String?

    // Enable/disable status for markdown generation
    var isEnabled: Bool = true

    // Inverse relationship to specification
    // Must be optional for SwiftData's automatic relationship management
    var specification: ContentSpecification?

    // Fileprivate init - sections must be created via ContentSpecification.addSection()
    // to ensure proper parent relationship and maintain the invariant that
    // sections are always children of a specification.
    // Cannot be fully private due to SwiftData's @Model macro requirements.
    fileprivate init(name: String, content: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
		 self.sectionDescription = nil
        self.content = content
        self.orderIndex = orderIndex
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.contentGenerationPrompt = nil
        self.contentUsagePrompt = nil
        self.isEnabled = true
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class ContentSpecification {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to project (prevents ERR-DATA-001)
    var project: ContentProject?

    // One-to-many relationship with sections
    @Relationship(deleteRule: .cascade, inverse: \SpecificationSection.specification)
    var sections: [SpecificationSection]

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.sections = []
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }

    // Convenience methods for section management
    func addSection(
        name: String,
        content: String,
        contentGenerationPrompt: String? = nil,
        contentUsagePrompt: String? = nil,
        isEnabled: Bool = true
    ) -> SpecificationSection {
        let newSection = SpecificationSection(
            name: name,
            content: content,
            orderIndex: sections.count
        )
        newSection.contentGenerationPrompt = contentGenerationPrompt
        newSection.contentUsagePrompt = contentUsagePrompt
        newSection.isEnabled = isEnabled
        newSection.specification = self
        sections.append(newSection)
        updateModifiedDate()
        return newSection
    }

    func removeSection(_ section: SpecificationSection) {
        sections.removeAll { $0.id == section.id }
        // Reorder remaining sections
        for (index, remainingSection) in sections.enumerated() {
            remainingSection.orderIndex = index
        }
        updateModifiedDate()
    }

    func moveSection(from sourceIndex: Int, to destinationIndex: Int) {
        guard sourceIndex < sections.count && destinationIndex < sections.count else { return }
        let section = sections.remove(at: sourceIndex)
        sections.insert(section, at: destinationIndex)

        // Update order indices
        for (index, section) in sections.enumerated() {
            section.orderIndex = index
        }
        updateModifiedDate()
    }
}

@Model
final class GeneratedContentData {
    var id: UUID
    var text: String
    var metadataJSON: Data?
    var createdAt: Date
    var modifiedAt: Date
    var llmConnectionId: UUID?

    // Inverse relationship to project
    var project: ContentProject?

    init(text: String, metadata: [String: Any]? = nil, llmConnectionId: UUID? = nil) {
        self.id = UUID()
        self.text = text
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.llmConnectionId = llmConnectionId

        if let metadata = metadata {
            self.metadataJSON = try? JSONSerialization.data(withJSONObject: metadata)
        }
    }

    var metadata: [String: Any]? {
        get {
            guard let data = metadataJSON else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        set {
            if let metadata = newValue {
                self.metadataJSON = try? JSONSerialization.data(withJSONObject: metadata)
            } else {
                self.metadataJSON = nil
            }
        }
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class FileAttachment {
    var id: UUID
    var originalFileName: String
    var fileExtension: String?
    var fileSizeBytes: Int64
    var securityScopedBookmarkData: Data?
    var createdAt: Date
    var modifiedAt: Date
    var isAccessible: Bool

    // Inverse relationship to project
    var project: ContentProject?

    init(originalFileName: String, fileSizeBytes: Int64) {
        self.id = UUID()
        self.originalFileName = originalFileName
        self.fileExtension = URL(fileURLWithPath: originalFileName).pathExtension.lowercased()
        self.fileSizeBytes = fileSizeBytes
        self.securityScopedBookmarkData = nil
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isAccessible = true
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }

    // Computed properties for UI display
    var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }

    var isTextFile: Bool {
        guard let ext = fileExtension else { return false }
        return ["txt", "md", "rtf"].contains(ext)
    }

    var fileTypeDisplayName: String {
        switch fileExtension {
        case "txt":
            return "Plain Text"
        case "md":
            return "Markdown"
        case "rtf":
            return "Rich Text"
        default:
            return "Text File"
        }
    }
}

// MARK: - Project Extensions

extension ContentProject {
    var hasSpecification: Bool {
        return specification != nil
    }

    var hasGeneratedContent: Bool {
        return !generatedContent.isEmpty
    }

    var latestContent: GeneratedContentData? {
        return generatedContent.sorted { $0.createdAt > $1.createdAt }.first
    }

    var hasAttachments: Bool {
        return !attachments.isEmpty
    }

    var sortedAttachments: [FileAttachment] {
        return attachments.sorted { $0.createdAt < $1.createdAt }
    }

    // Convenience methods for file attachment management
    func addAttachment(_ attachment: FileAttachment) {
        attachment.project = self
        attachments.append(attachment)
        updateModifiedDate()
    }

    func removeAttachment(_ attachment: FileAttachment) {
        attachments.removeAll { $0.id == attachment.id }
        updateModifiedDate()
    }

    func removeAttachment(withId id: UUID) {
        attachments.removeAll { $0.id == id }
        updateModifiedDate()
    }
}
