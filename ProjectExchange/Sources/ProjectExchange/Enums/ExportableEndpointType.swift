//
//  ExportableEndpointType.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// OpenAI endpoint type for import/export operations.
/// Mirrors the LLMmanagement OpenAIEndpointType enum for portability.
public enum ExportableEndpointType: String, Codable, Sendable, CaseIterable {
    case chatCompletions = "chat_completions"
    case responses = "responses"

    /// Human-readable display name
    public var displayName: String {
        switch self {
        case .chatCompletions:
            return "Chat Completions"
        case .responses:
            return "Responses"
        }
    }
}
