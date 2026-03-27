# Error Resolution Database

## Purpose and Scope

This specification defines a **living knowledge base** that captures compilation errors, test failures, and runtime issues encountered during AI code generation, along with their proven fixes. This system enables instant error resolution, enforces consistency across the codebase, and creates a self-improving AI development environment.

**Critical Requirement**: Every error encountered must be documented with its proven solution to prevent re-solving the same problems and ensure consistent fixes throughout the codebase.

**Swift 6 + Default MainActor Context**: This project uses Swift 6 with default actor isolation set to MainActor, which changes common error patterns compared to manual @MainActor annotation projects.

## Quick Reference Index

- [🔥 High-Frequency Errors](#high-frequency-errors)
- [⚡ Compilation Errors](#compilation-errors)
- [🗄️ SwiftData Errors](#swiftdata-errors)
- [🎨 SwiftUI Errors](#swiftui-errors)
  - [Navigation Errors](#navigation-errors)
- [🧪 Test Failure Errors](#test-failure-errors)
- [💥 Runtime Errors](#runtime-errors)
- [🔍 Search Guidelines](#search-guidelines)

## Error Entry Template

### Error ID: ERR-[CATEGORY]-[NUMBER]
- **Discovery Method**: [Compilation | Unit Test | Integration Test | Runtime]
- **Frequency**: [Count of occurrences - updated each time encountered]
- **Error Message**: [Exact error text from compiler/test/runtime]
- **Test Case**: [Specific test that revealed error, if applicable]
- **Context**: [When/where this occurs - file types, operations, patterns]
- **Root Cause**: [Technical explanation of why this happens]
- **Proven Fix**: [Step-by-step resolution that has been verified]
- **Code Before**: [Example of error-causing code]
- **Code After**: [Example of fixed code]
- **Prevention Pattern**: [How to avoid this error in future code generation]
- **Verification**: [How to confirm the fix works]
- **Related Errors**: [Links to similar error IDs]
- **Last Updated**: [Date of most recent update]

---

## High-Frequency Errors

*Most commonly encountered errors across the codebase*

### Known Patterns from Swift 6 + Default MainActor Projects

**Note**: These are pre-loaded patterns adapted from proven BlogGenerator solutions, modified for Swift 6 + Default MainActor environment.

### ERR-SWIFT-001: Unnecessary @MainActor Annotation
- **Discovery Method**: Compilation
- **Frequency**: 0 (Prevention pattern)
- **Error Message**: `@MainActor annotation is redundant with default actor isolation`
- **Context**: Classes that don't need explicit @MainActor with default isolation
- **Root Cause**: Default MainActor isolation makes explicit annotation redundant
- **Proven Fix**: Remove explicit @MainActor annotation
- **Code Before**:
```swift
@MainActor  // Redundant with default isolation
@Observable
final class ProjectListViewModel {
    // UI operations
}
```
- **Code After**:
```swift
@Observable  // MainActor by default
final class ProjectListViewModel {
    // UI operations automatically isolated
}
```
- **Prevention Pattern**: Only add @MainActor when overriding default isolation
- **Verification**: Compilation succeeds, UI updates work without warnings

### ERR-SWIFT-002: Missing nonisolated for Background Classes
- **Discovery Method**: Compilation
- **Frequency**: 0 (Prevention pattern)
- **Error Message**: `Expression is 'async' but is not marked with 'await'` or actor isolation conflicts
- **Context**: Background processing classes that should not be MainActor isolated
- **Root Cause**: Default MainActor isolation applies to classes that should run in background
- **Proven Fix**: Add `nonisolated` annotation to background classes
- **Code Before**:
```swift
final class DataProcessor {  // Incorrectly MainActor isolated by default
    func processData() async {
        // Background work causes isolation conflicts
    }
}
```
- **Code After**:
```swift
nonisolated final class DataProcessor {
    func processData() async {
        // Background work properly isolated
    }
}
```
- **Prevention Pattern**: Mark background processing classes as `nonisolated`
- **Verification**: Background operations complete without actor conflicts

### ERR-DATA-001: SwiftData @Relationship Syntax Error
- **Discovery Method**: Compilation
- **Frequency**: 0 (Prevention pattern)
- **Error Message**: `Cannot find type in scope` or `Invalid relationship syntax`
- **Context**: @Relationship definitions in @Model classes
- **Root Cause**: Incorrect relationship syntax or missing inverse relationships
- **Proven Fix**: Use proper @Relationship syntax with deleteRule and inverse
- **Code Before**:
```swift
@Relationship var specification: ContentSpecification?
```
- **Code After**:
```swift
@Relationship(deleteRule: .cascade, inverse: \ContentSpecification.project)
var specification: ContentSpecification?
```
- **Prevention Pattern**: Always specify deleteRule and inverse for @Relationship properties
- **Verification**: SwiftData model compiles and relationships work in runtime

### ERR-SWIFT-003: @Model Class Not Final
- **Discovery Method**: Compilation
- **Frequency**: 0 (Prevention pattern)
- **Error Message**: `@Model class 'ClassName' must be final`
- **Context**: SwiftData @Model class declarations
- **Root Cause**: SwiftData requires @Model classes to be final for optimization
- **Proven Fix**: Add `final` keyword to @Model class declarations
- **Code Before**:
```swift
@Model
class ContentProject {
    // ...
}
```
- **Code After**:
```swift
@Model
final class ContentProject {
    // ...
}
```
- **Prevention Pattern**: Always declare @Model classes as final
- **Verification**: SwiftData model compiles without warnings

## Compilation Errors

*Compilation-time errors and their solutions*

### ERR-COMPILE-005: Ambiguous type names when importing two DSL modules simultaneously

- **Discovery Method**: Compilation
- **Frequency**: 1 (2026-03-27)
- **Error Message**: `Ambiguous use of 'init(_:)'` or `Ambiguous use of 'init(baseURL:apiKey:sessionConfiguration:)'`
- **Context**: `SectionContentGenerationWindow.swift` and `ProjectContentGenerationWindow.swift` after adding `import SwiftOpenResponsesDSL` alongside the existing `import SwiftChatCompletionsDSL`. Both DSLs define identically named types: `LLMClient`, `LLMError`, `Temperature`, `RequestTimeout`, `ResourceTimeout`.
- **Root Cause**: Swift resolves unqualified type names by searching all imported modules. When two modules export the same type name, the compiler cannot choose and emits `Ambiguous use of`. Even inside a result builder closure (e.g., `ChatRequest { ... }`), the builder's expected element type is not enough to disambiguate a plain `Temperature(0.7)` call if the same name exists in another module.
- **Proven Fix**: Qualify every reference to a type that exists in both modules:
  - `SwiftChatCompletionsDSL.LLMClient(...)` in the `.chatCompletions` Task
  - `SwiftOpenResponsesDSL.LLMClient(...)` in the `.responses` Task
  - `SwiftChatCompletionsDSL.Temperature(...)`, `SwiftChatCompletionsDSL.RequestTimeout(...)`, `SwiftChatCompletionsDSL.ResourceTimeout(...)` inside `ChatRequest { }` builder
  - `catch let error as SwiftChatCompletionsDSL.LLMError` and `catch let error as SwiftOpenResponsesDSL.LLMError`
  - Overload `formatLLMError` with two typed parameters instead of a single unqualified `LLMError` parameter
- **Prevention Pattern**: Whenever a file imports two modules that share type names, always qualify those names with their module prefix. `[any ResponseConfigParameter]` annotation on the config params array is sufficient to disambiguate `RequestTimeout`/`ResourceTimeout` in the `.responses` case (since that protocol is unique to `SwiftOpenResponsesDSL`), but explicit qualification in the `.chatCompletions` builder is still required.
- **Files Affected**: `ContentGenerator/ContentGeneration/Views/SectionContentGenerationWindow.swift`, `ContentGenerator/ContentGeneration/Views/ProjectContentGenerationWindow.swift`
- **Last Updated**: 2026-03-27

## SwiftData Errors

*SwiftData-specific errors and patterns*

## SwiftUI Errors

*SwiftUI-specific errors and patterns*

### Navigation Errors

### ERR-UI-001: NavigationSplitView Navigation Not Working
- **Discovery Method**: Runtime / User Testing
- **Frequency**: 2 (2025-12-08)
- **Error Message**: Project selection stops working after navigating to settings via NavigationLink, OR detail view not populating when sidebar items selected
- **Context**:
  - Variant A: Mixed Button-based navigation (for projects) with NavigationLink-based navigation (for settings) in NavigationSplitView sidebar
  - Variant B: Using .navigationDestination(for:) modifier with NavigationSplitView (wrong API)
- **Root Cause**:
  - **Variant A**: When NavigationLink is activated, it pushes a new destination into SwiftUI's navigation state. Button-based selection uses manual `@State` that is not coordinated with NavigationLink. After NavigationLink takes over the detail area, Button's manual state becomes disconnected, and subsequent Button taps don't restore navigation context because they bypass NavigationLink system.
  - **Variant B**: `.navigationDestination(for:)` is the API for `NavigationStack`, not `NavigationSplitView`. When used with `NavigationSplitView`, it doesn't control what appears in the detail pane. The detail pane must switch on the List's selection binding directly.
- **Proven Fix**: Use the correct NavigationSplitView pattern with:
  1. NavigationDestination enum for type safety
  2. @State var selectedDestination for selection tracking
  3. List(selection: $selectedDestination) binding
  4. NavigationLink(value:) for all sidebar items
  5. Detail section switches on selectedDestination
  6. NO .navigationDestination(for:) modifier
- **Code Before**:
```swift
// BROKEN: Mixed navigation patterns
struct ContentView: View {
    @State private var selectedProject: ContentProject?  // Manual state

    var body: some View {
        NavigationSplitView {
            List {
                ForEach(projects) { project in
                    Button {  // Button-based navigation
                        selectedProject = project
                    } label: {
                        Text(project.name)
                    }
                }

                NavigationLink("LLM Connections") {  // NavigationLink breaks Button navigation
                    LLMConnectionListView()
                }
            }
        } detail: {
            if let project = selectedProject {
                ProjectDetailView(project: project)
            }
        }
    }
}
```
- **Code After**:
```swift
// FIXED: Correct NavigationSplitView pattern
enum NavigationDestination: Hashable {
    case project(ContentProject)
    case llmConnections
}

struct ContentView: View {
    // Selection state for NavigationSplitView
    @State private var selectedDestination: NavigationDestination?

    var body: some View {
        NavigationSplitView {
            // List with selection binding
            List(selection: $selectedDestination) {
                ForEach(projects) { project in
                    NavigationLink(value: NavigationDestination.project(project)) {
                        Text(project.name)
                    }
                }

                NavigationLink("LLM Connections", value: NavigationDestination.llmConnections)
            }
        } detail: {
            // Detail switches on selection
            if let destination = selectedDestination {
                switch destination {
                case .project(let project):
                    ProjectDetailView(project: project)
                case .llmConnections:
                    LLMConnectionListView()
                }
            } else {
                ContentUnavailableView("No Selection")
            }
        }
        // NO .navigationDestination modifier - that's for NavigationStack!
    }
}
```
- **Prevention Pattern**:
  - ALWAYS use value-based NavigationLink for all NavigationSplitView sidebar items
  - NEVER mix Button-based and NavigationLink-based navigation
  - Define NavigationDestination enum for type-safe routing
  - Use List(selection: $selectedDestination) binding in sidebar
  - Make detail section switch on selectedDestination with if-let/switch
  - NEVER use .navigationDestination(for:) with NavigationSplitView (that's for NavigationStack)
  - Declare @State var selectedDestination in the view containing NavigationSplitView
- **Verification**:
  - Can navigate from projects to settings and back freely
  - All navigation items work consistently
  - No selection state corruption
- **Related Errors**: None
- **Last Updated**: 2025-12-08
- **Architecture Mandate**: See SwiftTechSpecs.md "CRITICAL: NavigationSplitView Pattern Requirements"

### ERR-UI-002: GeometryReader Prevents Content From Filling Sheet
- **Discovery Method**: Runtime / User Testing
- **Frequency**: 1 (2026-01-15)
- **Error Message**: No error - visual bug where content doesn't fill the sheet/modal window
- **Context**: Using GeometryReader inside a sheet to calculate sizing (e.g., 80% of window), resulting in significant empty space around the content
- **Root Cause**: GeometryReader proposes size to its children based on calculations, but when nested inside a sheet with its own frame constraints, it creates double-sizing issues. The GeometryReader sizes its content to a percentage of available space, but the sheet's frame constraints are already controlling the size, causing the content to be undersized relative to the actual sheet dimensions.
- **Proven Fix**: Remove GeometryReader from sheet content. Let the sheet's frame modifiers control sizing, and use `.frame(maxWidth: .infinity, maxHeight: .infinity)` on content to fill the sheet.
- **Code Before**:
```swift
// BROKEN: GeometryReader causes content to not fill sheet
.sheet(isPresented: $isExpanded) {
    GeometryReader { geometry in
        NavigationStack {
            VStack(spacing: 0) {
                SpellCheckingTextEditor(text: $text)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(
            width: max(500, geometry.size.width * 0.8),
            height: max(400, geometry.size.height * 0.8)
        )
    }
    .frame(minWidth: 600, idealWidth: 800, minHeight: 500, idealHeight: 600)
}
```
- **Code After**:
```swift
// FIXED: Sheet frame controls size, content fills it
.sheet(isPresented: $isExpanded) {
    NavigationStack {
        SpellCheckingTextEditor(text: $text)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
    .frame(minWidth: 600, idealWidth: 800, minHeight: 500, idealHeight: 600)
}
```
- **Prevention Pattern**:
  - NEVER use GeometryReader inside sheets/popovers to calculate percentage-based sizing
  - Use the sheet's `.frame()` modifier to control overall size
  - Use `.frame(maxWidth: .infinity, maxHeight: .infinity)` on content to fill available space
  - If percentage sizing is truly needed, calculate it in the parent view before presenting the sheet
- **Verification**:
  - Content fills the entire sheet with appropriate padding
  - No unexplained empty space to the right, bottom, or above footer
- **Related Errors**: None
- **Last Updated**: 2026-01-15

## Test Failure Errors

*Unit test and UI test failures*

## Runtime Errors

*Runtime issues and crashes*

### ERR-RUNTIME-001: NSRangeException in NSTextView with SwiftUI
- **Discovery Method**: Runtime
- **Frequency**: 7+ (2026-02-27)
- **Error Message**: `NSRangeException: *** -[NSBigMutableString substringWithRange:]: Range {X, 18446744073709551612} out of bounds; string length Y`
- **Context**: NSTextView wrapped in NSViewRepresentable for spell checking, crashes during text editing, word completion, rich text paste, or editing in expanded editor sheet
- **Root Cause**: Multiple issues combine:
  1. `isAutomaticTextCompletionEnabled` triggers callbacks during SwiftUI layout passes
  2. Manual NSScrollView/NSTextView setup doesn't properly initialize text system components
  3. Rich text paste introduces mixed fonts that corrupt HIServices range calculations
  4. Synchronous binding updates cause SwiftUI reentrancy
  5. `updateNSView` using `textView.string = text` routes through the text input system (`shouldChangeTextInRanges:` → undo coalescing → `_undoRedoAttributedSubstringFromRange:`). When the spell checker's `NSCorrectionPanel` enters a nested run loop and a SwiftUI layout pass triggers `updateNSView`, the undo system reads stale ranges held by the spell checker, producing an integer-underflowed length
  6. Using `textView.string.count` (Swift `Character` count) instead of `(textView.string as NSString).length` (UTF-16 code unit count) for `NSRange` calculations produces incorrect offsets for text containing emoji, accented characters, or other multi-code-unit sequences
  7. `undoManager?.disableUndoRegistration()` is **insufficient** — it prevents the undo manager from *registering* operations, but `NSTextViewSharedData.coalesceInTextView:` still creates `NSUndoTyping` objects that read from text storage using stale ranges *before* reaching the undo manager registration step. The crash occurs inside `NSUndoTyping init` (via `_undoRedoAttributedSubstringFromRange:`), not during registration
  8. When the spell checker has active marked text (inline prediction), `storage.endEditing()` triggers `synchronizeTextLayoutManagers` → `_fixSelectionAfterChangeInCharacterRange:` → `_NSClearMarkedRange` → `insertText:replacementRange:` → `shouldChangeTextInRanges:` → `coalesceInTextView:` → crash
- **Proven Fix**:
  1. Use `NSTextView.scrollableTextView()` for proper text system initialization
  2. Set `isAutomaticTextCompletionEnabled = false` (CRITICAL)
  3. Intercept paste via `textView(_:doCommandBy:)` to force plain text
  4. Defer binding updates with `Task { @MainActor [weak self] in }` (Swift 6 native concurrency — avoids GCD/actor boundary crossing under strict concurrency checking)
  5. In `updateNSView`, use `textStorage` directly with `beginEditing`/`endEditing`; set `textView.allowsUndo = false` before editing and restore to `true` after (CRITICAL — `disableUndoRegistration()` is NOT sufficient because `NSUndoTyping` is created before registration)
  6. Use `(textView.string as NSString).length` instead of `textView.string.count` for all `NSRange` calculations
  7. Guard `updateNSView` with `textView.hasMarkedText()` — if marked text is active, defer the update via the coordinator's retry mechanism instead of editing text storage (CRITICAL — prevents `_NSClearMarkedRange` crash path entirely)
- **Code Before**:
```swift
// BROKEN: Manual setup with word completion enabled
func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSScrollView()
    let textView = NSTextView()  // Manual creation
    textView.isContinuousSpellCheckingEnabled = true
    // isAutomaticTextCompletionEnabled defaults to true - CRASH!
    scrollView.documentView = textView
    return scrollView
}

// BROKEN: updateNSView goes through text input system
func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else { return }
    if textView.string != text {
        textView.string = text  // Routes through shouldChangeText → undo → CRASH!
        let length = textView.string.count  // Wrong! Swift Character count ≠ UTF-16 length
        textView.setSelectedRange(NSRange(location: length, length: 0))
    }
}

// STILL BROKEN: disableUndoRegistration doesn't prevent NSUndoTyping creation
func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else { return }
    if textView.string != text {
        let storage = textView.textStorage!
        textView.undoManager?.disableUndoRegistration()  // NOT ENOUGH!
        storage.beginEditing()
        storage.replaceCharacters(in: NSRange(location: 0, length: storage.length), with: text)
        storage.endEditing()  // Still crashes when hasMarkedText() is true
        textView.undoManager?.enableUndoRegistration()
    }
}

func textDidChange(_ notification: Notification) {
    parent.text = textView.string  // Synchronous - causes reentrancy
}
```
- **Code After**:
```swift
// FIXED: Proper initialization with completion disabled
func makeNSView(context: Context) -> NSScrollView {
    let scrollView = NSTextView.scrollableTextView()  // Proper setup
    guard let textView = scrollView.documentView as? NSTextView else {
        return scrollView
    }
    textView.isContinuousSpellCheckingEnabled = true
    textView.isAutomaticTextCompletionEnabled = false  // CRITICAL
    textView.delegate = context.coordinator
    return scrollView
}

// FIXED: Guard against hasMarkedText + use allowsUndo = false
func updateNSView(_ scrollView: NSScrollView, context: Context) {
    guard let textView = scrollView.documentView as? NSTextView else { return }
    guard !context.coordinator.isUpdating else { return }

    // CRITICAL: Skip update if spell checker has active marked text
    if textView.hasMarkedText() {
        context.coordinator.scheduleDeferredTextUpdate(text)
        return
    }

    if textView.string != text {
        context.coordinator.performDirectUpdate(text, on: textView)
    }
}

// Coordinator method: direct update with allowsUndo = false
func performDirectUpdate(_ text: String, on textView: NSTextView) {
    isUpdating = true
    let storage = textView.textStorage!
    textView.allowsUndo = false  // Prevents NSUndoTyping creation entirely
    storage.beginEditing()
    let attributes = textView.typingAttributes
    storage.replaceCharacters(
        in: NSRange(location: 0, length: storage.length),
        with: NSAttributedString(string: text, attributes: attributes)
    )
    storage.endEditing()
    textView.allowsUndo = true

    // UTF-16 length for correct NSRange
    let utf16Length = (textView.string as NSString).length
    textView.setSelectedRange(NSRange(location: utf16Length, length: 0))
    isUpdating = false
}

// Coordinator method: deferred retry when hasMarkedText() is true
func scheduleDeferredTextUpdate(_ text: String) {
    pendingText = text
    retryCount = 0
    attemptDeferredUpdate()
}

private func attemptDeferredUpdate() {
    guard let text = pendingText, let textView = textView else {
        pendingText = nil; retryCount = 0; return
    }
    if !textView.hasMarkedText() {
        pendingText = nil; retryCount = 0
        if textView.string != text { performDirectUpdate(text, on: textView) }
        return
    }
    retryCount += 1
    if retryCount > maxRetries { pendingText = nil; retryCount = 0; return }
    Task { @MainActor [weak self] in
        try? await Task.sleep(for: .milliseconds(50))
        self?.attemptDeferredUpdate()
    }
}

// Intercept paste for plain text
func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
    if commandSelector == #selector(NSText.paste(_:)) {
        textView.pasteAsPlainText(nil)
        return true
    }
    return false
}

func textDidChange(_ notification: Notification) {
    let newText = textView.string
    // Defer to avoid reentrancy
    Task { @MainActor [weak self] in
        self?.parent.text = newText
    }
}
```
- **Prevention Pattern**:
  - ALWAYS use `NSTextView.scrollableTextView()` for proper text system setup
  - ALWAYS disable `isAutomaticTextCompletionEnabled` when wrapping NSTextView in SwiftUI
  - ALWAYS defer binding updates with `Task { @MainActor [weak self] in }` — do NOT use `DispatchQueue.main.async` in actor-isolated contexts (produces concurrency warnings under strict checking; crosses GCD/actor boundary)
  - ALWAYS intercept paste to force plain text in plain text editors
  - NEVER use `textView.string = text` in `updateNSView` — use `textStorage` directly with `beginEditing`/`endEditing` to bypass the text input system and undo coalescing
  - ALWAYS use `textView.allowsUndo = false` (not `disableUndoRegistration()`) when doing programmatic text storage edits — `disableUndoRegistration` does not prevent `NSUndoTyping` creation, only its registration
  - ALWAYS check `textView.hasMarkedText()` before editing text storage in `updateNSView` — if marked text is active, defer the update with a retry mechanism to avoid triggering `_NSClearMarkedRange`
  - ALWAYS disable undo registration (`undoManager?.disableUndoRegistration()`) during programmatic text updates in `updateNSView`
  - ALWAYS use `NSAttributedString(string: text, attributes: textView.typingAttributes)` when replacing text in `NSTextStorage` — plain `String` replacement loses font attributes, causing inconsistent font/size after programmatic updates
  - NEVER use `textView.string.count` for `NSRange` calculations — always use `(textView.string as NSString).length` for correct UTF-16 offsets
- **Verification**:
  - Rapid typing doesn't crash
  - Pasting rich text from AI chatbots works without crash
  - Spell check red underlines still appear
  - Right-click suggestions still work
  - No "reentrantly" console warnings
  - Editing in expanded editor sheet doesn't crash when spell checker shows corrections
  - Text with emoji or accented characters doesn't produce invalid cursor positions
  - Font remains consistent after programmatic text replacement (content generation, expand/collapse sheet)
- **Related Errors**: None
- **Last Updated**: 2026-03-03

## Search Guidelines

### How to Use This Database
1. **Before Code Generation**: Review relevant category for similar patterns
2. **During Errors**: Search for exact error messages or similar symptoms
3. **After Resolution**: Add new error patterns with complete solution details
4. **Regular Maintenance**: Update frequency counts and improve solutions

### Search Patterns
- **By Error Message**: Search for exact compiler error text
- **By Context**: Look for similar implementation scenarios
- **By Category**: Browse relevant sections (SwiftData, SwiftUI, etc.)
- **By Frequency**: Start with high-frequency errors for common patterns

---

**Last Updated**: 2026-03-27
**Swift Version**: 6.2+ with Default MainActor Isolation
**Project**: ContentGenerator