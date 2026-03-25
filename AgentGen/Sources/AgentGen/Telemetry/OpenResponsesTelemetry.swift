//
//  OpenResponsesTelemetry.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import Foundation
import os

/// OSSignpost-based telemetry for the Open Responses inference backend.
///
/// Emits five named tracks visible in Instruments' os_signpost template
/// when filtering by subsystem `com.rnaszcyn.ContentGenerator.AgentGen`:
///
/// - **AgentRun**: interval spanning the full `run()` call
/// - **Iteration**: interval per LLM iteration
/// - **ToolCall**: interval per tool call (keyed by `callId`)
/// - **ContentDelta**: point event per streaming content delta
/// - **TokenUsage**: point event per usage update
///
/// All methods run on the MainActor Task inside `OpenResponsesBackend.run()`.
/// `@unchecked Sendable` is safe because no cross-thread mutation occurs —
/// the compiler cannot see the MainActor confinement.
public final class OpenResponsesTelemetry: AgentBackendTelemetry, @unchecked Sendable {

    // MARK: - Signposter

    private let signposter = OSSignposter(
        subsystem: "com.rnaszcyn.ContentGenerator.AgentGen",
        category: "OpenResponsesBackend"
    )

    // MARK: - Interval State

    /// State for the AgentRun interval. Nil until `runBegan` is called.
    private var runState: OSSignpostIntervalState? = nil

    /// State for the current Iteration interval. Nil between iterations.
    private var iterationState: OSSignpostIntervalState? = nil

    /// Per-callId states for in-flight ToolCall intervals.
    private var toolStates: [String: OSSignpostIntervalState] = [:]

    public init() {}

    // MARK: - Run Lifecycle

    public func runBegan(projectName: String, model: String, maxIterations: Int) {
        let id = signposter.makeSignpostID()
        runState = signposter.beginInterval(
            "AgentRun", id: id,
            "\(projectName, privacy: .public) model=\(model, privacy: .public) maxIter=\(maxIterations, privacy: .public)"
        )
    }

    public func runEnded(totalIterations: Int, totalInputTokens: Int, totalOutputTokens: Int) {
        guard let state = runState else { return }
        signposter.endInterval(
            "AgentRun", state,
            "iterations=\(totalIterations, privacy: .public) in=\(totalInputTokens, privacy: .public) out=\(totalOutputTokens, privacy: .public)"
        )
        runState = nil
    }

    public func runFailed(reason: String) {
        guard let state = runState else { return }
        signposter.endInterval("AgentRun", state, "FAILED \(reason, privacy: .public)")
        runState = nil
    }

    // MARK: - Iteration Lifecycle

    public func iterationBegan(_ n: Int) {
        let id = signposter.makeSignpostID()
        iterationState = signposter.beginInterval(
            "Iteration", id: id, "n=\(n, privacy: .public)"
        )
    }

    public func iterationEnded(_ n: Int) {
        guard let state = iterationState else { return }
        signposter.endInterval("Iteration", state, "n=\(n, privacy: .public)")
        iterationState = nil
    }

    // MARK: - Tool Calls

    public func toolCallBegan(name: String, callId: String) {
        let id = signposter.makeSignpostID()
        toolStates[callId] = signposter.beginInterval(
            "ToolCall", id: id, "\(name, privacy: .public)"
        )
    }

    public func toolCallEnded(name: String, callId: String, duration: Duration) {
        guard let state = toolStates.removeValue(forKey: callId) else { return }
        let ms = duration.components.seconds * 1000
            + duration.components.attoseconds / 1_000_000_000_000_000
        signposter.endInterval(
            "ToolCall", state,
            "\(name, privacy: .public) \(ms, privacy: .public)ms"
        )
    }

    // MARK: - Content Streaming

    public func contentDeltaReceived(characterCount: Int) {
        signposter.emitEvent("ContentDelta", "\(characterCount, privacy: .public) chars")
    }

    // MARK: - Prompt Capture

    public func promptSent(systemPrompt: String, userMessage: String) {
        let timestamp = Int(Date().timeIntervalSince1970)
        let filename = "agentgen_prompt_\(timestamp).txt"
        let url = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent(filename)
        let content = """
            === SYSTEM PROMPT ===

            \(systemPrompt)

            === USER MESSAGE ===

            \(userMessage)
            """
        try? content.write(to: url, atomically: true, encoding: .utf8)
        signposter.emitEvent("PromptSent", "\(url.path, privacy: .public)")
    }

    // MARK: - Session Configuration

    public func makeSessionConfiguration() -> URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.protocolClasses = [AgentRequestLoggingURLProtocol.self]
        return config
    }

    // MARK: - Token Usage

    public func tokenUsageUpdated(
        iteration: Int,
        inputTokens: Int,
        outputTokens: Int,
        reasoningTokens: Int,
        cachedTokens: Int
    ) {
        signposter.emitEvent(
            "TokenUsage",
            "iter=\(iteration, privacy: .public) in=\(inputTokens, privacy: .public) out=\(outputTokens, privacy: .public) reasoning=\(reasoningTokens, privacy: .public) cached=\(cachedTokens, privacy: .public)"
        )
    }
}
#endif
