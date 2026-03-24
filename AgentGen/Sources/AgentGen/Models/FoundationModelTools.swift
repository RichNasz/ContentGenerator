//
//  FoundationModelTools.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import FoundationModels

// MARK: - Tool Types

/// Lists all specification sections with their names and enabled status.
struct FMListSectionsTool: Tool {
    let name = "listSections"
    let description = "Lists all specification sections with name and enabled status. Call first to discover sections."

    let sections: [AgentSection]

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        struct SectionSummary: Encodable {
            let name: String
            let isEnabled: Bool
        }

        let summaries = sections.map { SectionSummary(name: $0.name, isEnabled: $0.isEnabled) }
        let data = try JSONEncoder().encode(summaries)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

/// Reads the full content, generation prompt, and usage prompt for a named specification section.
struct FMReadSectionTool: Tool {
    let name = "readSection"
    let description = "Reads content and prompts for a named section. Use listSections first to get exact names."

    let sections: [AgentSection]
    let tracker: SectionReadTracker

    @Generable
    struct Arguments {
        @Guide(description: "The exact section name from listSections")
        var sectionName: String
    }

    func call(arguments: Arguments) async throws -> String {
        guard let section = sections.first(where: { $0.name == arguments.sectionName }) else {
            return "Section '\(arguments.sectionName)' not found. Use listSections to see available sections."
        }

        await tracker.markRead(section.name)

        var parts: [String] = [
            "Section: \(section.name)",
            "Enabled: \(section.isEnabled)",
            "Content:\n\(section.content)",
        ]

        if let genPrompt = section.contentGenerationPrompt, !genPrompt.isEmpty {
            parts.append("Generation Prompt:\n\(genPrompt)")
        }

        if let usagePrompt = section.contentUsagePrompt, !usagePrompt.isEmpty {
            parts.append("Usage Prompt:\n\(usagePrompt)")
        }

        return parts.joined(separator: "\n\n")
    }
}

/// Returns names of enabled sections not yet read via readSection.
struct FMGetUnreadSectionsTool: Tool {
    let name = "getUnreadSections"
    let description = "Returns names of enabled sections not yet read. Empty array means all read."

    let sections: [AgentSection]
    let tracker: SectionReadTracker

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        let unread = await tracker.unreadSections(from: sections)
        if unread.isEmpty {
            return "[]"
        }
        let names = unread.map { $0.name }
        let data = try JSONEncoder().encode(names)
        return String(data: data, encoding: .utf8) ?? "[]"
    }
}

/// Reads the project's system prompt.
struct FMReadSystemPromptTool: Tool {
    let name = "readSystemPrompt"
    let description = "Reads the project system prompt that provides persistent context."

    let systemPrompt: String?

    @Generable
    struct Arguments {}

    func call(arguments: Arguments) async throws -> String {
        systemPrompt.flatMap { $0.isEmpty ? nil : $0 } ?? "No system prompt configured for this project."
    }
}

// MARK: - Factory

/// Creates Foundation Models tools for use with `LanguageModelSession`.
public func makeFoundationModelTools(sections: [AgentSection], systemPrompt: String?, tracker: SectionReadTracker) -> [any Tool] {
    [
        FMListSectionsTool(sections: sections),
        FMReadSectionTool(sections: sections, tracker: tracker),
        FMReadSystemPromptTool(systemPrompt: systemPrompt),
        FMGetUnreadSectionsTool(sections: sections, tracker: tracker),
    ]
}
