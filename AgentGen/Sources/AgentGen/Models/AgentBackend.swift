//
//  AgentBackend.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Represents the selected agent backend for content generation.
public enum AgentBackend: Hashable {
    /// On-device Apple Intelligence via Foundation Models framework
    case appleIntelligence
    /// Cloud-based LLM connection via Open Responses API
    case cloudConnection(UUID)
}
