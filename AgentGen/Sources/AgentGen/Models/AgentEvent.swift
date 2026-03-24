//
//  AgentEvent.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftOpenResponsesDSL

// MARK: - Agent Events

/// Events yielded by inference backends during agent execution.
public enum AgentEvent: Sendable {
    /// A status message for the user (e.g., "Thinking…", "Calling readSection…").
    case statusUpdate(String)
    /// A tool call has started executing.
    case toolCallStarted(callId: String, name: String, arguments: String)
    /// A tool call completed with its result.
    case toolCallCompleted(callId: String, name: String, result: String, duration: Duration)
    /// Incremental content delta appended to generated text.
    case contentDelta(String)
    /// A complete thinking/reasoning block was produced.
    case thinkingBlock(String)
    /// A reasoning summary line.
    case thinkingSummary(String)
    /// Token usage update (cumulative).
    case tokenUsage(TokenUsageSnapshot)
    /// The active tool name changed (nil = no tool active).
    case activeToolChanged(String?)
    /// A section was read by the agent.
    case sectionRead(sectionName: String)
    /// Generation completed successfully with final content.
    case completed(String)
    /// Generation failed with a user-facing error message.
    case failed(String)
}

// MARK: - Token Usage

/// Cumulative token usage at a point in time.
public struct TokenUsageSnapshot: Sendable {
    public let input: Int
    public let output: Int
    public let reasoning: Int
    public let cached: Int

    public init(input: Int, output: Int, reasoning: Int = 0, cached: Int = 0) {
        self.input = input
        self.output = output
        self.reasoning = reasoning
        self.cached = cached
    }
}

// MARK: - Cloud Connection Configuration

/// Configuration for a cloud LLM connection, extracted from the SwiftData model.
public struct CloudConnectionConfig: Sendable {
    public let apiURL: String
    public let apiKey: String
    public let model: String
    public let requestTimeoutSeconds: Int
    public let reasoningEffort: ReasoningEffort?

    public init(
        apiURL: String,
        apiKey: String,
        model: String,
        requestTimeoutSeconds: Int,
        reasoningEffort: ReasoningEffort?
    ) {
        self.apiURL = apiURL
        self.apiKey = apiKey
        self.model = model
        self.requestTimeoutSeconds = requestTimeoutSeconds
        self.reasoningEffort = reasoningEffort
    }
}
