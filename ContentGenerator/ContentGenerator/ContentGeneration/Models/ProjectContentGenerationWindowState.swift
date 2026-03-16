//
//  ProjectContentGenerationWindowState.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftUI

/// Coordinates state for the project content generation window
@Observable
@MainActor
class ProjectContentGenerationWindowState {
    // Window content configuration
    var projectName: String = ""
    var projectSystemPrompt: String? = nil
    var projectLLMConnectionId: UUID? = nil
    var projectMarkdownContent: String = ""

    // Callback to handle generated content (for export functionality)
    var onContentGenerated: ((String) -> Void)? = nil

    // Callback to persist selected LLM connection back to the project
    var onLLMSelectionChanged: ((UUID?) -> Void)? = nil

    // Window lifecycle
    var isWindowRequested: Bool = false

    /// Configures the window with project data and opens it
    func openProjectWindow(
        projectName: String,
        projectSystemPrompt: String?,
        projectLLMConnectionId: UUID?,
        projectMarkdownContent: String,
        onContentGenerated: @escaping (String) -> Void,
        onLLMSelectionChanged: ((UUID?) -> Void)? = nil
    ) {
        self.projectName = projectName
        self.projectSystemPrompt = projectSystemPrompt
        self.projectLLMConnectionId = projectLLMConnectionId
        self.projectMarkdownContent = projectMarkdownContent
        self.onContentGenerated = onContentGenerated
        self.onLLMSelectionChanged = onLLMSelectionChanged
        self.isWindowRequested = true
    }

    /// Resets state when window closes
    func reset() {
        projectName = ""
        projectSystemPrompt = nil
        projectLLMConnectionId = nil
        projectMarkdownContent = ""
        onContentGenerated = nil
        onLLMSelectionChanged = nil
        isWindowRequested = false
    }
}