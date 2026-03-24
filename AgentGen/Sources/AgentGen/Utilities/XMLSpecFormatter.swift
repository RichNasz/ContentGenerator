//
//  XMLSpecFormatter.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

// MARK: - XML Spec Formatting

/// Formats enabled `AgentSection`s into XML-wrapped text for inclusion in the first LLM message.
///
/// Replicates the XML formatting used by `ProjectMarkdownBuilder` in the main app:
/// camelCase tag names, XML-escaped content, and inline usage prompts.
enum XMLSpecFormatter {

    /// Returns a manifest line listing all enabled section names with a count.
    ///
    /// Example: `"Enabled Sections (3): Goal, Formatting, Style"`
    ///
    /// - Parameter sections: The project's specification sections
    /// - Returns: A manifest string with count and comma-separated names
    static func formatSectionManifest(sections: [AgentSection]) -> String {
        let enabled = sections.filter(\.isEnabled)
        let names = enabled.map(\.name).joined(separator: ", ")
        return "Enabled Sections (\(enabled.count)): \(names)"
    }

    /// Formats all enabled sections as XML-wrapped blocks separated by blank lines.
    ///
    /// - Parameter sections: The project's specification sections
    /// - Returns: A string containing all enabled sections wrapped in XML tags
    static func formatSectionsAsXML(sections: [AgentSection]) -> String {
        let enabledSections = sections.filter(\.isEnabled)
        var usedTagNames: Set<String> = []
        var xmlBlocks: [String] = []

        for section in enabledSections {
            let tagName = uniqueXMLTagName(for: section.name, usedNames: &usedTagNames)
            let block = buildXMLSection(
                tagName: tagName,
                content: section.content,
                usagePrompt: section.contentUsagePrompt
            )
            xmlBlocks.append(block)
        }

        return xmlBlocks.joined(separator: "\n\n")
    }

    // MARK: - Private Helpers

    /// Converts a section name to a camelCase XML tag name.
    private static func xmlTagName(for sectionName: String) -> String {
        let cleaned = sectionName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "[^a-zA-Z0-9\\s]", with: "", options: .regularExpression)

        let words = cleaned.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        guard !words.isEmpty else { return "section" }

        let first = words[0].lowercased()
        let rest = words.dropFirst().map { $0.capitalized }
        let camelCase = ([first] + rest).joined()

        return camelCase.isEmpty ? "section" : camelCase
    }

    /// Generates a unique XML tag name, appending indices to handle duplicates.
    private static func uniqueXMLTagName(for sectionName: String, usedNames: inout Set<String>) -> String {
        let baseName = xmlTagName(for: sectionName)

        if !usedNames.contains(baseName) {
            usedNames.insert(baseName)
            return baseName
        }

        var index = 1
        var uniqueName = "\(baseName)\(index)"

        while usedNames.contains(uniqueName) {
            index += 1
            uniqueName = "\(baseName)\(index)"
        }

        usedNames.insert(uniqueName)
        return uniqueName
    }

    /// Escapes content for XML safety.
    private static func escapeXMLContent(_ content: String) -> String {
        content
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }

    /// Builds a complete XML section with optional usage prompt preceding the content.
    private static func buildXMLSection(tagName: String, content: String, usagePrompt: String?) -> String {
        var formattedContent = ""

        if let usagePrompt, !usagePrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            formattedContent += usagePrompt.trimmingCharacters(in: .whitespacesAndNewlines) + "\n\n"
        }

        formattedContent += content

        let escapedContent = escapeXMLContent(formattedContent)
        return "<\(tagName)>\n\(escapedContent)\n</\(tagName)>"
    }
}
