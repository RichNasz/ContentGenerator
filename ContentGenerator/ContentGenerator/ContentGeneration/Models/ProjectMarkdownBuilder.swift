//
//  ProjectMarkdownBuilder.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

// MARK: - Project Markdown Builder

/// Builder for creating markdown representations of projects with XML-wrapped specification sections
/// Designed for both LLM prompt generation and markdown export functionality
nonisolated struct ProjectMarkdownBuilder: Sendable {

    // MARK: - Properties

    /// Store section data directly to avoid actor isolation issues
    private let sections: [(name: String, content: String, orderIndex: Int, contentUsagePrompt: String?, isEnabled: Bool)]

    /// Store attachment data directly to avoid actor isolation issues
    private let attachments: [(fileName: String, fileSize: String, fileType: String, createdAt: Date)]

    // MARK: - Initialization

    /// Initialize with raw section data
    init(sections: [(name: String, content: String, orderIndex: Int, contentUsagePrompt: String?, isEnabled: Bool)], attachments: [(fileName: String, fileSize: String, fileType: String, createdAt: Date)] = []) {
        self.sections = sections
        self.attachments = attachments
    }

    // MARK: - Core Functionality

    /// Builds minimal markdown representation with XML-wrapped sections including usage prompts
    /// - Returns: Markdown string with each section wrapped in camelCase XML tags, including content usage prompts when available
    func buildMinimalMarkdown() -> String {
        let enabledSections = sections.filter { $0.isEnabled }
        let sortedSections = enabledSections.sorted { $0.orderIndex < $1.orderIndex }

        var markdown = ""
        var usedTagNames: Set<String> = []

        for section in sortedSections {
            let tagName = uniqueXMLTagName(for: section.name, usedNames: &usedTagNames)
            let xmlSection = buildXMLSection(
                tagName: tagName,
                content: section.content,
                usagePrompt: section.contentUsagePrompt
            )

            markdown += xmlSection + "\n\n"
        }

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Builds markdown for LLM prompt generation with system role context and inline usage guidance
    /// - Parameters:
    ///   - systemPrompt: Optional system/developer role prompt for LLM context
    ///   - additionalInstructions: Optional additional context for the LLM
    /// - Returns: Enhanced prompt string with system role and XML sections containing inline usage guidance
    func buildForLLMPrompt(systemPrompt: String? = nil, additionalInstructions: String? = nil) -> String {
        var prompt = ""

        // Add system role context if provided
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            prompt += "**System Role:**\n\(systemPrompt)\n\n"
        }

        prompt += "Generate content based on the following specification:\n\n"

        let enabledSections = sections.filter { $0.isEnabled }
        let sortedSections = enabledSections.sorted { $0.orderIndex < $1.orderIndex }
        var usedTagNames: Set<String> = []

        // Add XML-wrapped sections with inline usage prompts
        for section in sortedSections {
            let tagName = uniqueXMLTagName(for: section.name, usedNames: &usedTagNames)
            let xmlSection = buildXMLSection(
                tagName: tagName,
                content: section.content,
                usagePrompt: section.contentUsagePrompt
            )

            prompt += xmlSection + "\n\n"
        }

        if let additional = additionalInstructions, !additional.isEmpty {
            prompt += "**Additional Instructions:**\n\(additional)\n\n"
        }

        prompt += "Please generate appropriate content that addresses all the specification sections above."

        return prompt
    }

    /// Builds markdown for user message in LLM conversations (excludes system prompt to prevent duplication)
    ///
    /// IMPORTANT: Use this method when system prompt is already being sent as a system role message
    /// to avoid duplicating the system prompt in the user message content.
    ///
    /// - Parameter additionalInstructions: Optional additional context for the LLM
    /// - Returns: User message string with XML sections and usage guidance, without system prompt
    func buildForUserMessage(additionalInstructions: String? = nil) -> String {
        var prompt = "Generate content based on the following specification:\n\n"

        let enabledSections = sections.filter { $0.isEnabled }
        let sortedSections = enabledSections.sorted { $0.orderIndex < $1.orderIndex }
        var usedTagNames: Set<String> = []

        // Add XML-wrapped sections with inline usage prompts
        for section in sortedSections {
            let tagName = uniqueXMLTagName(for: section.name, usedNames: &usedTagNames)
            let xmlSection = buildXMLSection(
                tagName: tagName,
                content: section.content,
                usagePrompt: section.contentUsagePrompt
            )

            prompt += xmlSection + "\n\n"
        }

        if let additional = additionalInstructions, !additional.isEmpty {
            prompt += "**Additional Instructions:**\n\(additional)\n\n"
        }

        prompt += "Please generate appropriate content that addresses all the specification sections above."

        return prompt
    }

    /// Builds markdown for export with optional system prompt preamble
    /// - Parameter systemPrompt: Optional system/developer role prompt to include as preamble
    /// - Returns: Well-formatted markdown with optional preamble, XML sections, and attachments
    func buildForExport(systemPrompt: String? = nil) -> String {
        var markdown = ""

        // Add system prompt as preamble if provided
        if let systemPrompt = systemPrompt, !systemPrompt.isEmpty {
            markdown += systemPrompt
            markdown += "\n\n"
        }

        // Add the XML-wrapped sections
        let specificationContent = buildMinimalMarkdown()
        if !specificationContent.isEmpty {
            markdown += specificationContent
        }

        // Add attachments section if there are any attachments
        let attachmentsContent = buildAttachmentsMarkdown()
        if !attachmentsContent.isEmpty {
            if !markdown.isEmpty {
                markdown += "\n\n"
            }
            markdown += attachmentsContent
        }

        return markdown
    }

    /// Builds markdown section for reference content files
    /// - Returns: Formatted markdown listing reference content files with metadata
    private func buildAttachmentsMarkdown() -> String {
        guard !attachments.isEmpty else { return "" }

        var markdown = "## Reference Content Files\n\n"

        let sortedAttachments = attachments.sorted { $0.createdAt < $1.createdAt }

        for attachment in sortedAttachments {
            markdown += "- **\(attachment.fileName)** (\(attachment.fileSize))\n"
            markdown += "  - Type: \(attachment.fileType)\n"
            markdown += "  - Added: \(formatDate(attachment.createdAt))\n\n"
        }

        return markdown.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Formats a date for markdown display
    /// - Parameter date: The date to format
    /// - Returns: Formatted date string
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Utility Methods

    /// Converts section name to camelCase XML tag name
    /// - Parameter sectionName: The original section name
    /// - Returns: Valid camelCase XML tag name
    private func xmlTagName(for sectionName: String) -> String {
        // Clean the input - remove extra whitespace and non-alphanumeric characters except spaces
        let cleaned = sectionName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)

        // Split into words and filter out empty strings
        let words = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return "section" }

        // Create camelCase: first word lowercase, subsequent words capitalized
        let first = words[0].lowercased()
        let rest = words.dropFirst().map { $0.capitalized }
        let camelCase = ([first] + rest).joined()

        // Ensure we have a valid result
        return camelCase.isEmpty ? "section" : camelCase
    }

    /// Generates a unique XML tag name, handling duplicates by appending indices
    /// - Parameters:
    ///   - sectionName: The original section name
    ///   - usedNames: Set of already used tag names (modified in place)
    /// - Returns: Unique camelCase XML tag name
    private func uniqueXMLTagName(for sectionName: String, usedNames: inout Set<String>) -> String {
        let baseName = xmlTagName(for: sectionName)

        if !usedNames.contains(baseName) {
            usedNames.insert(baseName)
            return baseName
        }

        // Handle duplicates by appending numbers
        var index = 1
        var uniqueName = "\(baseName)\(index)"

        while usedNames.contains(uniqueName) {
            index += 1
            uniqueName = "\(baseName)\(index)"
        }

        usedNames.insert(uniqueName)
        return uniqueName
    }

    /// Escapes content for XML safety
    /// - Parameter content: Raw content string
    /// - Returns: XML-safe content string
    private func escapeXMLContent(_ content: String) -> String {
        return content
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }

    /// Formats section content with optional usage prompt
    /// - Parameters:
    ///   - content: The section content
    ///   - usagePrompt: Optional content usage prompt
    /// - Returns: Formatted content with usage prompt + empty line + content (if prompt exists)
    private func formatSectionContent(content: String, usagePrompt: String?) -> String {
        var formattedContent = ""

        // Add usage prompt if it exists and is not empty
        if let usagePrompt = usagePrompt, !usagePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formattedContent += usagePrompt.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n"
        }

        // Add section content
        formattedContent += content

        return formattedContent
    }

    /// Builds a complete XML section with proper formatting
    /// - Parameters:
    ///   - tagName: The XML tag name
    ///   - content: The section content
    ///   - usagePrompt: Optional content usage prompt
    /// - Returns: Complete XML section string
    private func buildXMLSection(tagName: String, content: String, usagePrompt: String?) -> String {
        let formattedContent = formatSectionContent(content: content, usagePrompt: usagePrompt)
        let escapedContent = escapeXMLContent(formattedContent)

        return "<\(tagName)>\n\(escapedContent)\n</\(tagName)>"
    }
}

// MARK: - Convenience Extensions

extension ProjectMarkdownBuilder {

    /// Initialize from ContentProject SwiftData model
    /// - Parameter project: The ContentProject to build markdown for
    init(project: ContentProject) {
        let projectSections: [(name: String, content: String, orderIndex: Int, contentUsagePrompt: String?, isEnabled: Bool)]

        if let specification = project.specification {
            let sortedSections = specification.sections.sorted { $0.orderIndex < $1.orderIndex }
            projectSections = sortedSections.map { section in
                (
                    name: section.name,
                    content: section.content,
                    orderIndex: Int(section.orderIndex),
                    contentUsagePrompt: section.contentUsagePrompt,
                    isEnabled: section.isEnabled
                )
            }
        } else {
            projectSections = []
        }

        // Extract attachment data
        let projectAttachments = project.sortedAttachments.map { attachment in
            (
                fileName: attachment.originalFileName,
                fileSize: attachment.formattedFileSize,
                fileType: attachment.fileTypeDisplayName,
                createdAt: attachment.createdAt
            )
        }

        self.init(sections: projectSections, attachments: projectAttachments)
    }

    /// Initialize from SpecificationSectionData UI models
    /// - Parameter sectionData: Array of SpecificationSectionData from the UI layer
    init(sectionData: [SpecificationSectionData]) {
        let sections = sectionData.map { section in
            (
                name: section.name,
                content: section.content,
                orderIndex: section.orderIndex,
                contentUsagePrompt: section.contentUsagePrompt,
                isEnabled: section.isEnabled
            )
        }

        // UI section data doesn't include attachments, so pass empty array
        self.init(sections: sections, attachments: [])
    }
}

