# Error Resolution Database

## Purpose and Scope
Living knowledge base for ChatCompletionsAgentGen — captures compilation errors, test failures, and runtime issues encountered during development.

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
- `ProjectAgentGenerationWindow.swift` is entirely wrapped in `#if os(macOS)`

---

## Compilation Errors

### ERR-SWIFTDATA-001: @Query Unavailable in Swift Package Context
- **Discovery Method**: Compilation (swift build)
- **Frequency**: 1 (2026-03-17)
- **Error Message**: `error: unknown attribute 'Query'`
- **Context**: Using `@Query(sort: \LLMConnection.name) private var llmConnections` in a SwiftUI view inside a Swift Package target
- **Root Cause**: `@Query` is a SwiftData property wrapper macro that requires SwiftData to be explicitly linked as a framework dependency. In Swift Package targets, system framework `@Query` expansion fails because the package linker does not automatically include the SwiftData macro plugin needed to expand `@Query` at compile time, even when `import SwiftData` is present and `@Model` types resolve correctly.
- **Proven Fix**: Follow the `LLMConnectionListView` pattern from `LLMmanagement`:
  1. Remove `@Query`
  2. Add `private let modelContext: ModelContext` as a stored property
  3. Add `modelContext: ModelContext` to the view's `init` parameters
  4. Use `@State private var llmConnections: [LLMConnection] = []`
  5. Load via `modelContext.fetch(FetchDescriptor<LLMConnection>(...))` in `.task`
  6. Pass `dataManager.createContext()` from the app's `WindowGroup`
- **Prevention Pattern**: NEVER use `@Query` in Swift Package view code. Always use the manual fetch pattern with a `ModelContext` parameter. The `@Query` property wrapper is only reliable in Xcode app targets, not SPM package targets.
- **Verification**: `swift build` succeeds with no errors or warnings
- **Related Errors**: None
- **Last Updated**: 2026-03-17

### ERR-COMPILE-001: ToolSession init — maxIterations must precede handlers
- **Discovery Method**: Compilation (xcodebuild)
- **Frequency**: 1 (2026-03-17)
- **Error Message**: `error: argument 'maxIterations' must precede argument 'handlers'`
- **Context**: Adding `maxIterations:` after `handlers:` in a `ToolSession` explicit init call
- **Root Cause**: The `ToolSession` non-declarative init signature is `init(client:tools:toolChoice:maxIterations:handlers:)` — `maxIterations` is the 4th parameter and must appear before `handlers` (5th parameter). Swift enforces argument label order strictly.
- **Proven Fix**: Reorder arguments to match the declared parameter order: `client:`, `tools:`, `maxIterations:`, `handlers:` (omitting `toolChoice:` if using its default `nil`).
- **Prevention Pattern**: When adding `maxIterations:` to an existing `ToolSession` init that only had `client:tools:handlers:`, insert it before `handlers:`, not after.
- **Verification**: `xcodebuild` BUILD SUCCEEDED with no errors
- **Related Errors**: None
- **Last Updated**: 2026-03-17

### ERR-COMPILE-002: MainActor-Isolated @ChatConfigBuilder Closure Cannot Be Sent to Nonisolated ToolSession.run()
- **Discovery Method**: Compilation (xcodebuild)
- **Frequency**: 1 (2026-03-17)
- **Error Message**: `error: sending value of non-Sendable type '() throws -> [any ChatConfigParameter]' risks causing data races` / `note: sending main actor-isolated value of non-Sendable type … to nonisolated instance method 'run(model:messages:config:)' risks causing races`
- **Context**: Calling `session.run(model:messages:config:)` with a trailing `@ChatConfigBuilder` closure from a MainActor-isolated context (`runAgent()` inside `ProjectAgentGenerationWindow`)
- **Root Cause**: The `@ChatConfigBuilder config` parameter of `ToolSession.run(model:messages:config:)` is a closure type `() throws -> [any ChatConfigParameter]` which is not `Sendable`. Swift 6 strict concurrency prevents sending a MainActor-isolated closure to a `nonisolated` async method.
- **Proven Fix**: Use the `configParams:` overload (`run(model:messages:configParams:)`) instead. Pre-compute the `[ChatConfigParameter]` array on the MainActor before the `await` call, then pass the Sendable array directly:
```swift
let configParams: [ChatConfigParameter] = [
    try RequestTimeout(validRequestTimeout),
    try ResourceTimeout(validResourceTimeout),
]
let result = try await session.run(
    model: llmConnection.selectedModel,
    messages: [...],
    configParams: configParams
)
```
- **Code Before**:
```swift
let result = try await session.run(
    model: llmConnection.selectedModel,
    messages: [...]
) {
    try RequestTimeout(validRequestTimeout)
    try ResourceTimeout(validResourceTimeout)
}
```
- **Code After**:
```swift
let configParams: [ChatConfigParameter] = [
    try RequestTimeout(validRequestTimeout),
    try ResourceTimeout(validResourceTimeout),
]
let result = try await session.run(
    model: llmConnection.selectedModel,
    messages: [...],
    configParams: configParams
)
```
- **Prevention Pattern**: When passing `ChatConfigParameter` values to `ToolSession.run()` from a MainActor-isolated view, always use the `configParams:` overload with a pre-computed array. Never use the `@ChatConfigBuilder` trailing closure overload from MainActor-isolated code.
- **Verification**: `xcodebuild` BUILD SUCCEEDED with no errors
- **Related Errors**: ERR-COMPILE-001
- **Last Updated**: 2026-03-17

### ERR-COMPILE-003: Uninitialized `let` + Conditional Assignment Inside @ViewBuilder Produces `Void`
- **Discovery Method**: Compilation (xcodebuild)
- **Frequency**: 1 (2026-03-17)
- **Error Message**: `error: type '()' cannot conform to 'View'` / `note: only concrete types such as structs, enums and classes can conform to protocols` / `note: required by static method 'buildExpression' where 'Content' = '()'`
- **Context**: Using the Swift two-phase pattern (declare uninitialized `let`, then assign inside `if/else`) inside a `ScrollView {}` or other `@ViewBuilder` closure to compute local display values
- **Root Cause**: A `@ViewBuilder` closure collects each statement as a potential `View`-conforming value via `buildExpression`. An assignment statement (`variable = value`) returns `Void` (`()`), which the compiler attempts to pass to `buildExpression`. Since `()` does not conform to `View`, the build fails.
- **Proven Fix**: Extract the conditional logic to a computed property on the view struct that returns a plain tuple (or struct). Call it with `let state = myComputedProperty` (initialized `let`) inside the ViewBuilder — a `let` with an initializer expression is legal in ViewBuilder contexts.
- **Code Before**:
```swift
ScrollView {
    let displayText: String      // uninitialized — triggers the bug
    let isPlaceholder: Bool
    if condition {
        displayText = "A"        // assignment → Void → build failure
        isPlaceholder = true
    } else {
        displayText = "B"
        isPlaceholder = false
    }
    Text(displayText)
        .foregroundStyle(isPlaceholder ? .secondary : .primary)
}
```
- **Code After**:
```swift
// Computed property on the view struct (outside any ViewBuilder):
private var contentDisplayState: (text: String, isPlaceholder: Bool) {
    if condition { return ("A", true) }
    return ("B", false)
}

// Inside the ViewBuilder — initialized let is legal:
ScrollView {
    let state = contentDisplayState
    Text(state.text)
        .foregroundStyle(state.isPlaceholder ? .secondary : .primary)
}
```
- **Prevention Pattern**: NEVER use uninitialized `let` + conditional assignment inside any `@ViewBuilder` closure (`body`, `ScrollView {}`, `VStack {}`, etc.). Always pre-compute conditional display values in a computed property or by using a ternary expression, then bind with an initialized `let`.
- **Verification**: `xcodebuild` BUILD SUCCEEDED with no errors
- **Related Errors**: None
- **Last Updated**: 2026-03-17

### ERR-COMPILE-004: Actor Used as Public Function Parameter Must Be Public
- **Discovery Method**: Compilation (xcodebuild)
- **Frequency**: 1 (2026-03-17)
- **Error Message**: `error: function cannot be declared public because its parameter uses an internal type`
- **Context**: Adding a new `actor SectionReadTracker` (default `internal` access) as a parameter to the `public func makeAgentTools(...)` factory function
- **Root Cause**: Swift enforces that all parameter types of a `public` function must themselves be at least `public`. An `actor` with default `internal` access cannot appear in a `public` function signature, even if the actor is only used as infrastructure inside the package.
- **Proven Fix**: Declare the actor `public actor SectionReadTracker` and add a `public init()` (required because the synthesized memberwise init of an actor is `internal` by default — callers outside the module need `public init()` to instantiate it).
- **Prevention Pattern**: When introducing any new type that will be passed to or returned from a `public` function, immediately declare it `public`. For actors, also add an explicit `public init()`.
- **Verification**: `xcodebuild` BUILD SUCCEEDED with no errors or warnings
- **Related Errors**: None
- **Last Updated**: 2026-03-17

---

## Runtime Errors

*New runtime issues will be documented here as they are encountered and resolved.*

---

**Last Updated:** 2026-03-17 (added ERR-COMPILE-004: actor used as public function parameter must be public)
**Swift Version:** 6.2 with Default MainActor Isolation
**Package:** ChatCompletionsAgentGen
