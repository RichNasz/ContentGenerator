//
//  ContentGenerationWindowState.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftUI
import SwiftData

/// Coordinates state for the content generation window
@Observable
class ContentGenerationWindowState {
    // Window content configuration
    var sectionName: String = ""
    var sectionContent: String = ""
    var contentGenerationPrompt: String? = nil
    var projectLLMConnectionId: UUID? = nil
    var projectAttachments: [FileAttachment] = []

    // Callback to handle generated content
    var onContentGenerated: ((String, ContentInsertMode, String?) -> Void)? = nil

    // Window lifecycle
    var isWindowRequested: Bool = false

    /// Configures the window with section data and opens it
    func openWindow(
        sectionName: String,
        sectionContent: String,
        contentGenerationPrompt: String?,
        projectLLMConnectionId: UUID?,
        projectAttachments: [FileAttachment],
        onContentGenerated: @escaping (String, ContentInsertMode, String?) -> Void
    ) {
        self.sectionName = sectionName
        self.sectionContent = sectionContent
        self.contentGenerationPrompt = contentGenerationPrompt
        self.projectLLMConnectionId = projectLLMConnectionId
        self.projectAttachments = projectAttachments
        self.onContentGenerated = onContentGenerated
        self.isWindowRequested = true
    }

    /// Resets state when window closes
    func reset() {
        sectionName = ""
        sectionContent = ""
        contentGenerationPrompt = nil
        projectLLMConnectionId = nil
        projectAttachments = []
        onContentGenerated = nil
        isWindowRequested = false
    }
}
