//
//  AgentInferenceBackend.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// An inference backend that produces a stream of ``AgentEvent`` values.
///
/// Conforming types encapsulate all inference logic for a specific backend
/// (e.g., Apple Intelligence, Open Responses API). The view consumes the
/// event stream without knowing the backend implementation details.
public protocol AgentInferenceBackend {
    /// Run the agent and yield events. The stream completes when generation is done.
    /// Cancellation of the consuming Task cancels the generation.
    func run(
        projectName: String,
        systemPrompt: String?,
        sections: [AgentSection],
        instructions: String
    ) -> AsyncThrowingStream<AgentEvent, any Error>
}
