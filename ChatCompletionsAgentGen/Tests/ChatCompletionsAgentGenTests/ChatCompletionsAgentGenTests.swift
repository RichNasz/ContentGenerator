//
//  ChatCompletionsAgentGenTests.swift
//  ChatCompletionsAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Testing
@testable import ChatCompletionsAgentGen

@Suite("ChatCompletionsAgentGen Tests")
struct ChatCompletionsAgentGenTests {

    // MARK: - AgentSection Tests

    @Test("AgentSection initializes with all fields")
    func agentSectionInitializesAllFields() {
        let section = AgentSection(
            name: "Target Audience",
            content: "Marketing professionals",
            contentGenerationPrompt: "Describe the audience",
            contentUsagePrompt: "Use this to frame all content",
            isEnabled: true
        )

        #expect(section.name == "Target Audience")
        #expect(section.content == "Marketing professionals")
        #expect(section.contentGenerationPrompt == "Describe the audience")
        #expect(section.contentUsagePrompt == "Use this to frame all content")
        #expect(section.isEnabled == true)
    }

    @Test("AgentSection defaults isEnabled to true")
    func agentSectionDefaultsEnabled() {
        let section = AgentSection(name: "Section", content: "Content")
        #expect(section.isEnabled == true)
    }

    // MARK: - AgentGenerationWindowState Tests

    @Test("AgentGenerationWindowState resets to empty state")
    @MainActor
    func windowStateResetsCorrectly() {
        let state = AgentGenerationWindowState()
        state.openAgentWindow(
            projectName: "Test Project",
            systemPrompt: "A system prompt",
            llmConnectionId: UUID(),
            sections: [AgentSection(name: "Section", content: "Content")],
            onContentGenerated: { _ in }
        )

        state.reset()

        #expect(state.projectName.isEmpty)
        #expect(state.projectSystemPrompt == nil)
        #expect(state.projectLLMConnectionId == nil)
        #expect(state.sections.isEmpty)
        #expect(state.onContentGenerated == nil)
        #expect(state.onLLMSelectionChanged == nil)
    }

    @Test("AgentGenerationWindowState openAgentWindow sets all fields")
    @MainActor
    func windowStateOpenSetsFields() {
        let state = AgentGenerationWindowState()
        let id = UUID()
        let sections = [AgentSection(name: "Test", content: "Content")]

        state.openAgentWindow(
            projectName: "My Project",
            systemPrompt: "System prompt",
            llmConnectionId: id,
            sections: sections,
            onContentGenerated: { _ in }
        )

        #expect(state.projectName == "My Project")
        #expect(state.projectSystemPrompt == "System prompt")
        #expect(state.projectLLMConnectionId == id)
        #expect(state.sections.count == 1)
        #expect(state.onContentGenerated != nil)
    }
}
