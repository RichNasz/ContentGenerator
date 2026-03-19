# Swift Technical Specifications

## Purpose
Swift-specific implementation guidance for OpenResponsesAgentGen. References CommonSpecs for shared patterns.

**Swift 6 + Default MainActor Context**: This package is consumed by ContentGenerator, which uses Swift 6 with default actor isolation set to MainActor.

## Architecture Patterns

### Architecture Foundation
This package follows patterns defined in the CommonSpecs:
- **Swift 6 Concurrency**: See [SwiftCodeGeneration.md](../../../CommonSpecs/SwiftCodeGeneration.md)
- **SwiftUI State Management**: See [SwiftUIWithoutMVVM.md](../../../CommonSpecs/SwiftUIWithoutMVVM.md)

## Key Types

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

    public func openAgentWindow(projectName:systemPrompt:llmConnectionId:sections:onContentGenerated:onLLMSelectionChanged:)
    public func reset()
}
```
- No explicit `@MainActor` -- default isolation applies
- Window ID: `"project-agent-generation-responses"`

### SectionReadTracker (Models/SectionReadTracker.swift)
```swift
public actor SectionReadTracker {
    public init()
    func markRead(_ name: String)
    func unreadSections(from sections: [AgentSection]) -> [AgentSection]
}
```
- Freshly allocated per `runAgent()` call so prior session reads do not bleed into subsequent runs
- Actor isolation makes it safely `Sendable` for capture in `@Sendable` tool handler closures

### ProjectSpecTools (Models/ProjectSpecTools.swift)
- Four `@LLMTool`-decorated structs: `ListSectionsTool`, `ReadSectionTool`, `GetUnreadSectionsTool`, `ReadSystemPromptTool`
- Factory: `public func makeAgentTools(sections: [AgentSection], systemPrompt: String?, tracker: SectionReadTracker) -> [AgentTool]`
- `AgentTool` from `SwiftOpenResponsesDSL` wraps `FunctionToolParam` + handler

### ProjectAgentGenerationWindow (Views/ProjectAgentGenerationWindow.swift)
- Wrapped in `#if os(macOS)`
- Receives data as init parameters (mirrors `ProjectContentGenerationWindow` pattern)
- Uses `ToolSession` (non-declarative init) with `makeAgentTools()` output
- **Iteration limit**: `maxIterations: (sections.filter(\.isEnabled).count * 2) + 5` — dynamically derived from enabled section count × 2 (accounts for alternating read/check pattern) plus overhead
- **Streaming execution**: Uses `session.stream(model:input:configParams:)` returning `AsyncThrowingStream<ToolSessionEvent, Error>`
- **Event handling**: `for try await event in stream` loop processes:
  - `.iterationStarted(Int)` → updates `liveStatus` with iteration number
  - `.toolCallStarted(callId:name:arguments:)` → sets `activeToolName`, caches arguments in `pendingToolArgs`
  - `.toolCallCompleted(callId:name:output:duration:)` → clears `activeToolName`, builds `LocalToolCallLogEntry`, appends to `toolCallLog`
  - `.llm(.contentPartDelta(delta:_:_:))` → appends delta text to `generatedContent` for live streaming
  - `.llm(.responseCompleted(response))` → no longer used for usage extraction (handled by `.usageUpdate`)
  - `.usageUpdate(usage, iteration)` → accumulates `cumulativeInput` / `cumulativeOutput`, appends to `iterationUsages` array, updates `tokenUsageSummary` and `liveStatus` with running totals
- **Live status state**: `@State private var liveStatus: String` and `@State private var activeToolName: String?` provide real-time UI feedback; `@State private var pendingToolArgs: [String: String]` caches arguments from `toolCallStarted` for use in `toolCallCompleted`
- **Section read count tracking**: `@State private var sectionReadCounts: [String: Int]` tracks per-section read counts for Column 1 badges. Incremented in the `.toolCallCompleted` handler when `name == "read_section_tool"` by parsing the `section_name` key from the JSON arguments string via `JSONSerialization`. Reset to `[:]` at the start of each `runAgent()` call.
- **Post-stream processing**: Thinking block extraction via `extractingThinkingBlocks()` runs after the stream finishes (when full text is accumulated), not during streaming
- **Input items**: Uses `System(buildSystemPrompt())` and `User(userMessage)` convenience functions returning `InputItem`
- **Token usage**: Cumulative tracking via local `cumulativeInput`, `cumulativeOutput` (Int accumulators) and `iterationUsages: [(iteration: Int, usage: ResponseObject.Usage)]` array, accumulated from `.usageUpdate` events. Final summary format: `"Input: N | Output: N | Total: N tokens (M iterations)"`
- **Tracker lifecycle**: `let tracker = SectionReadTracker()` is created at the top of `runAgent()`, before `makeAgentTools()`. A fresh tracker per run ensures prior session reads do not bleed.
- **Timeout configuration**: Uses the `configParams:` overload to pass `RequestTimeout` and `ResourceTimeout` derived from `llmConnection.requestTimeoutSeconds`. Pre-computed array on MainActor before the `await`.

### LocalToolCallLogEntry (Views/AgentToolCallLogView.swift)
- Local struct with `name`, `arguments`, `result`, `duration` fields — mirrors `SwiftOpenResponsesDSL.ToolCallLogEntry` but has a public init (the upstream type's synthesized memberwise init is `internal`)
- Built from `.toolCallStarted` + `.toolCallCompleted` stream events

### AgentToolCallLogView (Views/AgentToolCallLogView.swift)
- `struct AgentToolCallLogView: View` with `let entries: [LocalToolCallLogEntry]` and `var inProgressTool: String? = nil`
- `inProgressTool` is set to `activeToolName` during streaming to show a spinner row for the currently executing tool

## Concurrency Patterns
- `runAgent()` uses `Task { }` -- runs on MainActor by default
- Tool handlers are `@Sendable` closures; `SectionReadTracker` is an `actor` and therefore `Sendable`
- No GCD, no DispatchQueue

## Dependencies
- `SwiftOpenResponsesDSL`: `ToolSession`, `ToolSessionEvent`, `StreamEvent`, `AgentTool`, `FunctionToolParam`, `InputItem`, `LLMClient`, `ResponseObject`, `ResponseConfigParameter`
- `SwiftLLMToolMacros`: `@LLMTool`, `@LLMToolArguments`, `@LLMToolGuide`
- `LLMmanagement`: `LLMConnection`, `LLMClient`

## Key API Differences from ChatCompletionsAgentGen
| ChatCompletionsDSL | OpenResponsesDSL | Notes |
|---|---|---|
| `TextMessage(role:content:)` | `System()`, `User()` free functions -> `[InputItem]` | Convenience functions return `InputItem` |
| `ChatResponse` | `ResponseObject` | |
| `result.response.firstContent` | `result.response.firstOutputText` | Property name differs |
| `ChatResponse.Usage` (.promptTokens, .completionTokens) | `ResponseObject.Usage` (.inputTokens, .outputTokens) | Field names differ |
| `ChatConfigParameter` | `ResponseConfigParameter` | Same pattern, different protocol name |
| `session.stream(model:messages:configParams:)` | `session.stream(model:input:configParams:)` | Both return `AsyncThrowingStream<ToolSessionEvent, Error>` |
| `ToolSessionStreamEvent` (`.modelResponse`, `.toolStarted`, `.toolCompleted`, `.completed`) | `ToolSessionEvent` (`.iterationStarted`, `.toolCallStarted`, `.toolCallCompleted`, `.llm(StreamEvent)`) | Different event shapes; Responses wraps raw `StreamEvent` in `.llm()`, no `.completed` case |

---
**Last Updated:** 2026-03-19
