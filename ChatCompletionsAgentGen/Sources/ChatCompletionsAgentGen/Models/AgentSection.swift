//
//  AgentSection.swift
//  ChatCompletionsAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// A read-only snapshot of a project specification section for use in agent-based generation.
///
/// Plain `Sendable` value type with no SwiftData dependency, allowing safe passage
/// across actor boundaries into tool handler closures.
public struct AgentSection: Sendable {
    /// The section name displayed to the user and referenced by tools.
    public let name: String
    /// The specification content written for this section.
    public let content: String
    /// The optional prompt guiding AI content generation for this section.
    public let contentGenerationPrompt: String?
    /// The optional prompt describing how this section's content should be applied.
    public let contentUsagePrompt: String?
    /// Whether this section is included in generation.
    public let isEnabled: Bool

    public init(
        name: String,
        content: String,
        contentGenerationPrompt: String? = nil,
        contentUsagePrompt: String? = nil,
        isEnabled: Bool = true
    ) {
        self.name = name
        self.content = content
        self.contentGenerationPrompt = contentGenerationPrompt
        self.contentUsagePrompt = contentUsagePrompt
        self.isEnabled = isEnabled
    }
}
