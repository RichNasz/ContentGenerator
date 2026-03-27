# Swift Technical Specifications

## Purpose
Swift-specific implementation guidance for AgentGen. References CommonSpecs for shared patterns.

**Swift 6 + Default MainActor Context**: This package is consumed by ContentGenerator, which uses Swift 6 with default actor isolation set to MainActor.

## Architecture Patterns

### Architecture Foundation
This package follows patterns defined in the CommonSpecs:
- **Swift 6 Concurrency**: See [SwiftCodeGeneration.md](../../../CommonSpecs/SwiftCodeGeneration.md)
- **SwiftUI State Management**: See [SwiftUIWithoutMVVM.md](../../../CommonSpecs/SwiftUIWithoutMVVM.md)

### Backend Abstraction
The package uses a protocol-based backend pattern. Each inference backend conforms to `AgentInferenceBackend` and yields `AgentEvent` values through `AsyncThrowingStream`. The view consumes events without knowing the backend implementation.

## Key Types

### AgentEvent (Models/AgentEvent.swift)
`AgentEvent` is a `public enum` conforming to `Sendable`, representing every event a backend can emit. Cases:
- `statusUpdate(String)` — human-readable status message
- `toolCallStarted(callId: String, name: String, arguments: String)` — tool invocation beginning
- `toolCallCompleted(callId: String, name: String, result: String, duration: Duration)` — tool invocation finished with result and elapsed time
- `contentDelta(String)` — incremental text fragment from the LLM
- `thinkingBlock(String)` — raw `<think>...</think>` content extracted from the stream
- `thinkingSummary(String)` — deduplicated thinking summary for display
- `tokenUsage(TokenUsageSnapshot)` — token counters for the current iteration
- `activeToolChanged(String?)` — currently active tool name or `nil` when idle
- `sectionRead(sectionName: String)` — a spec section was read by the LLM
- `completed(String)` — generation finished; associated value is the full content string
- `failed(String)` — generation failed; associated value is the error description

Imports `SwiftOpenResponsesDSL` for the `ReasoningEffort` type used by `CloudConnectionConfig`.

### TokenUsageSnapshot (Models/AgentEvent.swift)
`TokenUsageSnapshot` is a `public struct` conforming to `Sendable` with four `Int` properties: `input`, `output`, `reasoning` (defaults to 0), and `cached` (defaults to 0). Passed in `.tokenUsage` events to report per-iteration token counts.

### CloudConnectionConfig (Models/AgentEvent.swift)
`CloudConnectionConfig` is a `public struct` conforming to `Sendable` carrying resolved connection parameters for `OpenResponsesBackend` — removing any SwiftData dependency from the backends:
- `apiURL: String` — full endpoint URL
- `apiKey: String` — bearer token
- `model: String` — model identifier
- `requestTimeoutSeconds: Int` — request timeout
- `reasoningEffort: ReasoningEffort?` — optional reasoning effort level

### AgentInferenceBackend (Models/AgentInferenceBackend.swift)
`AgentInferenceBackend` is a `public protocol` with a single method `run(projectName:systemPrompt:sections:instructions:)` returning `AsyncThrowingStream<AgentEvent, any Error>`. Conformers: `AppleIntelligenceBackend`, `OpenResponsesBackend`, and the internal `FailingBackend` (used when configuration is invalid).

### AgentBackend (Models/AgentBackend.swift)
`AgentBackend` is a `public enum` conforming to `Hashable` used as the picker selection type:
- `appleIntelligence` — on-device Foundation Models inference
- `cloudConnection(UUID)` — cloud/local inference; carries the `LLMConnection.id`

### AgentBackendTelemetry (Models/AgentBackendTelemetry.swift)
`AgentBackendTelemetry` is a `public protocol` constrained to `Sendable` so the existential `any AgentBackendTelemetry` is safe to capture in backend `Task` closures. All methods are called synchronously from the MainActor Task inside `run()`. Methods:
- `runBegan(projectName:model:maxIterations:)` — signals run start
- `runEnded(totalIterations:totalInputTokens:totalOutputTokens:)` — signals run end with totals
- `runFailed(reason:)` — signals failure with description
- `iterationBegan(_:)` and `iterationEnded(_:)` — bracket each LLM iteration
- `toolCallBegan(name:callId:)` and `toolCallEnded(name:callId:duration:)` — bracket tool invocations
- `contentDeltaReceived(characterCount:)` — reports streaming text chunk size
- `tokenUsageUpdated(iteration:inputTokens:outputTokens:reasoningTokens:cachedTokens:)` — reports per-iteration token counts
- `promptSent(systemPrompt:userMessage:)` — records the full prompt before streaming begins
- `makeSessionConfiguration()` — returns the `URLSessionConfiguration` to pass to `LLMClient`; instrumented implementations register `AgentRequestLoggingURLProtocol` in `protocolClasses`; default returns `.default`

Each backend type provides its own conforming implementation. Uninstrumented backends use `DisabledAgentTelemetry`.

### DisabledAgentTelemetry (Models/AgentBackendTelemetry.swift)
`DisabledAgentTelemetry` is a `public struct` conforming to `AgentBackendTelemetry` with no stored state. All methods have empty bodies — the optimizer eliminates all call sites. `makeSessionConfiguration()` returns `.default` with zero overhead. Trivially `Sendable`. Used for `OpenResponsesBackend` when the user has disabled telemetry, and for `AppleIntelligenceBackend` and any future uninstrumented backend.

### OpenResponsesTelemetry (Telemetry/OpenResponsesTelemetry.swift)
`OpenResponsesTelemetry` is a `public final class` guarded with `#if os(macOS)`, conforming to `AgentBackendTelemetry` and marked `@unchecked Sendable` (all methods run on the MainActor Task; `@unchecked` is safe because there is no cross-thread mutable state). Uses `OSSignposter` with subsystem `"com.rnaszcyn.ContentGenerator.AgentGen"` and category `"OpenResponsesBackend"`. Stores `OSSignpostIntervalState?` for the active run, current iteration, and a `[String: OSSignpostIntervalState]` keyed by `callId` for active tool calls. Seven Instruments tracks: `AgentRun` (interval), `Iteration` (interval), `ToolCall` (interval), `ContentDelta` (event), `TokenUsage` (event), `PromptSent` (event), `HTTPRequest` (event). `makeSessionConfiguration()` returns a `.default` copy with `AgentRequestLoggingURLProtocol` registered in `protocolClasses` — registered only on the `LLMClient` session, never globally. All interpolated values use `privacy: .public`. Create a fresh instance per run; do not share across runs.

### AgentRequestLoggingURLProtocol (Telemetry/AgentRequestLoggingURLProtocol.swift)
`AgentRequestLoggingURLProtocol` is an internal `final class` guarded with `#if os(macOS)`, subclassing `URLProtocol` and conforming to `URLSessionDataDelegate` and `@unchecked Sendable`. Registered via `URLSessionConfiguration.protocolClasses` only — never globally. Behavior:
- `canInit(with:)` uses a per-request property flag (`"AgentRequestLoggingHandled"`) to prevent infinite recursion when the internal forwarding session re-issues the request
- `startLoading()` writes `request.httpBody` (the full JSON POST body) to `/tmp/agentgen_http_post_<timestamp>.json`, emits an `"HTTPRequest"` signpost event with the file path, then forwards the request via a delegate-based `URLSessionDataTask` on an internal `.default` session
- SSE streaming is preserved: `URLSessionDataDelegate` methods (`didReceive response:`, `didReceive data:`, `didCompleteWithError:`) forward each chunk immediately via `URLProtocolClient` so the upstream `AsyncBytes.lines` loop receives data incrementally
- `@unchecked Sendable` required because Swift 6 default MainActor isolation infers `Sendable` on final classes, but the `NSObject` superclass constraint prevents direct conformance; semantically safe because there is no cross-thread mutable state
- Has its own `static OSSignposter` instance; does not depend on `OpenResponsesTelemetry`

### AgentSection (Models/AgentSection.swift)
`AgentSection` is a `public struct` conforming to `Sendable` with no SwiftData dependency. Properties:
- `name: String` — section name
- `content: String` — section body text
- `contentGenerationPrompt: String?` — optional prompt for AI-assisted generation
- `contentUsagePrompt: String?` — optional prompt for how section content should be applied
- `isEnabled: Bool` — whether this section participates in generation

Maps from `SpecificationSectionData` at the ContentGenerator app layer.

### AgentGenerationWindowState (Models/AgentGenerationWindowState.swift)
`AgentGenerationWindowState` is a `public @Observable class` with no explicit `@MainActor` (default isolation applies). Public stored properties:
- `projectName: String`
- `projectSystemPrompt: String?`
- `projectLLMConnectionId: UUID?`
- `sections: [AgentSection]`
- `onContentGenerated: ((String) -> Void)?`
- `onLLMSelectionChanged: ((UUID?) -> Void)?`

Window ID: `"project-agent-generation-responses"`

### SectionReadTracker (Models/SectionReadTracker.swift)
`SectionReadTracker` is a `public actor` that tracks which sections have been read during a run. Methods:
- `markRead(_ name: String)` — records that the named section was accessed
- `unreadSections(from sections: [AgentSection]) -> [AgentSection]` — returns sections not yet marked read

Freshly allocated per backend `run()` call so prior session reads do not bleed into new runs. Actor isolation makes it safely `Sendable` for capture in tool handler closures.

## Tool Factories

### ProjectSpecTools (Models/ProjectSpecTools.swift) — Open Responses
- Four `@LLMTool`-decorated structs: `ListSectionsTool`, `ReadSectionTool`, `GetUnreadSectionsTool`, `ReadSystemPromptTool`
- `@LLMToolArguments` structs: `NoArguments` (empty), `ReadSectionArguments` with a `sectionName: String` field
- Factory: `public func makeAgentTools(sections:systemPrompt:tracker:) -> [AgentTool]`
- `AgentTool` from `SwiftOpenResponsesDSL` wraps `FunctionToolParam` + handler

### FoundationModelTools (Models/FoundationModelTools.swift) — Apple Intelligence
- Four structs conforming to the `Tool` protocol: `FMListSectionsTool`, `FMReadSectionTool`, `FMGetUnreadSectionsTool`, `FMReadSystemPromptTool`
- Arguments use `@Generable struct Arguments` with `@Guide(description:)` annotations
- Factory: `public func makeFoundationModelTools(sections:systemPrompt:tracker:) -> [any Tool]`
- Tool names use camelCase: `listSections`, `readSection`, `getUnreadSections`, `readSystemPrompt`

## Backend Implementations

### AppleIntelligenceBackend (Backends/AppleIntelligenceBackend.swift)
`AppleIntelligenceBackend` is a `public struct` conforming to `AgentInferenceBackend`. Static property `isAvailable: Bool` wraps `SystemLanguageModel.default.isAvailable`. Uses `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` to avoid `sending` data race errors. All helper methods are `private static` to avoid capturing `self` in the Task closure. Creates `LanguageModelSession` with Foundation Model tools and concise instructions. Uses `respond(to:)` (non-streaming) to avoid rate limiting. Builds minimal user prompt with section names only — no XML spec, respecting the 4,096 token context window. Tool calls extracted from `session.transcript` after `respond()` completes. Section reads reported from `SectionReadTracker`. Handles `LanguageModelSession.GenerationError` and `ToolCallError` with formatted messages.

### OpenResponsesBackend (Backends/OpenResponsesBackend.swift)
`OpenResponsesBackend` is a `public struct` guarded with `#if os(macOS)`, conforming to `AgentInferenceBackend`. Initializer takes `config: CloudConnectionConfig` and `telemetry: any AgentBackendTelemetry` (defaults to `DisabledAgentTelemetry()`). Uses the same `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` pattern as Apple Intelligence, with all helpers as `private static` methods. Creates `LLMClient` with `telemetry.makeSessionConfiguration()` as `sessionConfiguration` — enabling HTTP POST capture when telemetry is active. Creates `ToolSession` with `makeAgentTools()` output. Formats sections as XML via `XMLSpecFormatter` with double manifest listing. Passes a `[any ResponseConfigParameter]` array: `RequestTimeout`, `ResourceTimeout`, `Instructions`, and optional `Reasoning`. Transforms `ToolSessionEvent` → `AgentEvent` in the stream loop. Accumulates token usage across iterations via local counters. Extracts `<think>...</think>` blocks during streaming via `extractCompletedThinkBlocks()`. Handles `LLMError` with formatted messages. Emits telemetry at every LLM interaction point (pre-capture `let telemetry = self.telemetry` before the `Task` — do not reference `self` inside the Task). Telemetry call points: `promptSent` before stream begins; `runBegan` before loop; `iterationBegan`/`iterationEnded` on `.iterationStarted`; `toolCallBegan`/`toolCallEnded` on tool events; `tokenUsageUpdated` on `.usageUpdate` (bind `let iteration` not `_`); `contentDeltaReceived` in `processLLMEvent` on `.contentPartDelta`; `runEnded` after loop; `runFailed` in catch blocks. `processLLMEvent` static function signature includes `telemetry: any AgentBackendTelemetry` as a parameter.

### Concurrency Pattern for Backends
Both backends use the same pattern to avoid Swift 6 `sending` data race errors: `AsyncThrowingStream.makeStream()` produces a `(stream, continuation)` pair; pre-compute any `Sendable` values needed inside; launch `Task { @MainActor in }` that captures only the continuation and pre-computed values; return the stream immediately. `makeStream()` avoids the closure-based initializer's `sending` parameter issues. `@MainActor` Task avoids isolation boundary crossings. Static methods avoid capturing `self` in the Task closure.

## View Layer

### ActivityLogEntry (Views/ActivityLogView.swift)
`ActivityLogEntry` is an `Identifiable` struct with a `UUID` for stable SwiftUI diffing during rapid appends. It has a `kind: Kind` property where `Kind` is an enum with cases:
- `status(String)` — status message
- `thinkingSummary(String)` — deduplicated thinking summary
- `thinkingBlock(String)` — raw thinking content (expandable)
- `toolCallStarted(callId: String, name: String, arguments: String)` — tool invocation in progress (shows spinner)
- `toolCallCompleted(callId: String, name: String, arguments: String, result: String, duration: Duration)` — finished tool call (expandable args/result/duration)
- `tokenUsage(String)` — formatted token count string
- `completed` — generation finished
- `failed(String)` — generation failed with description

### ActivityLogView (Views/ActivityLogView.swift)
Guarded with `#if os(macOS)`. Uses `ScrollViewReader` + `LazyVStack` + `ForEach` over `[ActivityLogEntry]`. Auto-scrolls to bottom via `.onChange(of: entries.count)`. `ActivityLogRow` dispatches to specialized row views by `entry.kind`: `StatusRow`, `ThinkingSummaryRow`, `ThinkingBlockRow` (expandable), `ToolCallInProgressRow` (spinner), `ToolCallCompletedRow` (expandable args/result/duration), `TokenUsageRow`, `CompletionRow`, `FailureRow`. Tool call duration formatted as milliseconds. Tool call result preview truncated at 400 characters.

### ProjectAgentGenerationWindow (Views/ProjectAgentGenerationWindow.swift)
Guarded with `#if os(macOS)`. Receives data as init parameters: `projectName`, `projectSystemPrompt`, `projectLLMConnectionId`, `sections: [AgentSection]`, `modelContext: ModelContext`, `onContentGenerated`, `onLLMSelectionChanged`.

**State variables** (all `@State private var`):
- `llmConnections: [LLMConnection]` — loaded via `modelContext.fetch`
- `selectedBackend: AgentBackend?` — picker selection
- `instructions: String` — user's instruction text
- `isRunning: Bool` — controls run/cancel button state
- `generatedContent: String` — accumulated output text
- `activityLog: [ActivityLogEntry]` — chronological event log
- `errorMessage: String?` and `showingError: Bool` — error alert state
- `tokenUsageSummary: String` — formatted token count for display
- `pendingToolArgs: [String: String]` — in-progress tool call argument cache (keyed by `callId`)
- `sectionReadCounts: [String: Int]` — how many times each section was read
- `toolCallCounts: [String: Int]` — how many times each tool was called
- `selectedReasoningEffort: ReasoningEffort?` — defaults to `.medium`
- `activeTask: Task<Void, Never>?` — current run task for cancellation
- `isTelemetryEnabled: Bool` stored via `@AppStorage("agentTelemetryEnabled")`

**Key computed properties:**
- `configuredLLMConnections` — filters `llmConnections` by `isConfigured && endpointType == .responses`
- `localLLMConnections` — filters `configuredLLMConnections` by `isLocalConnection()` (localhost, 127.0.0.1, 0.0.0.0, ::1)
- `cloudLLMConnections` — non-local connections
- `availableToolNames: [String]` — returns backend-specific tool names based on `selectedBackend`
- `isCloudBackendSelected: Bool` — case check for conditional UI
- `contentDisplayState` — placeholder logic when running vs. completed

**Backend factory (`makeBackend(for:)`):**
- `.appleIntelligence` → `AppleIntelligenceBackend()`
- `.cloudConnection(id)` → resolves `LLMConnection`, builds `CloudConnectionConfig`, returns `OpenResponsesBackend(config:telemetry:)` — passes `OpenResponsesTelemetry()` when `isTelemetryEnabled`, otherwise `DisabledAgentTelemetry()`
- Invalid config → `FailingBackend(message:)`

**Event handling (`handleEvent(_:)`):**
- `.statusUpdate` → append to `activityLog`
- `.toolCallStarted` → cache args in `pendingToolArgs`, append entry
- `.toolCallCompleted` → replace matching started entry in-place, increment `toolCallCounts[name]`
- `.contentDelta` → append to `generatedContent`
- `.thinkingBlock` → append entry
- `.thinkingSummary` → append entry (deduplicated)
- `.tokenUsage` → format + set `tokenUsageSummary`, append entry
- `.activeToolChanged` → no-op (handled by started/completed entries)
- `.sectionRead` → increment `sectionReadCounts[name]`
- `.completed` → set content, append entry, call `onContentGenerated`
- `.failed` → set error, append entry

**Agent execution (`runAgent()`):**
1. Cancel previous `activeTask`
2. `resetRunState()` — clears all logs, content, counts
3. Create backend via `makeBackend(for:)`
4. Consume stream: `for try await event in stream { handleEvent(event) }`
5. Post-run: `updateLastUsed()`, `onLLMSelectionChanged?(id)`, `isRunning = false`

## Utilities

### XMLSpecFormatter (Utilities/XMLSpecFormatter.swift)
- `formatSectionManifest(sections:)` → "Enabled Sections (N): name1, name2, …"
- `formatSectionsAsXML(sections:)` → XML-wrapped section blocks with camelCase tags, usage prompt prepended, XML-escaped content

### String+ThinkingBlocks (Utilities/String+ThinkingBlocks.swift)
- `ThinkingParseResult: Sendable` with `content: String` and `thinkingBlocks: [String]`
- `extractingThinkingBlocks()` — parses `<think>...</think>` tags (case-insensitive), handles unclosed tags

## Dependencies
- `SwiftOpenResponsesDSL`: `ToolSession`, `ToolSessionEvent`, `StreamEvent`, `AgentTool`, `LLMClient`, `LLMError`, `ResponseConfigParameter`, `Reasoning`, `ReasoningEffort`, `RequestTimeout`, `ResourceTimeout`, `Instructions`
- `SwiftLLMToolMacros`: `@LLMTool`, `@LLMToolArguments`
- `LLMmanagement`: `LLMConnection`, `OpenAIEndpointType`
- `FoundationModels` (system framework): `LanguageModelSession`, `SystemLanguageModel`, `Tool`, `@Generable`, `@Guide`

## Concurrency Patterns
- Default MainActor isolation throughout — no explicit `@MainActor` annotations needed
- `SectionReadTracker` is an `actor` — safely `Sendable`
- Backend `run()` methods use `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` — avoids `sending` parameter data race errors
- Backend helper methods are `static` to avoid capturing `self` in Task closures
- `activeTask?.cancel()` before starting new runs — prevents concurrent sessions
- No GCD, no DispatchQueue

## File Structure

Organize `Sources/AgentGen/` into five subdirectories:
- `Models/` — `AgentSection.swift`, `AgentBackend.swift`, `AgentEvent.swift` (AgentEvent, TokenUsageSnapshot, CloudConnectionConfig), `AgentInferenceBackend.swift` (protocol), `AgentBackendTelemetry.swift` (protocol + DisabledAgentTelemetry), `AgentGenerationWindowState.swift`, `SectionReadTracker.swift`, `ProjectSpecTools.swift` (Open Responses tools), `FoundationModelTools.swift` (Apple Intelligence tools)
- `Backends/` — `AppleIntelligenceBackend.swift`, `OpenResponsesBackend.swift`
- `Telemetry/` — `OpenResponsesTelemetry.swift` (`#if os(macOS)`, OSSignpost implementation), `AgentRequestLoggingURLProtocol.swift` (`#if os(macOS)`, URLProtocol HTTP POST capture)
- `Views/` — `ProjectAgentGenerationWindow.swift`, `ActivityLogView.swift`
- `Utilities/` — `XMLSpecFormatter.swift`, `String+ThinkingBlocks.swift`

---
**Last Updated:** 2026-03-27 (converted all code blocks to prose per no-code-in-specs rule)
