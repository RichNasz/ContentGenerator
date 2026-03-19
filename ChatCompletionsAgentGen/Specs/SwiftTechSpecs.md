# Swift Technical Specifications

## Purpose
Swift-specific implementation guidance for ChatCompletionsAgentGen. References CommonSpecs for shared patterns.

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
- No explicit `@MainActor` — default isolation applies

### SectionReadTracker (Models/SectionReadTracker.swift)
```swift
public actor SectionReadTracker {
    public init()
    func markRead(_ name: String)
    func unreadSections(from sections: [AgentSection]) -> [AgentSection]
}
```
- Plain `public actor` — no `@LLMTool` macro (it is infrastructure, not a tool)
- `public` access required because `makeAgentTools()` is `public` and takes it as a parameter
- `markRead` and `unreadSections` are `internal` — only called from within the package
- Freshly allocated per `runAgent()` call so prior session reads do not bleed into subsequent runs
- Actor isolation makes it safely `Sendable` for capture in `@Sendable` tool handler closures

### ProjectSpecTools (Models/ProjectSpecTools.swift)
- Four `@LLMTool`-decorated structs: `ListSectionsTool`, `ReadSectionTool`, `GetUnreadSectionsTool`, `ReadSystemPromptTool`
- `ReadSectionTool` holds `let tracker: SectionReadTracker`; calls `await tracker.markRead(section.name)` on the **matched section's actual name** (not `arguments.sectionName`) before returning, to handle any case discrepancy between the model's argument and the stored name
- `GetUnreadSectionsTool` holds `let sections: [AgentSection]` and `let tracker: SectionReadTracker`; returns JSON array of unread enabled section names, or `"[]"` when all have been read
- Factory: `public func makeAgentTools(sections: [AgentSection], systemPrompt: String?, tracker: SectionReadTracker) -> [AgentTool]`
- `NoArguments` and `ReadSectionArguments` decorated with `@LLMToolArguments`

### ProjectAgentGenerationWindow (Views/ProjectAgentGenerationWindow.swift)
- Wrapped in `#if os(macOS)`
- Receives data as init parameters (mirrors `ProjectContentGenerationWindow` pattern)
- Uses `ToolSession` (non-declarative init) with `makeAgentTools()` output
- **Iteration limit**: `maxIterations: (sections.filter(\.isEnabled).count * 2) + 5` — dynamically derived from enabled section count × 2 (accounts for alternating read/check pattern) plus overhead
- Log displayed post-completion via `result.log` (populated on the `.completed` event)
- **Instructions field initialization**: In the `.task` modifier, `instructions` always initializes to the generic task request string — never to `projectSystemPrompt`. The system prompt already appears in the LLM system message via `buildSystemPrompt()` as role/context; using it as the instructions default would place it in two semantically different roles at once.
- **Tracker lifecycle**: `let tracker = SectionReadTracker()` is created at the top of `runAgent()`, before `makeAgentTools()`. A fresh tracker per run ensures prior session reads do not bleed.
- **`buildSystemPrompt()` structure**: Lists four tools (including `get_unread_sections_tool`). Step 3 instructs the model to call `get_unread_sections_tool` and loop — reading any returned section names, then calling again — until it returns `[]`. Step 4 permits writing the final response only after `get_unread_sections_tool` returns `[]`.
- **Streaming execution**: Uses `session.stream(model:messages:configParams:)` returning `AsyncThrowingStream<ToolSessionEvent, Error>`. The `for try await event in stream` loop handles four event cases:
  - `.modelResponse(_, _, iteration)` → sets `liveStatus = "Thinking (iteration N)…"`
  - `.toolStarted(name, _)` → sets `activeToolName = name`, `liveStatus = "Calling \(name)…"`
  - `.toolCompleted(name, _, _)` → clears `activeToolName`, sets `liveStatus = "Tool \(name) finished. Waiting for model…"`
  - `.completed(result)` → clears `activeToolName`/`liveStatus`, populates `toolCallLog = result.log`, processes `result.response` for thinking blocks and final content; extracts `result.response.usage` → if non-nil, formats as `"Prompt: N | Completion: N | Total: N tokens"` → sets `tokenUsageSummary`; if nil, sets `tokenUsageSummary = "Token usage unavailable"`
- **Live state variables**: `@State private var liveStatus: String` and `@State private var activeToolName: String?` are reset to empty/nil at the top of `runAgent()` alongside the other reset properties. Both are also cleared in both `catch` blocks.
- **Token usage state**: `@State private var tokenUsageSummary: String = ""` — populated on `.completed` event from `result.response.usage`. Displayed as a `Text` view below the tool call log in Column 2, styled `.font(.caption)` `.foregroundStyle(.secondary)`. Only visible when non-empty (i.e., after agent completes). Reset to `""` at the top of `runAgent()`.
- **DSL gap — per-iteration usage**: `ToolSessionEvent.modelResponse` does not currently carry `ChatResponse.Usage`. When the DSL adds this, accumulate per-iteration totals in `@State private var cumulativeTokens: (prompt: Int, completion: Int, total: Int)` and update `liveStatus` to include the running token count.
- **`ToolCallLogEntry` constraint**: Has no public memberwise init — `activeToolName` is a separate `String?` state variable. The authoritative `toolCallLog: [ToolCallLogEntry]` is only populated from `result.log` on the `.completed` event; never constructed manually.
- **`contentDisplayState` computed property**: Returns `(text: String, isPlaceholder: Bool)`. Used inside the Column 3 `ScrollView` body via `let state = contentDisplayState`. This pattern is required because uninitialized `let` + conditional assignment inside a `@ViewBuilder` closure produces `Void` expressions that break the ViewBuilder — see ERR-COMPILE-003.
- **Timeout configuration**: Uses the `configParams:` overload (NOT the `@ChatConfigBuilder` trailing-closure overload) to pass `RequestTimeout` and `ResourceTimeout` derived from `llmConnection.requestTimeoutSeconds`. Clamping: `RequestTimeout` clamps to 10–900s, `ResourceTimeout` clamps to 30–3600s. The `[ChatConfigParameter]` array is pre-computed on MainActor before the `await` — see ERR-COMPILE-002.

### AgentToolCallLogView (Views/AgentToolCallLogView.swift)
- `struct AgentToolCallLogView: View` with `let entries: [ToolCallLogEntry]` and `var inProgressTool: String? = nil`
- When `entries.isEmpty && inProgressTool == nil`: shows "No tool calls yet." placeholder text
- Otherwise: `ScrollView` with `LazyVStack` of `AgentToolCallLogRow` entries followed (if `inProgressTool != nil`) by `AgentToolCallInProgressRow`
- `AgentToolCallInProgressRow` (private struct): shows `ProgressView` spinner + tool name + "running…" italic label; styled with `.regularMaterial` background matching completed rows

## Concurrency Patterns
- `runAgent()` uses `Task { }` — runs on MainActor by default
- Tool handlers are `@Sendable` closures; `SectionReadTracker` is an `actor` and therefore `Sendable`, so it can be safely captured alongside `[AgentSection]` without data-race risk
- `await tracker.markRead(...)` and `await tracker.unreadSections(...)` in tool `call()` methods are legal because `call(arguments:)` is `async throws`
- No GCD, no DispatchQueue

## Dependencies
- `SwiftChatCompletionsDSL`: `ToolSession`, `AgentTool`, `TextMessage`, `LLMClient`, `ToolCallLogEntry`, `ToolSessionEvent`
- `SwiftLLMToolMacros`: `@LLMTool`, `@LLMToolArguments`, `@LLMToolGuide`
- `LLMmanagement`: `LLMConnection`, `LLMClient`

---
**Last Updated:** 2026-03-18
