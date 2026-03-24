//
//  AgentGenerationWindowState.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Coordinates state for the project agent generation window (Open Responses variant).
///
/// Mirrors the pattern of `ProjectContentGenerationWindowState` in the ContentGenerator app.
/// Injected into the environment and populated by `ProjectDetailView` before
/// `openWindow(id: "project-agent-generation-responses")` is called.
@Observable
public class AgentGenerationWindowState {

    // MARK: - Window Content Configuration

    public var projectName: String = ""
    public var projectSystemPrompt: String? = nil
    public var projectLLMConnectionId: UUID? = nil
    public var sections: [AgentSection] = []

    // MARK: - Callbacks

    /// Called when the agent produces final generated content.
    public var onContentGenerated: ((String) -> Void)? = nil

    /// Called when the user changes the selected LLM connection so the project can persist it.
    public var onLLMSelectionChanged: ((UUID?) -> Void)? = nil

    // MARK: - Lifecycle

    public init() {}

    /// Configures the window with project data.
    ///
    /// Call this before invoking `openWindow(id: "project-agent-generation-responses")`.
    public func openAgentWindow(
        projectName: String,
        systemPrompt: String?,
        llmConnectionId: UUID?,
        sections: [AgentSection],
        onContentGenerated: @escaping (String) -> Void,
        onLLMSelectionChanged: ((UUID?) -> Void)? = nil
    ) {
        self.projectName = projectName
        self.projectSystemPrompt = systemPrompt
        self.projectLLMConnectionId = llmConnectionId
        self.sections = sections
        self.onContentGenerated = onContentGenerated
        self.onLLMSelectionChanged = onLLMSelectionChanged
    }

    /// Resets all state when the window closes.
    public func reset() {
        projectName = ""
        projectSystemPrompt = nil
        projectLLMConnectionId = nil
        sections = []
        onContentGenerated = nil
        onLLMSelectionChanged = nil
    }
}
