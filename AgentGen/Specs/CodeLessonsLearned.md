# Error Resolution Database

## Purpose and Scope
Living knowledge base for AgentGen — captures compilation errors, test failures, and runtime issues encountered during development.

**Swift 6 + Default MainActor Context**: This package is consumed by ContentGenerator which uses default MainActor isolation.

## Quick Reference Index
- [High-Frequency Errors](#high-frequency-errors)
- [Compilation Errors](#compilation-errors)
- [Runtime Errors](#runtime-errors)

---

## High-Frequency Errors

### Known Patterns (Pre-loaded from ContentGenerator)

**ERR-SWIFT-001: Unnecessary @MainActor on @Observable class**
- Do NOT add `@MainActor` to `AgentGenerationWindowState` — default isolation applies
- See ContentGenerator/Specs/CodeLessonsLearned.md ERR-SWIFT-001

**ERR-MACOS-001: NSColor / NSSavePanel / NSPasteboard in cross-platform package**
- Views using macOS AppKit APIs must be wrapped in `#if os(macOS) ... #endif`
- `ProjectAgentGenerationWindow.swift`, `ActivityLogView.swift`, and `OpenResponsesBackend.swift` are all wrapped in `#if os(macOS)`

**ERR-SWIFTDATA-001: @Query Unavailable in Swift Package Context**
- NEVER use `@Query` in Swift Package view code. Always use manual fetch pattern with `ModelContext` parameter.

---

## Compilation Errors

### ERR-COMPILE-001: ToolCallLogEntry memberwise init is internal [HISTORICAL]

- **Error ID:** ERR-COMPILE-001
- **Status:** Historical — `LocalToolCallLogEntry` no longer exists. Tool call data is now carried inline by `ActivityLogEntry.Kind.toolCallCompleted(callId:name:arguments:result:duration:)`.
- **Original Issue:** `SwiftOpenResponsesDSL.ToolCallLogEntry` has an internal memberwise init. When streaming, the consumer must build entries manually.
- **Current Resolution:** The `ActivityLogEntry` model carries tool call data directly in its enum cases, eliminating the need for a separate log entry struct.

### ERR-COMPILE-002: Reasoning summary streaming events silently dropped by DSL default break

- **Error ID:** ERR-COMPILE-002
- **Category:** SWIFT
- **Severity:** Build-breaking (functional gap)
- **Context:** Models emitting `response.reasoning_summary_part.added` and `response.reasoning_summary_part.done` SSE events had reasoning silently dropped by `default: break` in `SwiftOpenResponsesDSL.parseStreamEvent()`
- **Root Cause:** The DSL's `StreamEvent` enum did not include cases for reasoning summary part events
- **Proven Fix:** Added `reasoningSummaryPartAdded` and `reasoningSummaryPartDone` cases to `StreamEvent` enum and `parseStreamEvent`. Handled in `OpenResponsesBackend.processLLMEvent()` — no-op for `.added`, yield `.thinkingSummary` on `.done`.
- **Prevention:** When integrating a new API provider, review the full OpenAPI spec for event types not covered by the DSL.
- **Last Updated:** 2026-03-18

### ERR-COMPILE-003: AsyncThrowingStream sending parameter data race errors

- **Error ID:** ERR-COMPILE-003
- **Category:** CONCURRENCY
- **Severity:** Build-breaking
- **Frequency:** High — affects all backend implementations
- **Context:** Backend `run()` methods returning `AsyncThrowingStream<AgentEvent>` with closure-based initializer + `Task { }` inside
- **Error Message:** `Passing closure as a 'sending' parameter risks causing data races between code in the current task and concurrent execution of the closure`
- **Root Cause:** With default MainActor isolation, function parameters and `self` are MainActor-isolated. The `Task` closure captures these across an isolation boundary. The `AsyncThrowingStream` closure-based initializer's build closure is `@Sendable`, creating a second boundary. Even `Sendable` types trigger this when captured from MainActor-isolated context.
- **Proven Fix:** Three-part solution:
  1. Use `AsyncThrowingStream.makeStream(of: AgentEvent.self)` instead of closure-based initializer — returns `(stream, continuation)` tuple, avoiding the `@Sendable` closure
  2. Use `Task { @MainActor in }` — keeps the Task on MainActor, eliminating isolation boundary
  3. Make all helper methods called from the Task `private static` — avoids capturing `self`
- **Code Pattern:**
```swift
func run(...) -> AsyncThrowingStream<AgentEvent, any Error> {
    let (stream, continuation) = AsyncThrowingStream.makeStream(of: AgentEvent.self)
    Task { @MainActor in
        // call Self.staticMethod() only — no self capture
    }
    return stream
}
```
- **Prevention:** Always use `makeStream()` + `@MainActor Task` + static methods for backend implementations. Never use the closure-based `AsyncThrowingStream { continuation in Task { } }` pattern.
- **Files Affected:** `Backends/AppleIntelligenceBackend.swift`, `Backends/OpenResponsesBackend.swift`
- **Last Updated:** 2026-03-24

### ERR-COMPILE-004: 'Sendable' class cannot inherit from another class other than 'NSObject'

- **Error ID:** ERR-COMPILE-004
- **Category:** CONCURRENCY
- **Severity:** Build-breaking
- **Frequency:** Encountered when subclassing any NSObject subclass (e.g., URLProtocol) under Swift 6 default MainActor isolation
- **Context:** Creating a `final class` subclass of `URLProtocol` (which itself subclasses `NSObject`) for HTTP request interception
- **Error Message:** `'Sendable' class 'AgentRequestLoggingURLProtocol' cannot inherit from another class other than 'NSObject'`
- **Root Cause:** Swift 6 with default MainActor isolation implicitly infers `Sendable` on `final` classes. The Swift compiler enforces that `Sendable` classes may only directly inherit from `NSObject` — not from intermediate subclasses of `NSObject` like `URLProtocol`. The compile-time check cannot be satisfied by reorganizing the inheritance hierarchy, since `URLProtocol` is a required superclass.
- **Proven Fix:** Add `@unchecked Sendable` to the class declaration to suppress the automatic conformance check:
  ```swift
  final class AgentRequestLoggingURLProtocol: URLProtocol, URLSessionDataDelegate, @unchecked Sendable {
  ```
  This is semantically safe when the class has no cross-thread mutable state. `URLProtocol` instances are called from the URL loading system on its own queue; the `forwardingSession` delegate callbacks arrive on the delegate queue; neither crosses actor boundaries in a way that would cause data races.
- **Prevention:** When subclassing any `NSObject` subclass (not `NSObject` directly) in a Swift 6 codebase with default MainActor isolation, expect this error. Always add `@unchecked Sendable` and verify that stored mutable state does not escape across thread/actor boundaries.
- **Files Affected:** `Telemetry/AgentRequestLoggingURLProtocol.swift`
- **Last Updated:** 2026-03-25

---

## Runtime Errors

### ERR-RUNTIME-001: Apple Intelligence fails on repeat runs

- **Error ID:** ERR-RUNTIME-001
- **Category:** RUNTIME
- **Severity:** Major — second and subsequent runs return empty or fail
- **Frequency:** Consistent on repeat runs without fix
- **Context:** Running Apple Intelligence agent multiple times consecutively
- **Root Cause:** Three compounding issues:
  1. **Context window overflow**: Full XML spec was sent in prompts, exceeding the 4,096 token limit on repeat runs
  2. **Rate limiting from streaming**: `streamResponse()` triggered rate limiting on the on-device model
  3. **No task cancellation**: Previous tasks were not cancelled before starting new runs
- **Proven Fix:**
  1. Concise prompts with section names only (no XML spec) — model uses tools to discover content
  2. Use `respond()` (non-streaming) instead of `streamResponse()` to avoid rate limiting
  3. Add `activeTask?.cancel()` before starting new runs
- **Prevention:** For on-device models with limited context windows, always use tool-first approaches where the model discovers content incrementally rather than receiving it upfront. Always cancel previous tasks before starting new inference.
- **Files Affected:** `Backends/AppleIntelligenceBackend.swift`, `Views/ProjectAgentGenerationWindow.swift`
- **Last Updated:** 2026-03-24

---

**Last Updated:** 2026-03-25
**Swift Version:** 6.2 with Default MainActor Isolation
**Package:** AgentGen
