# Lessons Learned - ContentGenerator

## SwiftUI Layout Issues

### WindowGroup with HSplitView and Nested ScrollViews - Layout Timing Issue

**Date**: December 8, 2024
**Component**: SectionContentGenerationWindow (LLM Assistant Window)
**Issue**: Vertical ScrollViews not properly extending to fill available height on initial window open

#### Symptom
When the LLM content assistant window first opened, the vertical ScrollViews in both the input panel and preview panel did not extend to the bottom of the content area. The content appeared clipped or cut off, with scrollable areas stopping short of where they should reach. However, after clicking the "Generate Content" button and receiving results, the layout would suddenly render perfectly with proper ScrollView heights.

#### Root Cause
**Multiple factors combined to create this layout timing issue:**

1. **Missing Explicit Height Constraints on Nested ScrollViews**
   - The `inputSection` and `previewSection` both contained ScrollViews nested within an HSplitView
   - Without explicit `.frame(maxHeight: .infinity)` constraints, SwiftUI's layout engine couldn't properly calculate the available height during initial render
   - The HSplitView itself had `.frame(maxWidth: .infinity, maxHeight: .infinity)`, but child views didn't propagate this constraint

2. **Conditional Rendering in WindowGroup**
   - The WindowGroup used conditional rendering: `if contentGenerationWindowState.isWindowRequested { ... } else { EmptyView() }`
   - This introduced an extra view hierarchy transition that delayed proper layout calculation
   - SwiftUI had to render EmptyView first, then switch to the actual window content

3. **Why Generate Content Button "Fixed" the Layout**
   - When content was generated, the preview section underwent a **complete view structure change**:
     - From: `ContentUnavailableView` (when empty)
     - To: `ScrollView` with actual content
   - This view reconstruction forced SwiftUI to completely rebuild that branch of the view hierarchy
   - The reconstruction triggered a full layout recalculation of the HSplitView, using proper dimensions
   - This is more thorough than incremental layout updates during initial render

#### The Fix

**Three changes were required:**

1. **Add explicit height constraint to inputSection's ScrollView**
   ```swift
   private var inputSection: some View {
       ScrollView {
           VStack(alignment: .leading, spacing: 16) {
               // ... content
           }
           .padding()
       }
       .frame(maxHeight: .infinity)  // ← CRITICAL: Tell SwiftUI to fill available height
   }
   ```

2. **Add explicit height constraint to previewSection's outer VStack**
   ```swift
   private var previewSection: some View {
       VStack(alignment: .leading, spacing: 16) {
           Text("Generated Content")
               .font(.headline)

           if generatedContent.isEmpty {
               ContentUnavailableView(...)
           } else {
               ScrollView { ... }
                   .frame(maxWidth: .infinity, maxHeight: .infinity)
           }
       }
       .padding()
       .frame(maxHeight: .infinity)  // ← CRITICAL: Ensure consistent height regardless of content state
   }
   ```

3. **Remove conditional rendering from WindowGroup**
   ```swift
   // BEFORE (problematic):
   WindowGroup(id: "content-generation") {
       if contentGenerationWindowState.isWindowRequested {
           SectionContentGenerationWindow(...)
       } else {
           EmptyView()
       }
   }

   // AFTER (fixed):
   WindowGroup(id: "content-generation") {
       SectionContentGenerationWindow(...)
   }
   ```

#### Best Practices Learned

1. **Always add explicit height constraints to ScrollViews nested in HSplitView**
   - Use `.frame(maxHeight: .infinity)` to tell SwiftUI to fill available vertical space
   - Don't rely on implicit sizing - SwiftUI's layout engine needs explicit hints for nested flexible containers

2. **Match constraint patterns between parent and child views**
   - If HSplitView has `.frame(maxWidth: .infinity, maxHeight: .infinity)`, its children should too
   - Consistent constraint patterns help SwiftUI's layout algorithm work correctly

3. **Avoid conditional view switching in WindowGroup content when possible**
   - WindowGroup should render the actual content directly, not conditionally
   - Use window opening/closing (via `openWindow(id:)` and `dismissWindow(id:)`) to control visibility
   - Conditional rendering adds unnecessary view hierarchy transitions

4. **Use `.frame(maxHeight: .infinity)` vs `.frame(height: .infinity)`**
   - `maxHeight` allows views to shrink below infinity if needed (e.g., when window is resized smaller)
   - `height` would force a fixed infinite height, preventing proper resizing
   - `maxHeight` creates flexible, responsive layouts

5. **Understanding SwiftUI Layout Passes**
   - Initial layout pass may use conservative/default sizes without explicit constraints
   - State changes can trigger more thorough layout recalculation
   - View reconstruction (from one view type to another) forces complete re-layout
   - Don't rely on state changes to "fix" layouts - get the constraints right from the start

#### Related Code Locations

- **Fixed file**: `ContentGenerator/ContentGeneration/Views/SectionContentGenerationWindow.swift`
  - Line 271: Added `.frame(maxHeight: .infinity)` to inputSection
  - Line 301: Added `.frame(maxHeight: .infinity)` to previewSection

- **Fixed file**: `ContentGenerator/App/ContentGeneratorApp.swift`
  - Lines 43-58: Removed conditional rendering from WindowGroup

#### When to Apply This Pattern

Apply explicit `.frame(maxHeight: .infinity)` constraints when:
- ScrollViews are nested inside HSplitView or VSplitView
- Views are nested inside flexible containers (GeometryReader, etc.)
- Layout doesn't properly fill available space on initial render
- Layout "fixes itself" after a state change or user interaction
- Views have conditional rendering that changes their structure

#### Testing Checklist for Similar Issues

When implementing windows with split views and scroll views, verify:
- [ ] Window opens with proper layout on first render (don't rely on state changes to fix it)
- [ ] ScrollViews extend to fill available space in their containers
- [ ] No clipping or cut-off content on initial render
- [ ] Layout remains correct when window is resized
- [ ] No layout flickering or jumping during state changes
- [ ] Both empty state and content state render with proper sizing

---

## AppKit/SwiftUI Integration Issues

### NSTextView in NSViewRepresentable - NSRangeException Crashes

**Date**: January 12, 2026
**Component**: SpellCheckingTextEditor (NSViewRepresentable wrapping NSTextView)
**Issue**: App crashes with NSRangeException when editing text, especially with word completion or rich text paste

#### Symptom
The app crashes with errors like:
```
NSRangeException: *** -[NSBigMutableString substringWithRange:]: Range {1313, 18446744073709551612} out of bounds; string length 2263
```

The second value (18446744073709551612) is near `UInt64.max`, indicating `NSNotFound` being used as a range length. Also accompanied by:
```
NSHostingView is being laid out reentrantly while rendering its SwiftUI content
```

#### Root Cause
**Multiple factors combined to create these crashes:**

1. **Automatic Text Completion Conflicts**
   - `isAutomaticTextCompletionEnabled` (word completion popup) triggers callbacks during SwiftUI layout passes
   - When word completion queries text ranges, it can receive invalid range information
   - The completion system's internal state becomes corrupted when text changes during its operation

2. **Improper Text System Initialization**
   - Creating NSScrollView and NSTextView manually doesn't properly set up NSTextStorage, NSLayoutManager, and NSTextContainer relationships
   - Using `NSTextView.scrollableTextView()` ensures proper text system initialization

3. **Rich Text Paste Causing Mixed Fonts**
   - Pasting content from AI chatbots with different fonts/sizes introduces mixed font attributes
   - HIServices (macOS text services) crashes when querying ranges in text with inconsistent attributes
   - Even with `isRichText = false`, some paste operations bypass this setting

4. **SwiftUI/AppKit Reentrancy**
   - Synchronous binding updates during `textDidChange` can trigger SwiftUI layout during an existing layout pass
   - This creates reentrancy that corrupts the text system's internal state

#### The Fix

**Four changes were required:**

1. **Use `NSTextView.scrollableTextView()` for proper initialization**
   ```swift
   func makeNSView(context: Context) -> NSScrollView {
       // Use scrollableTextView() for proper text system setup
       let scrollView = NSTextView.scrollableTextView()
       guard let textView = scrollView.documentView as? NSTextView else {
           return scrollView
       }
       // Configure textView...
   }
   ```

2. **Disable automatic text completion**
   ```swift
   // CRITICAL: Disable automatic text completion to prevent crashes
   textView.isAutomaticTextCompletionEnabled = false

   // Spell checking still works (red underlines, right-click suggestions)
   textView.isContinuousSpellCheckingEnabled = true
   textView.isGrammarCheckingEnabled = true
   ```

3. **Intercept paste to ensure plain text**
   ```swift
   // In Coordinator
   func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
       if commandSelector == #selector(NSText.paste(_:)) {
           textView.pasteAsPlainText(nil)
           return true
       }
       return false
   }
   ```

4. **Defer binding updates to avoid reentrancy**
   ```swift
   func textDidChange(_ notification: Notification) {
       guard !isUpdating else { return }
       guard let textView = notification.object as? NSTextView else { return }

       let newText = textView.string
       guard newText != parent.text else { return }

       // Defer binding update to next run loop to avoid reentrancy
       DispatchQueue.main.async { [weak self] in
           guard let self = self else { return }
           guard !self.isUpdating else { return }
           if self.textView?.string == newText {
               self.parent.text = newText
           }
       }
   }
   ```

#### Best Practices Learned

1. **Always use `NSTextView.scrollableTextView()` instead of manual setup**
   - This method properly initializes NSTextStorage, NSLayoutManager, and NSTextContainer
   - Manual setup can leave the text system in an inconsistent state

2. **Disable `isAutomaticTextCompletionEnabled` for NSViewRepresentable wrappers**
   - Word completion triggers callbacks that conflict with SwiftUI's layout system
   - Spell checking (red underlines) and right-click suggestions still work without it

3. **Use delegate method for paste interception instead of subclassing**
   - `textView(_:doCommandBy:)` cleanly intercepts paste commands
   - Avoids complexity of custom NSTextView subclass overrides

4. **Always defer binding updates with `DispatchQueue.main.async`**
   - Prevents reentrancy when NSTextView changes trigger SwiftUI layout
   - Verify text view state before applying deferred update

5. **Track update state with `isUpdating` flag**
   - Prevents feedback loops between SwiftUI binding updates and `textDidChange`
   - Essential for bidirectional text synchronization

#### Related Code Locations

- **Fixed file**: `ContentGenerator/ContentGeneration/Views/SpellCheckingTextEditor.swift`
  - Line 35: `isAutomaticTextCompletionEnabled = false`
  - Line 20: `NSTextView.scrollableTextView()` for proper initialization
  - Lines 117-123: `textView(_:doCommandBy:)` for paste interception
  - Lines 98-114: Deferred binding update pattern

#### When to Apply This Pattern

Apply these fixes when:
- Wrapping NSTextView in NSViewRepresentable
- Experiencing NSRangeException crashes during text editing
- Seeing "NSHostingView is being laid out reentrantly" warnings
- Users paste rich text and the app crashes
- Word completion popup appears and causes crashes

#### Testing Checklist

- [ ] Type rapidly in text editor - no crashes
- [ ] Paste rich text from AI chatbot - pastes as plain text, no crash
- [ ] Misspelled words show red underlines (spell check works)
- [ ] Right-click on misspelled word shows suggestions
- [ ] No "reentrantly" warnings in console during editing
- [ ] Word completion popup does NOT appear (intentionally disabled)

---

## SwiftUI Drag and Drop

### Transferable API vs onDrag/onDrop - Reliability Issues

**Date**: January 15, 2026
**Component**: ProjectDetailView (Specification Section Reordering)
**Issue**: Modern `draggable`/`dropDestination` APIs with custom `Transferable` types fail silently

#### Symptom
When implementing drag-and-drop reordering for specification sections using Swift's modern `Transferable` protocol with `draggable()` and `dropDestination()` modifiers:
- Dragging appeared to work (item became draggable with preview)
- Drop was never accepted - the `dropDestination` closure never fired
- Dragged item remained dimmed (opacity 0.5) after mouse release
- No errors or warnings in console

#### Root Cause
**Multiple factors combined to create this failure:**

1. **Transferable/Codable Serialization Issues**
   - The `SpecificationSectionData` struct conformed to `Transferable` with `CodableRepresentation`
   - Custom `UTType` was declared with `UTType(exportedAs:)`
   - Without proper Info.plist registration, the system may not recognize the custom UTType
   - The deserialized object may have a different UUID than the original (if `init` regenerates it)

2. **Swift 6 Concurrency Isolation**
   - Static `UTType` properties are main-actor isolated by default in Swift 6
   - Accessing them from `Transferable.transferRepresentation` (nonisolated context) causes errors
   - Required `nonisolated` keyword on the UTType extension property

3. **dropDestination Not Firing**
   - Even when serialization appeared to work, `dropDestination(for:)` never received the data
   - The exact cause is unclear - possibly related to UTType registration or Transferable implementation details

#### The Fix

**Switch to the older, more reliable `onDrag`/`onDrop` APIs:**

```swift
// Track which section is being dragged
@State private var draggingSectionId: UUID?

// In ForEach for sections:
ExpandableSpecificationSection(...)
    .opacity(draggingSectionId == section.id ? 0.5 : 1.0)
    .onDrag {
        draggingSectionId = section.id
        return NSItemProvider(object: section.id.uuidString as NSString)
    }
    .onDrop(of: [.text], isTargeted: nil) { providers in
        guard let dragId = draggingSectionId,
              let sourceIndex = specificationSections.firstIndex(where: { $0.id == dragId }) else {
            draggingSectionId = nil
            return false
        }
        let destinationIndex = index
        draggingSectionId = nil

        guard sourceIndex != destinationIndex else { return true }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            moveSection(from: sourceIndex, to: destinationIndex)
        }
        return true
    }

// On parent container - clear drag state if dropped outside sections:
VStack(spacing: 12) {
    ForEach(...) { ... }
}
.onDrop(of: [.text], isTargeted: nil) { _ in
    draggingSectionId = nil
    return false
}
```

#### Why This Approach Works

1. **Simple data transfer** - Only passes a UUID string, not a complex serialized object
2. **Local state tracking** - Uses `draggingSectionId` state to track source, not deserialized data
3. **Built-in UTType** - Uses `.text` which is always registered and recognized
4. **No Transferable conformance needed** - Avoids all serialization/deserialization issues

#### Best Practices Learned

1. **Prefer `onDrag`/`onDrop` over `draggable`/`dropDestination` for internal reordering**
   - The older APIs are more reliable for same-view drag-and-drop
   - Custom `Transferable` types add complexity without benefit for internal operations
   - Use local state to track drag source rather than relying on serialization

2. **Use simple data types for drag payloads**
   - Pass identifiers (UUID string) instead of full objects
   - Look up the actual object from your data source using the identifier
   - Avoids serialization issues and UUID regeneration problems

3. **Track drag state locally**
   - Store `draggingSectionId` in `@State` when drag starts
   - Use this for visual feedback (opacity) and source identification
   - Clear state in all drop handlers (success and failure paths)

4. **Add container-level drop handler**
   - Catches drops that miss specific targets
   - Ensures drag state is cleared even on cancelled/failed drops
   - Return `false` to indicate drop wasn't fully handled

5. **Swift 6 UTType extensions need `nonisolated`**
   ```swift
   extension UTType {
       nonisolated static var customType: UTType {
           UTType(exportedAs: "com.app.custom-type")
       }
   }
   ```

#### When to Use Each API

**Use `onDrag`/`onDrop` when:**
- Reordering items within the same view/list
- Drag-and-drop is internal to your app
- You control both drag source and drop target
- Simplicity and reliability are priorities

**Use `draggable`/`dropDestination` when:**
- Inter-app drag-and-drop is required
- You need to export data to other apps (Finder, etc.)
- The UTType is properly registered in Info.plist
- You've thoroughly tested the Transferable implementation

#### Related Code Locations

- **Modified file**: `ContentGenerator/ContentGeneration/Views/ProjectDetailView.swift`
  - Lines 178-198: `onDrag`/`onDrop` implementation
  - Line 54: `@State private var draggingSectionId: UUID?`
  - Lines 206-210: Container-level drop handler

- **Modified file**: `ContentGenerator/ContentGeneration/Views/ExpandableSpecificationSection.swift`
  - Lines 24, 119-144, 157-160: Hover-only move buttons with `.onHover`

- **Modified file**: `ContentGenerator/ContentGeneration/Views/SpecificationBuilder.swift`
  - Lines 178-206: `Transferable` conformance (kept for reference, not used)
  - Lines 211-215: `nonisolated` UTType extension

#### Testing Checklist

- [ ] Drag section by header - visual feedback (dimming) appears
- [ ] Drop on another section - sections swap positions
- [ ] Drop outside sections - dimming clears, no position change
- [ ] Cancel drag (press Escape) - dimming clears
- [ ] Hover over section header - move up/down buttons appear
- [ ] Click move buttons - sections reorder correctly
- [ ] Order persists after save
- [ ] Single section - no move buttons shown, drag still works but no reorder
