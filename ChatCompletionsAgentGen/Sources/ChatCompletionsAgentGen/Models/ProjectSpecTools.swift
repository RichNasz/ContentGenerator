//
//  ProjectSpecTools.swift
//  ChatCompletionsAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftChatCompletionsDSL
import SwiftChatCompletionsMacros

// MARK: - Shared Argument Types

/// Arguments for tools that take no parameters.
@ChatCompletionsToolArguments
struct NoArguments {}

/// Arguments for the read section tool.
@ChatCompletionsToolArguments
struct ReadSectionArguments {
    @ChatCompletionsToolGuide(description: "The exact name of the section to read, as returned by list_sections_tool")
    var sectionName: String
}

// MARK: - Tool Types

/// Lists all specification sections with their names and enabled status.
///
/// Returns a JSON array of objects with "name" (string) and "isEnabled" (boolean) fields.
/// Call this tool first to discover available sections before reading their content.
@ChatCompletionsTool
struct ListSectionsTool {
    let sections: [AgentSection]

    func call(arguments: NoArguments) async throws -> ToolOutput {
        struct SectionSummary: Encodable {
            let name: String
            let isEnabled: Bool
        }

        let summaries = sections.map { SectionSummary(name: $0.name, isEnabled: $0.isEnabled) }
        let data = try JSONEncoder().encode(summaries)
        let json = String(data: data, encoding: .utf8) ?? "[]"
        return ToolOutput(content: json)
    }
}

/// Reads the full content, generation prompt, and usage prompt for a named specification section.
///
/// Returns a structured text block containing the section's content and all associated prompts.
/// Use list_sections_tool first to get the exact section names.
@ChatCompletionsTool
struct ReadSectionTool {
    let sections: [AgentSection]
    let tracker: SectionReadTracker

    func call(arguments: ReadSectionArguments) async throws -> ToolOutput {
        guard let section = sections.first(where: { $0.name == arguments.sectionName }) else {
            return ToolOutput(content: "Section '\(arguments.sectionName)' not found. Use list_sections_tool to see available sections.")
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

        return ToolOutput(content: parts.joined(separator: "\n\n"))
    }
}

/// Returns the names of enabled sections that the agent has not yet read via read_section_tool.
///
/// Returns a JSON array of section names. When the array is empty, all enabled sections have been read.
/// Call this before writing your final response to confirm completeness.
@ChatCompletionsTool
struct GetUnreadSectionsTool {
    let sections: [AgentSection]
    let tracker: SectionReadTracker

    func call(arguments: NoArguments) async throws -> ToolOutput {
        let unread = await tracker.unreadSections(from: sections)
        if unread.isEmpty {
            return ToolOutput(content: "[]")
        }
        let names = unread.map { $0.name }
        let data = try JSONEncoder().encode(names)
        let json = String(data: data, encoding: .utf8) ?? "[]"
        return ToolOutput(content: json)
    }
}

/// Reads the project's system prompt that provides persistent context for all generation.
///
/// Returns the system prompt string, or a message indicating none is configured.
@ChatCompletionsTool
struct ReadSystemPromptTool {
    let systemPrompt: String?

    func call(arguments: NoArguments) async throws -> ToolOutput {
        let content = systemPrompt.flatMap { $0.isEmpty ? nil : $0 } ?? "No system prompt configured for this project."
        return ToolOutput(content: content)
    }
}

// MARK: - Factory

/// Creates the full set of agent tools initialized with the provided project data.
///
/// Each tool is a pure function over the injected `sections`, `systemPrompt`, and `tracker` data.
/// The returned `AgentTool` values wrap the tool definitions and handlers for use with
/// `ToolSession`.
///
/// - Parameters:
///   - sections: The project's specification sections
///   - systemPrompt: The project's system prompt, if any
///   - tracker: The read tracker for this agent session; allocate a fresh instance per run
/// - Returns: Four `AgentTool` values: list sections, read section, read system prompt, get unread sections
public func makeAgentTools(sections: [AgentSection], systemPrompt: String?, tracker: SectionReadTracker) -> [AgentTool] {
    [
        AgentTool(ListSectionsTool(sections: sections)),
        AgentTool(ReadSectionTool(sections: sections, tracker: tracker)),
        AgentTool(ReadSystemPromptTool(systemPrompt: systemPrompt)),
        AgentTool(GetUnreadSectionsTool(sections: sections, tracker: tracker)),
    ]
}
