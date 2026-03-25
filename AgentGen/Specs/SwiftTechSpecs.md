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
```swift
public enum AgentEvent: Sendable {
    case statusUpdate(String)
    case toolCallStarted(callId: String, name: String, arguments: String)
    case toolCallCompleted(callId: String, name: String, result: String, duration: Duration)
    case contentDelta(String)
    case thinkingBlock(String)
    case thinkingSummary(String)
    case tokenUsage(TokenUsageSnapshot)
    case activeToolChanged(String?)
    case sectionRead(sectionName: String)
    case completed(String)
    case failed(String)
}
```
- Unified event type consumed by the view from any backend
- Imports `SwiftOpenResponsesDSL` for `ReasoningEffort` type used by `CloudConnectionConfig`

### TokenUsageSnapshot (Models/AgentEvent.swift)
```swift
public struct TokenUsageSnapshot: Sendable {
    public let input: Int
    public let output: Int
    public let reasoning: Int  // default 0
    public let cached: Int     // default 0
}
```

### CloudConnectionConfig (Models/AgentEvent.swift)
```swift
public struct CloudConnectionConfig: Sendable {
    public let apiURL: String
    public let apiKey: String
    public let model: String
    public let requestTimeoutSeconds: Int
    public let reasoningEffort: ReasoningEffort?
}
```
- Resolved connection parameters passed to `OpenResponsesBackend` — no SwiftData dependency in backends

### AgentInferenceBackend (Models/AgentInferenceBackend.swift)
```swift
public protocol AgentInferenceBackend {
    func run(
        projectName: String,
        systemPrompt: String?,
        sections: [AgentSection],
        instructions: String
    ) -> AsyncThrowingStream<AgentEvent, any Error>
}
```
- Conformers: `AppleIntelligenceBackend`, `OpenResponsesBackend`, `FailingBackend` (private, for invalid config)

### AgentBackend (Models/AgentBackend.swift)
```swift
public enum AgentBackend: Hashable {
    case appleIntelligence
    case cloudConnection(UUID)
}
```
- Picker selection type — `cloudConnection` carries the `LLMConnection.id`

### AgentBackendTelemetry (Models/AgentBackendTelemetry.swift)
```swift
public protocol AgentBackendTelemetry: Sendable {
    func runBegan(projectName: String, model: String, maxIterations: Int)
    func runEnded(totalIterations: Int, totalInputTokens: Int, totalOutputTokens: Int)
    func runFailed(reason: String)
    func iterationBegan(_ n: Int)
    func iterationEnded(_ n: Int)
    func toolCallBegan(name: String, callId: String)
    func toolCallEnded(name: String, callId: String, duration: Duration)
    func contentDeltaReceived(characterCount: Int)
    func tokenUsageUpdated(iteration: Int, inputTokens: Int, outputTokens: Int,
                           reasoningTokens: Int, cachedTokens: Int)
}
```
- `Sendable`-constrained so the existential `any AgentBackendTelemetry` is safe to capture in backend `Task` closures
- All methods called synchronously from the MainActor Task inside `run()` — no locking needed
- Each backend type provides its own conforming implementation; uninstrumented backends use `DisabledAgentTelemetry`

### DisabledAgentTelemetry (Models/AgentBackendTelemetry.swift)
```swift
public struct DisabledAgentTelemetry: AgentBackendTelemetry {
    public init()
    // All methods are empty — optimizer eliminates all call sites
}
```
- Default telemetry for `OpenResponsesBackend` when user has disabled the toggle
- Also used for `AppleIntelligenceBackend` and any future uninstrumented backend
- Trivially `Sendable` as a struct with no stored state

### OpenResponsesTelemetry (Telemetry/OpenResponsesTelemetry.swift)
```swift
#if os(macOS)
public final class OpenResponsesTelemetry: AgentBackendTelemetry, @unchecked Sendable {
    // OSSignposter subsystem: "com.rnaszcyn.ContentGenerator.AgentGen"
    // OSSignposter category: "OpenResponsesBackend"
    public init()
}
#endif
```
- `#if os(macOS)` — matches `OpenResponsesBackend` guard
- `@unchecked Sendable` — all methods run on the MainActor Task; compiler cannot see the confinement but it is semantically safe
- Stores `OSSignpostIntervalState?` for the run, current iteration, and a `[String: OSSignpostIntervalState]` for active tool calls (keyed by `callId`)
- Five Instruments tracks: `AgentRun` (interval), `Iteration` (interval), `ToolCall` (interval), `ContentDelta` (event), `TokenUsage` (event)
- All interpolated values use `privacy: .public` — appropriate for a developer profiling tool
- Fresh instance created per run; do not share instances across runs

### AgentSection (Models/AgentSection.swift)
```swift
public struct AgentSection: Sendable {
    public let name: String
    public let content: String
    public let contentGenerationPrompt: String?
    public let contentUsagePrompt: String?
    public let isEnabled: Bool
}
```
- Plain `Sendable` struct, no SwiftData dependency
- Maps from `SpecificationSectionData` at the ContentGenerator app layer

### AgentGenerationWindowState (Models/AgentGenerationWindowState.swift)
```swift
@Observable
public class AgentGenerationWindowState {
    public var projectName: String
    public var projectSystemPrompt: String?
    public var projectLLMConnectionId: UUID?
    public var sections: [AgentSection]
    public var onContentGenerated: ((String) -> Void)?
    public var onLLMSelectionChanged: ((UUID?) -> Void)?
}
```
- No explicit `@MainActor` — default isolation applies
- Window ID: `"project-agent-generation-responses"`

### SectionReadTracker (Models/SectionReadTracker.swift)
```swift
public actor SectionReadTracker {
    public init()
    func markRead(_ name: String)
    func unreadSections(from sections: [AgentSection]) -> [AgentSection]
}
```
- Freshly allocated per backend `run()` call so prior session reads do not bleed
- Actor isolation makes it safely `Sendable` for capture in tool handler closures

## Tool Factories

### ProjectSpecTools (Models/ProjectSpecTools.swift) — Open Responses
- Four `@LLMTool`-decorated structs: `ListSectionsTool`, `ReadSectionTool`, `GetUnreadSectionsTool`, `ReadSystemPromptTool`
- `@LLMToolArguments` structs: `NoArguments` (empty), `ReadSectionArguments { sectionName: String }`
- Factory: `public func makeAgentTools(sections:systemPrompt:tracker:) -> [AgentTool]`
- `AgentTool` from `SwiftOpenResponsesDSL` wraps `FunctionToolParam` + handler

### FoundationModelTools (Models/FoundationModelTools.swift) — Apple Intelligence
- Four structs conforming to `Tool` protocol: `FMListSectionsTool`, `FMReadSectionTool`, `FMGetUnreadSectionsTool`, `FMReadSystemPromptTool`
- Arguments use `@Generable struct Arguments` with `@Guide(description:)` annotations
- Factory: `public func makeFoundationModelTools(sections:systemPrompt:tracker:) -> [any Tool]`
- Tool names use camelCase: `listSections`, `readSection`, `getUnreadSections`, `readSystemPrompt`

## Backend Implementations

### AppleIntelligenceBackend (Backends/AppleIntelligenceBackend.swift)
```swift
public struct AppleIntelligenceBackend: AgentInferenceBackend {
    public static var isAvailable: Bool  // wraps SystemLanguageModel.default.isAvailable
    public init()
    public func run(...) -> AsyncThrowingStream<AgentEvent, any Error>
}
```
- Uses `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` to avoid `sending` data race errors
- All helper methods are `private static` to avoid capturing `self` in the Task closure
- Creates `LanguageModelSession` with Foundation Model tools and concise instructions
- Uses `respond(to:)` (non-streaming) to avoid rate limiting
- Builds minimal user prompt: section names only, no XML spec (4,096 token context window)
- Tool calls extracted from `session.transcript` after `respond()` completes
- Section reads reported from `SectionReadTracker`
- Handles `LanguageModelSession.GenerationError` and `ToolCallError` with formatted messages

### OpenResponsesBackend (Backends/OpenResponsesBackend.swift)
```swift
public struct OpenResponsesBackend: AgentInferenceBackend {
    public init(config: CloudConnectionConfig,
                telemetry: any AgentBackendTelemetry = DisabledAgentTelemetry())
    public func run(...) -> AsyncThrowingStream<AgentEvent, any Error>
}
```
- `#if os(macOS)` guarded
- Uses `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` (same pattern as Apple Intelligence)
- All helper methods are `private static`
- Creates `LLMClient` and `ToolSession` with `makeAgentTools()` output
- Formats sections as XML via `XMLSpecFormatter` with double manifest listing
- Passes `ResponseConfigParameter` array: `RequestTimeout`, `ResourceTimeout`, `Instructions`, optional `Reasoning`
- Transforms `ToolSessionEvent` → `AgentEvent` in the stream loop
- Accumulates token usage across iterations via local counters
- Extracts `<think>...</think>` blocks during streaming via `extractCompletedThinkBlocks()`
- Handles `LLMError` with formatted messages
- Emits telemetry at every LLM interaction point via `any AgentBackendTelemetry` (pre-captured before `Task` as `let telemetry = self.telemetry`)
- Telemetry call points: `runBegan` (before stream loop), `iterationBegan/iterationEnded` (on `.iterationStarted`), `toolCallBegan/toolCallEnded` (on tool events), `tokenUsageUpdated` (on `.usageUpdate` — bind `let iteration` not `_`), `contentDeltaReceived` (in `processLLMEvent` on `.contentPartDelta`), `iterationEnded` + `runEnded` (after loop), `runFailed` (in catch blocks)
- `processLLMEvent` static function signature includes `telemetry: any AgentBackendTelemetry` parameter

### Concurrency Pattern for Backends
Both backends use the same pattern to avoid Swift 6 `sending` data race errors:
```swift
func run(...) -> AsyncThrowingStream<AgentEvent, any Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(of: AgentEvent.self)
    // Pre-compute Sendable values before Task
    Task { @MainActor in
        // All work here — calls static methods only, no self capture
    }
    return stream
}
```
- `makeStream()` avoids the closure-based initializer's `sending` parameter issues
- `@MainActor` Task avoids isolation boundary crossings
- Static methods avoid capturing `self` in the Task closure

## View Layer

### ActivityLogEntry (Views/ActivityLogView.swift)
```swift
struct ActivityLogEntry: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case status(String)
        case thinkingSummary(String)
        case thinkingBlock(String)
        case toolCallStarted(callId: String, name: String, arguments: String)
        case toolCallCompleted(callId: String, name: String, arguments: String, result: String, duration: Duration)
        case tokenUsage(String)
        case completed
        case failed(String)
    }
}
```
- `Identifiable` with `UUID` for stable SwiftUI diffing during rapid appends

### ActivityLogView (Views/ActivityLogView.swift)
- `#if os(macOS)` guarded
- `ScrollViewReader` + `LazyVStack` + `ForEach` over `[ActivityLogEntry]`
- Auto-scrolls to bottom via `.onChange(of: entries.count)`
- `ActivityLogRow` dispatches to specialized row views by `entry.kind`
- Row views: `StatusRow`, `ThinkingSummaryRow`, `ThinkingBlockRow` (expandable), `ToolCallInProgressRow` (spinner), `ToolCallCompletedRow` (expandable args/result/duration), `TokenUsageRow`, `CompletionRow`, `FailureRow`
- Tool call duration formatted as milliseconds
- Tool call result preview truncated at 400 characters

### ProjectAgentGenerationWindow (Views/ProjectAgentGenerationWindow.swift)
- `#if os(macOS)` guarded
- Receives data as init parameters: `projectName`, `projectSystemPrompt`, `projectLLMConnectionId`, `sections: [AgentSection]`, `modelContext: ModelContext`, `onContentGenerated`, `onLLMSelectionChanged`

**State variables:**
```swift
@State private var llmConnections: [LLMConnection] = []
@State private var selectedBackend: AgentBackend? = nil
@State private var instructions: String = ""
@State private var isRunning: Bool = false
@State private var generatedContent: String = ""
@State private var activityLog: [ActivityLogEntry] = []
@State private var errorMessage: String? = nil
@State private var showingError: Bool = false
@State private var tokenUsageSummary: String = ""
@State private var pendingToolArgs: [String: String] = [:]
@State private var sectionReadCounts: [String: Int] = [:]
@State private var toolCallCounts: [String: Int] = [:]
@State private var selectedReasoningEffort: ReasoningEffort? = .medium
@State private var activeTask: Task<Void, Never>?
@AppStorage("agentTelemetryEnabled") private var isTelemetryEnabled: Bool = false
```

**Key computed properties:**
- `configuredLLMConnections` — filters `llmConnections` by `isConfigured && endpointType == .responses`
- `localLLMConnections` — filters by `isLocalConnection()` (localhost, 127.0.0.1, 0.0.0.0, ::1)
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
```
Sources/AgentGen/
├── Models/
│   ├── AgentSection.swift
│   ├── AgentBackend.swift
│   ├── AgentEvent.swift              (AgentEvent, TokenUsageSnapshot, CloudConnectionConfig)
│   ├── AgentInferenceBackend.swift    (protocol)
│   ├── AgentBackendTelemetry.swift    (protocol + DisabledAgentTelemetry)
│   ├── AgentGenerationWindowState.swift
│   ├── SectionReadTracker.swift
│   ├── ProjectSpecTools.swift        (Open Responses tools)
│   └── FoundationModelTools.swift    (Apple Intelligence tools)
├── Backends/
│   ├── AppleIntelligenceBackend.swift
│   └── OpenResponsesBackend.swift
├── Telemetry/
│   └── OpenResponsesTelemetry.swift  (#if os(macOS), OSSignpost implementation)
├── Views/
│   ├── ProjectAgentGenerationWindow.swift
│   └── ActivityLogView.swift
└── Utilities/
    ├── XMLSpecFormatter.swift
    └── String+ThinkingBlocks.swift
```

---
**Last Updated:** 2026-03-25 (added AgentBackendTelemetry protocol, DisabledAgentTelemetry, OpenResponsesTelemetry; updated OpenResponsesBackend init to accept telemetry; documented telemetry call points in backend and toggle in view; added Telemetry/ directory to file structure)
