//
//  AgentBackendTelemetry.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Observes agent backend execution events for external telemetry.
///
/// Conforming types emit signposts, metrics, or other instrumentation.
/// All methods are called synchronously from the backend event loop,
/// which runs on the MainActor. Implementations must be `Sendable`
/// because backend instances are constructed on the view layer and
/// captured in async `Task` closures.
///
/// Long-term, each backend type provides its own conforming implementation.
/// Use ``DisabledAgentTelemetry`` when telemetry is off or not yet
/// supported for a given backend.
public protocol AgentBackendTelemetry: Sendable {

    // MARK: - Run Lifecycle

    /// Called immediately before the ToolSession stream begins.
    func runBegan(projectName: String, model: String, maxIterations: Int)

    /// Called after the stream loop exits normally (not on error).
    func runEnded(totalIterations: Int, totalInputTokens: Int, totalOutputTokens: Int)

    /// Called when the stream loop exits due to a thrown error.
    func runFailed(reason: String)

    // MARK: - Iteration Lifecycle

    /// Called on each `.iterationStarted(n)` event.
    func iterationBegan(_ n: Int)

    /// Called to close the current iteration — either when the next iteration
    /// starts (`n > 1`) or when the run completes.
    func iterationEnded(_ n: Int)

    // MARK: - Tool Calls

    /// Called on each `.toolCallStarted` event.
    func toolCallBegan(name: String, callId: String)

    /// Called on each `.toolCallCompleted` event.
    func toolCallEnded(name: String, callId: String, duration: Duration)

    // MARK: - Content Streaming

    /// Called for each `.contentPartDelta` received during streaming.
    func contentDeltaReceived(characterCount: Int)

    // MARK: - Token Usage

    /// Called on each `.usageUpdate` event from the DSL stream.
    func tokenUsageUpdated(
        iteration: Int,
        inputTokens: Int,
        outputTokens: Int,
        reasoningTokens: Int,
        cachedTokens: Int
    )

    // MARK: - Prompt Capture

    /// Called once per run with the full system prompt and user message sent to the LLM,
    /// before the stream begins. Implementations write this to an external sink
    /// (e.g., a temp file) since the full text exceeds signpost message size limits.
    func promptSent(systemPrompt: String, userMessage: String)

    // MARK: - Session Configuration

    /// Returns the `URLSessionConfiguration` to use when creating `LLMClient`.
    ///
    /// Instrumented implementations return a configuration with a logging `URLProtocol`
    /// registered in `protocolClasses` so every HTTP POST body is captured to a temp file.
    /// The no-op default returns `.default` with zero overhead.
    func makeSessionConfiguration() -> URLSessionConfiguration
}

// MARK: - No-Op Implementation

/// No-op telemetry used when the user has disabled telemetry or when a backend
/// does not yet have a dedicated telemetry implementation.
///
/// All methods are empty and the optimizer eliminates every call site.
public struct DisabledAgentTelemetry: AgentBackendTelemetry {
    public init() {}

    public func runBegan(projectName: String, model: String, maxIterations: Int) {}
    public func runEnded(totalIterations: Int, totalInputTokens: Int, totalOutputTokens: Int) {}
    public func runFailed(reason: String) {}
    public func iterationBegan(_ n: Int) {}
    public func iterationEnded(_ n: Int) {}
    public func toolCallBegan(name: String, callId: String) {}
    public func toolCallEnded(name: String, callId: String, duration: Duration) {}
    public func contentDeltaReceived(characterCount: Int) {}
    public func tokenUsageUpdated(
        iteration: Int,
        inputTokens: Int,
        outputTokens: Int,
        reasoningTokens: Int,
        cachedTokens: Int
    ) {}
    public func promptSent(systemPrompt: String, userMessage: String) {}
    public func makeSessionConfiguration() -> URLSessionConfiguration { .default }
}
