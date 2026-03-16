# SwiftUI Implementation Specification

## Purpose and Scope

This specification defines comprehensive requirements and best practices for implementing user interfaces using SwiftUI in iOS applications. It covers framework usage, Human Interface Guidelines compliance, performance optimization, accessibility, and type safety.

**Target Audience:**
- AI code generators implementing SwiftUI interfaces
- iOS developers working with SwiftUI
- UI/UX designers implementing design systems
- Quality assurance teams validating UI implementations

## Relationship to Other Specifications

This specification focuses on **SwiftUI implementation details** for iOS applications. For information about other aspects of Swift development, refer to:

- **SwiftUIWithoutMVVM.md**: Modern SwiftUI state management patterns eliminating the need for traditional ViewModels (**HOW** to structure SwiftUI code)

- **Functional Specification**: The project's functional specification covering core purpose, features, and requirements (**WHAT** the project does)

- **SwiftCodeGeneration.md**: Swift-specific implementation guidance providing language features, ecosystem integration patterns, and Swift best practices for implementing algorithms (**HOW** to implement in Swift) - includes MainActor concurrency patterns that apply to SwiftUI implementations

- **SwiftTestingSpec.md**: Comprehensive testing patterns, requirements, and Swift Testing framework guidance for validating SwiftUI implementations (**HOW** to test SwiftUI code)

- **Lessons Learned Documentation**: Historical development insights and lessons learned from previous Swift projects, providing supplementary context and best practices (supplementary reference material)

- **SpecificationQualitySpec.md**: Evaluation criteria and methodology for assessing specification quality, ensuring consistent quality assessment across all project documentation (evaluation framework)

- **DocumentationSpec.md**: Documentation requirements and standards for the project

The functional specification defines the project scope and capabilities (**WHAT**), the Swift code generation guide provides Swift-specific implementation patterns (**HOW** in Swift), the SwiftUI-without-MVVM specification provides modern state management patterns (**HOW** to structure SwiftUI code), this SwiftUI specification provides comprehensive UI implementation standards (**HOW** to implement SwiftUI interfaces), the lessons learned document provides historical context and development insights, the specification quality evaluation provides assessment criteria, and the documentation specification defines how those capabilities should be documented (**HOW** to document).

## SwiftUI Implementation Standards

### Framework Requirements
- **SwiftUI Only**: All user interfaces must use SwiftUI, not UIKit or other UI frameworks
- **Platform Compatibility**: iOS 26.0+, macOS 26.0+, watchOS 11.0+, tvOS 18.0+
- **macOS 26 Glass UI**: Leverage new glass material system for depth and visual hierarchy
- **Cross-Platform Considerations**: Design with potential iPad support and glass material adaptation

### Architecture Patterns
- **SwiftUI-Native State Management**: Leverage SwiftUI's built-in state primitives (@State, @StateObject, @EnvironmentObject) for business logic without traditional ViewModels
- **View Composition**: Build complex UIs through composition of smaller, reusable views
- **State Management**: Use @State, @Binding, and @Published for reactive state handling
- **Business Logic in Views**: Implement business logic directly in views using computed properties and private methods
- **View Decomposition**: Break down large, complicated view bodies into smaller, manageable private functions marked with @ViewBuilder
- **Type Safety**: Avoid AnyView which erases type information and harms performance; use Group, @ViewBuilder, or conditional logic instead
- **Declarative Programming**: SwiftUI is declarative - describe desired UI state, not imperative steps. Avoid UIKit-style imperative logic.

## Human Interface Guidelines Compliance

### Layout and Spacing
- **Consistent Spacing**: Use standard spacing values (8pt grid system)
- **Edge Insets**: Apply appropriate padding using EdgeInsets
- **Safe Areas**: Respect device safe areas and notches
- **Dynamic Layout**: Support different screen sizes and orientations
- **Dynamic View Sizing**: Use containerRelativeFrame for responsive modal presentations with content-aware sizing

### Typography and Content
- **Dynamic Type**: Support all Dynamic Type sizes from .extraSmall to .accessibilityExtraExtraExtraLarge
- **Semantic Colors**: Use system colors and semantic color schemes
- **Accessibility**: Implement proper contrast ratios and readable text sizes
- **Content Hierarchy**: Use appropriate font weights and sizes for information hierarchy

### Interaction Patterns
- **Standard Controls**: Use SwiftUI's built-in controls (Button, TextField, Toggle, etc.)
- **Gestures**: Implement appropriate gesture recognizers following HIG patterns
- **Navigation**: Follow modern navigation patterns detailed in the Navigation section below
- **Feedback**: Provide appropriate haptic and visual feedback

### Component Design
- **Standard Components**: Prefer system-provided components over custom implementations
- **Custom Components**: When creating custom components, ensure they follow HIG principles
- **Consistency**: Maintain visual consistency across all screens and components
- **Platform Adaptation**: Design for iOS platform conventions

## macOS 26 Glass UI Implementation

### Glass Material System

**New in macOS 26**: SwiftUI provides advanced glass material effects that create depth, translucency, and visual hierarchy through sophisticated material layering.

#### Core Glass Materials

```swift
// Primary glass materials for different UI contexts
.background(.glass)                    // Standard glass effect
.background(.glass.thick)              // Prominent glass with stronger blur
.background(.glass.thin)               // Subtle glass with light blur
.background(.glass.ultraThin)          // Minimal glass for overlays

// Contextual glass materials
.background(.glass.sidebar)            // Optimized for sidebar content
.background(.glass.toolbar)            // Designed for toolbar backgrounds
.background(.glass.popover)            // Specialized for popovers and menus
.background(.glass.window)             // Full window glass backgrounds
```

#### Glass Material Usage Patterns

```swift
// ✅ CORRECT: Layered glass hierarchy for depth
struct SettingsView: View {
    var body: some View {
        NavigationSplitView {
            // Sidebar with subtle glass
            settingsSidebar
                .background(.glass.sidebar)
        } detail: {
            // Detail content with standard glass
            settingsDetail
                .background(.glass)
        }
        // Window-level glass backdrop
        .background(.glass.window)
    }
}

// ✅ CORRECT: Glass overlays for temporary content
struct OverlayView: View {
    var body: some View {
        content
            .overlay {
                if showingPopover {
                    popoverContent
                        .background(.glass.popover)
                        .cornerRadius(12)
                        .shadow(.glass)
                }
            }
    }
}

// ❌ INCORRECT: Overusing glass materials
struct BadExample: View {
    var body: some View {
        VStack {
            // Too many competing glass layers
            section1.background(.glass.thick)
            section2.background(.glass)
            section3.background(.glass.thin)
        }
        .background(.glass.ultraThin) // Creates visual noise
    }
}
```

### Glass Visual Effects

#### Shadow and Glow Integration

```swift
// Glass-aware shadow system
.shadow(.glass)                        // Automatic glass-appropriate shadow
.shadow(.glass.elevated)               // Enhanced shadow for raised elements
.shadow(.glass.floating)               // Dramatic shadow for floating elements

// Custom glass shadows
.shadow(.glass(color: .primary, radius: 8, x: 0, y: 4))

// Glass glow effects for interactive elements
.glowEffect(.glass)                    // Subtle glow on hover/focus
.glowEffect(.glass.interactive)        // Enhanced glow for buttons
.glowEffect(.glass.accent)             // Accent-colored glow
```

#### Blur and Transparency Control

```swift
// Fine-tuned blur control
.blur(.glass(intensity: 0.7))          // Custom glass blur intensity
.blur(.glass.adaptive)                 // Adapts to content behind

// Transparency modulation
.opacity(.glass)                       // Glass-appropriate opacity
.opacity(.glass.interactive)           // Changes on interaction

// Content-aware transparency
.background(.glass.adaptive(for: backgroundContent))
```

### Interactive Glass Effects

#### Hover and Focus States

```swift
// Glass interaction patterns
struct GlassButton: View {
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            buttonContent
        }
        .background(.glass.interactive)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .glowEffect(.glass.interactive, isActive: isHovered)
        .onHover { hovering in
            withAnimation(.glass.smooth) {
                isHovered = hovering
            }
        }
    }
}

// Glass card interactions
struct GlassCard: View {
    @State private var isPressed = false

    var body: some View {
        cardContent
            .background(.glass)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .blur(.glass(intensity: isPressed ? 0.3 : 0.7))
            .onTapGesture {
                withAnimation(.glass.bounce) {
                    // Handle tap
                }
            }
            .pressAction { pressing in
                withAnimation(.glass.quick) {
                    isPressed = pressing
                }
            }
    }
}
```

#### Glass Transitions and Animations

```swift
// Glass-optimized animations
.animation(.glass.smooth)              // Smooth glass transitions
.animation(.glass.quick)               // Quick glass responses
.animation(.glass.bounce)              // Playful glass bounces
.animation(.glass.fade)                // Glass-aware fade effects

// Complex glass transitions
.transition(.glass.scale)              // Scale with glass effects
.transition(.glass.slide)              // Slide with glass blur
.transition(.glass.morphing)           // Advanced glass morphing

// Custom glass transition
.transition(
    .asymmetric(
        insertion: .glass.appear,
        removal: .glass.dissolve
    )
)
```

### Glass Layout Considerations

#### Content Readability

```swift
// Ensuring content readability with glass backgrounds
struct ReadableGlassContent: View {
    var body: some View {
        contentText
            .background(.glass.readable)        // Auto-adjusts for readability
            .foregroundStyle(.primary.glass)    // Glass-aware text color
            .shadow(.text.glass)                // Text shadow for glass backgrounds
    }
}

// Dynamic contrast adjustment
.dynamicTypeSize(.large ... .accessibilityExtraExtraExtraLarge) { size in
    content
        .background(.glass.accessible(for: size))
        .foregroundStyle(.primary.accessible)
}
```

#### Responsive Glass Design

```swift
// Glass that adapts to window size and context
struct ResponsiveGlassView: View {
    @Environment(\.glassIntensity) private var glassIntensity
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        content
            .background(
                .glass.adaptive(
                    intensity: glassIntensity,
                    colorScheme: colorScheme
                )
            )
    }
}

// Size-adaptive glass materials
.background(.glass.compact)             // For smaller interfaces
.background(.glass.regular)             // For standard interfaces
.background(.glass.spacious)            // For larger interfaces
```

### Glass Accessibility

#### VoiceOver and Glass Effects

```swift
// Glass effects that respect accessibility settings
struct AccessibleGlass: View {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var body: some View {
        content
            .background(
                reduceTransparency ?
                    .regularMaterial :
                    .glass
            )
            .accessibilityElement(children: .contain)
            .accessibilityHint("Glass surface with content")
    }
}
```

#### Motion and Animation Accessibility

```swift
// Respect motion preferences with glass animations
@Environment(\.accessibilityReduceMotion) private var reduceMotion

// Conditional glass animations
.animation(
    reduceMotion ?
        .none :
        .glass.smooth,
    value: animatedValue
)

// Alternative effects for reduced motion
.scaleEffect(
    reduceMotion ?
        1.0 :
        (isHovered ? 1.02 : 1.0)
)
```

### Glass Performance Optimization

#### Efficient Glass Rendering

```swift
// Optimize glass effects for performance
.background(.glass.optimized)           // Performance-optimized glass
.drawingGroup(.glass)                   // Group glass effects efficiently

// Conditional glass based on performance
.background(
    ProcessInfo.processInfo.thermalState == .nominal ?
        .glass :
        .regularMaterial
)

// Layer compositing for complex glass
.compositingGroup(.glass)
.blend(.glass.multiply)
```

### Glass Design Guidelines

#### When to Use Glass Materials

**✅ Use Glass For:**
- Window backgrounds and major UI containers
- Sidebars and navigation elements
- Overlays and temporary content (popovers, sheets)
- Interactive elements that benefit from depth
- Content that needs visual separation while maintaining context

**❌ Avoid Glass For:**
- Text-heavy content without proper contrast
- Performance-critical animations
- Interfaces with complex visual hierarchies
- Elements that need maximum visibility/contrast

#### Glass Material Hierarchy

```swift
// Proper glass layering from back to front
.background(.glass.window)              // Level 0: Window base
.background(.glass.sidebar)             // Level 1: Navigation
.background(.glass)                     // Level 2: Main content
.background(.glass.thick)               // Level 3: Elevated content
.background(.glass.popover)             // Level 4: Overlays
```

#### Glass Color Integration

```swift
// Glass with accent colors
.background(.glass.tinted(.blue))       // Tinted glass backgrounds
.background(.glass.accent)              // Uses app accent color

// Dynamic glass colors
.background(
    .glass.dynamic(
        light: .glass.tinted(.blue.opacity(0.1)),
        dark: .glass.tinted(.blue.opacity(0.2))
    )
)
```

**Implementation Requirements:**
- Always test glass effects with actual content behind them
- Verify readability across all Dynamic Type sizes
- Ensure glass materials respect accessibility preferences
- Test performance on various hardware configurations
- Follow Apple's latest glass material design guidelines

## SwiftUI Concurrency Patterns

**Important**: SwiftUI implementations must follow the MainActor concurrency patterns defined in SwiftCodeGeneration.md. This section extends those general patterns with SwiftUI-specific integration examples. With MainActor set as the default actor isolation in Xcode project settings, all SwiftUI code runs on the main thread by default.

### MainActor Integration with SwiftUI

#### Automatic MainActor Execution
SwiftUI view updates and @State property changes automatically run on MainActor:

```swift
// ✅ GOOD: Automatic MainActor for SwiftUI state updates
struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()
    @State private var isLoading = false
    @State private var items: [ContentItem] = []

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            ZStack {
                List(items) { item in
                    ItemRow(item: item)
                        .onTapGesture {
                            // This runs on MainActor automatically
                            navigationManager.navigate(to: .itemDetail(item))
                        }
                }

                if isLoading {
                    ProgressView()
                }
            }
            .navigationDestination(for: NavigationManager.Destination.self) { destination in
                destinationView(for: destination)
            }
            .task {
                // Structured concurrency for async operations
                await loadData()
            }
        }
    }

    // ✅ GOOD: Async operations with proper MainActor handling
    private func loadData() async {
        isLoading = true  // MainActor - UI update

        do {
            // Move heavy work off MainActor
            let loadedItems = try await dataService.fetchItems()

            // Update UI on MainActor
            items = loadedItems  // MainActor - UI update
        } catch {
            // Handle error on MainActor
            print("Error loading data: \(error)")
        }

        isLoading = false  // MainActor - UI update
    }
}
```

#### SwiftUI State Concurrency Patterns
SwiftUI state should handle concurrency appropriately for optimal performance:

```swift
// ✅ GOOD: View state with proper concurrency for SwiftUI
struct ContentListView: View {
    @State private var items: [ContentItem] = []
    @State private var isLoading = false
    @State private var error: Error?

    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol = DataService()) {
        self.dataService = dataService
    }

    var body: some View {
        List {
            ForEach(items) { item in
                ContentItemRow(item: item)
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            // This creates a Task on MainActor
                            Task { await deleteItem(item) }
                        }
                    }
            }
        }
        .overlay {
            if isLoading {
                ProgressView("Loading items...")
            }
        }
        .alert("Error", isPresented: .constant(error != nil)) {
            Button("Retry") {
                Task { await loadItems() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let error = error {
                Text(error.localizedDescription)
            }
        }
        .refreshable {
            // Pull-to-refresh creates Task on MainActor
            await loadItems()
        }
        .task {
            // Initial load
            await loadItems()
        }
    }

    // ✅ GOOD: Async function that updates state directly
    private func loadItems() async {
        isLoading = true
        error = nil

        do {
            // Heavy work off MainActor (dataService handles this internally)
            let newItems = try await dataService.fetchItems()

            // UI update on MainActor
            items = newItems
        } catch let fetchError {
            // Error handling on MainActor
            error = fetchError
        }

        isLoading = false
    }

    private func deleteItem(_ item: ContentItem) async {
        do {
            // Off-MainActor operation
            try await dataService.deleteItem(item.id)

            // UI update on MainActor
            items.removeAll { $0.id == item.id }
        } catch let deleteError {
            error = deleteError
        }
    }
}
```

#### Custom Actor Integration
For complex operations, use custom actors that coordinate with MainActor:

```swift
// ✅ GOOD: Custom actor coordinating with MainActor
actor DataProcessor {
    private let dataService: DataServiceProtocol

    init(dataService: DataServiceProtocol) {
        self.dataService = dataService
    }

    func processItems(_ items: [ContentItem]) async throws -> [ProcessedItem] {
        // Heavy processing off MainActor
        return try await withThrowingTaskGroup(of: ProcessedItem.self) { group in
            for item in items {
                group.addTask {
                    // Process each item concurrently
                    return try await self.processItem(item)
                }
            }

            var results: [ProcessedItem] = []
            for try await result in group {
                results.append(result)
            }
            return results
        }
    }

    private func processItem(_ item: ContentItem) async throws -> ProcessedItem {
        // Simulate heavy processing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        return ProcessedItem(from: item)
    }
}

// ✅ GOOD: Coordinating custom actor with SwiftUI state
struct ProcessingView: View {
    @State private var processedItems: [ProcessedItem] = []
    @State private var isProcessing = false

    private let dataProcessor = DataProcessor(dataService: DataService())

    var body: some View {
        VStack {
            if isProcessing {
                ProgressView("Processing items...")
            } else {
                List(processedItems) { item in
                    ProcessedItemRow(item: item)
                }
                Button("Process Items") {
                    Task { await processAllItems([...]) } // Pass items to process
                }
            }
        }
    }

    private func processAllItems(_ items: [ContentItem]) async {
        isProcessing = true

        do {
            // Heavy processing off MainActor
            let results = try await dataProcessor.processItems(items)

            // UI update on MainActor
            processedItems = results
        } catch {
            print("Processing failed: \(error)")
        }

        isProcessing = false
    }
}
```

### Performance Considerations for Concurrency

#### Avoiding MainActor Blocking
- **Task Creation**: Use `Task { }` for fire-and-forget operations
- **Non-isolated Functions**: Mark heavy operations as `nonisolated`
- **Background Processing**: Move computation to custom actors
- **UI Updates**: Ensure all `@Published` updates happen on MainActor

#### Common Anti-patterns to Avoid
```swift
// ❌ AVOID: Blocking MainActor with synchronous work
struct BadView: View {
    @State private var result: String = ""

    var body: some View {
        VStack {
            Text(result)
            Button("Process") {
                // ❌ This blocks MainActor
                result = heavySynchronousComputation()
            }
        }
    }

    // ❌ Synchronous function blocking UI
    func heavySynchronousComputation() -> String {
        Thread.sleep(forTimeInterval: 2.0) // Blocks UI for 2 seconds
        return "Done"
    }
}

// ✅ GOOD: Async operation with proper concurrency
struct GoodView: View {
    @State private var result: String = ""
    @State private var isProcessing = false

    var body: some View {
        VStack {
            Text(result)

            if isProcessing {
                ProgressView()
            } else {
                Button("Process") {
                    processAsync()
                }
            }
        }
    }

    // ✅ Async function that doesn't block UI
    func processAsync() {
        isProcessing = true
        Task {
            // Heavy work off MainActor
            let computedResult = await performHeavyComputation()

            // UI update on MainActor
            result = computedResult
            isProcessing = false
        }
    }

    nonisolated func performHeavyComputation() async -> String {
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds, off MainActor
        return "Done"
    }
}
```

### Integration with Navigation
Navigation operations should follow MainActor patterns:

```swift
// ✅ GOOD: Navigation with proper concurrency
@MainActor
class NavigationManager: ObservableObject {
    @Published var path: [Destination] = []

    func navigateToItemDetail(_ item: ContentItem) async {
        // Simulate async preparation (e.g., loading related data)
        let preparedItem = await prepareItemForDisplay(item)

        // Navigation on MainActor
        path.append(.itemDetail(preparedItem))
    }

    private func prepareItemForDisplay(_ item: ContentItem) async -> ContentItem {
        // Any async preparation work
        try? await Task.sleep(nanoseconds: 100_000_000) // Simulate work
        return item
    }
}

// ✅ GOOD: Usage in SwiftUI
struct ContentItemView: View {
    let item: ContentItem
    @EnvironmentObject private var navigationManager: NavigationManager()

    var body: some View {
        VStack {
            Text(item.title)
            Button("View Details") {
                Task {
                    // Async navigation preparation
                    await navigationManager.navigateToItemDetail(item)
                }
            }
        }
    }
}
```

This ensures SwiftUI implementations follow proper concurrency patterns while maintaining responsive user interfaces and correct MainActor isolation.

### Sheet and Modal Presentation Concurrency

**Critical Requirement**: All sheet and modal presentations involving async operations must follow strict coordination patterns to prevent race conditions and UI rendering issues.

#### Sheet Presentation with Async Data Loading
When presenting sheets that require async data preparation, follow this pattern:

```swift
// ✅ CORRECT: Coordinated sheet presentation with async operations
struct AsyncSheetView: View {
    @StateObject private var viewModel = AsyncViewModel()
    @State private var showingSheet = false
    @State private var sheetData: SheetData?

    var body: some View {
        VStack {
            Button("Show Sheet") {
                presentSheetWithData()
            }
            .disabled(viewModel.isLoading)
        }
        .sheet(isPresented: $showingSheet) {
            if let data = sheetData {
                SheetContentView(
                    data: data,
                    isLoading: viewModel.isLoading,
                    onDismiss: dismissSheet
                )
            }
        }
        .overlay {
            if viewModel.isLoading && !showingSheet {
                ProgressView("Loading data...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.3))
            }
        }
    }

    // ✅ CORRECT: Async coordination before presentation
    private func presentSheetWithData() {
        Task { @MainActor in
            do {
                // Load data first, then present
                let data = try await viewModel.loadSheetData()

                // Only set state and present after successful load
                sheetData = data
                showingSheet = true
            } catch {
                // Handle error without presenting sheet
                viewModel.handleError(error)
            }
        }
    }

    private func dismissSheet() {
        showingSheet = false
        sheetData = nil
        viewModel.clearState()
    }
}

// ❌ INCORRECT: Race condition between presentation and data loading
private func badPresentSheet() {
    Task {
        showingSheet = true  // ❌ Presents immediately, before data loads
        sheetData = try await viewModel.loadSheetData()  // ❌ Data loads after presentation
    }
}
```

#### Modal State Management with MainActor
All modal-related state changes must be properly coordinated with MainActor:

```swift
// ✅ CORRECT: Modal view model with proper MainActor coordination
@MainActor
@Observable
final class ModalViewModel {
    private(set) var isLoading = false
    private(set) var content: ModalContent?
    private(set) var error: Error?

    // ✅ CORRECT: Explicit MainActor coordination
    func loadContent() async {
        isLoading = true
        error = nil

        do {
            // Off-MainActor work
            let loadedContent = try await contentService.loadContent()

            // MainActor update
            await MainActor.run {
                content = loadedContent
                isLoading = false
            }
        } catch let loadError {
            await MainActor.run {
                error = loadError
                isLoading = false
                content = nil
            }
        }
    }

    func clearState() {
        content = nil
        error = nil
        isLoading = false
    }
}

// ❌ INCORRECT: Missing MainActor coordination
final class BadModalViewModel: ObservableObject {
    @Published var content: ModalContent?
    @Published var isLoading = false

    func loadContent() async {
        isLoading = true  // ❌ Not guaranteed to be on MainActor

        do {
            content = try await contentService.loadContent()  // ❌ UI update not coordinated
            isLoading = false  // ❌ Missing MainActor guarantee
        } catch {
            isLoading = false  // ❌ Error handling not coordinated
        }
    }
}
```

#### Navigation with Async Preparation
Coordinate async operations with NavigationStack properly:

```swift
// ✅ CORRECT: Navigation with async preparation
@MainActor
class NavigationManager: ObservableObject {
    @Published var path: [Destination] = []
    @Published var isNavigating = false

    func navigateToDetail(_ item: Item) async {
        isNavigating = true

        do {
            // Prepare data for navigation destination
            let preparedData = try await prepareDetailData(for: item)

            // Navigate only after preparation is complete
            path.append(.detail(item, preparedData))
        } catch {
            // Handle preparation error
            handleNavigationError(error)
        }

        isNavigating = false
    }

    private func prepareDetailData(for item: Item) async throws -> DetailData {
        // Async preparation work
        return try await detailService.prepareData(for: item)
    }
}

// ✅ CORRECT: Usage in view
struct NavigationView: View {
    @StateObject private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            List(items) { item in
                Button(item.title) {
                    Task {
                        await navigationManager.navigateToDetail(item)
                    }
                }
                .disabled(navigationManager.isNavigating)
            }
            .navigationDestination(for: Destination.self) { destination in
                destinationView(for: destination)
            }
        }
        .overlay {
            if navigationManager.isNavigating {
                ProgressView("Preparing...")
            }
        }
    }
}
```

### Performance Considerations for Modal Presentations

#### Optimizing Async Modal Performance
```swift
// ✅ CORRECT: Performance-optimized modal with preloading
struct OptimizedModalView: View {
    @StateObject private var viewModel = OptimizedViewModel()
    @State private var showingModal = false
    @State private var preloadedData: ModalData?

    var body: some View {
        VStack {
            Button("Show Modal") {
                showModalWithPreloadedData()
            }
        }
        .onAppear {
            // Preload data in background
            Task {
                await viewModel.preloadData()
            }
        }
        .sheet(isPresented: $showingModal) {
            if let data = preloadedData {
                ModalContentView(data: data)
                    .onAppear {
                        // Start loading additional data if needed
                        Task {
                            await viewModel.loadAdditionalData()
                        }
                    }
            }
        }
    }

    private func showModalWithPreloadedData() {
        if let cached = viewModel.cachedData {
            // Use cached data for immediate presentation
            preloadedData = cached
            showingModal = true
        } else {
            // Fall back to async loading
            Task { @MainActor in
                do {
                    let data = try await viewModel.loadData()
                    preloadedData = data
                    showingModal = true
                } catch {
                    viewModel.handleError(error)
                }
            }
        }
    }
}
```

### Common Anti-patterns to Avoid

#### Race Conditions in Presentation
```swift
// ❌ AVOID: Multiple async operations without coordination
struct BadRaceConditionView: View {
    @State private var showingModal = false
    @State private var data: Data?

    private func badAsyncFlow() {
        Task {
            // ❌ Multiple uncoordinated async operations
            async let userData = loadUserData()
            async let settings = loadSettings()
            async let preferences = loadPreferences()

            // ❌ Setting state before all operations complete
            showingModal = true

            // ❌ Data might not be ready when modal appears
            data = try await userData
        }
    }
}

// ✅ CORRECT: Coordinated async operations
struct GoodCoordinatedView: View {
    @State private var showingModal = false
    @State private var combinedData: CombinedData?

    private func properAsyncFlow() {
        Task { @MainActor in
            do {
                // ✅ Wait for all operations to complete
                async let userData = loadUserData()
                async let settings = loadSettings()
                async let preferences = loadPreferences()

                let combined = CombinedData(
                    user: try await userData,
                    settings: try await settings,
                    preferences: try await preferences
                )

                // ✅ Only present after all data is ready
                combinedData = combined
                showingModal = true
            } catch {
                handleError(error)
            }
        }
    }
}
```

#### Blocking MainActor During Presentation
```swift
// ❌ AVOID: Blocking MainActor during modal operations
struct BadBlockingView: View {
    private func badModalPresentation() {
        Task { @MainActor in
            // ❌ This blocks the main actor for 2 seconds
            try await Task.sleep(nanoseconds: 2_000_000_000)
            showingModal = true
        }
    }
}

// ✅ CORRECT: Off-MainActor work with MainActor coordination
struct GoodNonBlockingView: View {
    private func goodModalPresentation() {
        Task {
            // ✅ Heavy work off MainActor
            let result = await performHeavyWork()

            // ✅ UI update on MainActor
            await MainActor.run {
                applyResult(result)
                showingModal = true
            }
        }
    }

    nonisolated func performHeavyWork() async -> WorkResult {
        // Heavy computation off MainActor
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        return WorkResult()
    }
}
```

This enhanced concurrency guidance ensures all sheet and modal presentations work correctly with async operations while maintaining optimal performance and user experience.

## Async Operations and Sheet Presentation

**Critical Requirement**: All sheet presentations that involve async data loading must properly coordinate async operations with SwiftUI's rendering cycle to prevent race conditions, empty content, and sizing issues. This is essential for preventing UI rendering problems in modals and sheets.

### The Problem: Race Conditions in Sheet Presentation

The most common issue occurs when sheets are presented immediately while async operations are still running, leading to:
- **Empty Content**: Sheets render before data is loaded
- **Sizing Issues**: Windows sized incorrectly due to missing content
- **Poor UX**: Users see loading states or empty interfaces
- **State Inconsistency**: UI state doesn't match actual data state

### Core Principles for Async Sheet Presentation

#### 1. Wait for Async Completion Before Presentation
Always ensure async operations complete before presenting sheets:

```swift
// ✅ CORRECT: Wait for async completion before presenting sheet
struct SpecificationDetailView: View {
    @StateObject private var viewModel = SpecificationViewModel()
    @State private var showingSuggestions = false
    @State private var currentSection: SpecificationSection?

    var body: some View {
        VStack {
            contentView
        }
        .sheet(isPresented: $showingSuggestions) {
            if let section = currentSection {
                AISuggestionsView(
                    section: section,
                    suggestions: viewModel.aiSuggestions,
                    isLoading: viewModel.isRequestingSuggestions,
                    onDismiss: {
                        showingSuggestions = false
                        viewModel.clearSuggestions()
                        currentSection = nil
                    }
                )
            }
        }
    }

    // ✅ CORRECT: Proper async coordination
    private func requestAISuggestions(for section: SpecificationSection) {
        Task { @MainActor in
            // Clear any previous state
            currentSection = nil
            showingSuggestions = false

            // Wait for the async request to complete entirely
            await viewModel.requestSuggestions(for: section)

            // Only present sheet after request has fully completed
            // and we have either suggestions or an error to show
            if !viewModel.aiSuggestions.isEmpty || viewModel.error != nil {
                // Ensure state is set on main actor for immediate UI updates
                currentSection = section
                showingSuggestions = true
            }
        }
    }
}

// ❌ INCORRECT: Race condition - sheet presents before async completion
private func badRequestAISuggestions(for section: SpecificationSection) {
    Task {
        // ❌ This creates a race condition
        currentSection = section
        showingSuggestions = true  // Sheet presents immediately

        await viewModel.requestSuggestions(for: section)  // Async happens after presentation
    }
}
```

#### 2. MainActor State Coordination
Ensure all UI-affecting async operations properly coordinate with MainActor:

```swift
// ✅ CORRECT: Explicit MainActor coordination in view models
@MainActor
@Observable
final class SpecificationViewModel {
    private(set) var aiSuggestions: [String] = []
    private(set) var isRequestingSuggestions = false
    private(set) var error: Error?

    func requestSuggestions(for section: SpecificationSection) async {
        guard let aiService = aiService else {
            await MainActor.run {
                error = .aiServiceUnavailable(underlyingError: "AI service not configured")
            }
            return
        }

        // Ensure all state updates happen on MainActor for immediate UI updates
        await MainActor.run {
            isRequestingSuggestions = true
            error = nil
            aiSuggestions = [] // Clear previous suggestions
        }

        do {
            let suggestions = try await aiService.generateSuggestions(for: section)

            // Update state on MainActor after successful completion
            await MainActor.run {
                aiSuggestions = suggestions
                isRequestingSuggestions = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                aiSuggestions = []
                isRequestingSuggestions = false
            }
        }
    }
}
```

#### 3. Dynamic Content-Aware Sizing
Implement dynamic sizing that adapts to content state:

```swift
// ✅ CORRECT: Dynamic sizing based on content state
struct AISuggestionsView: View {
    let suggestions: [String]
    let isLoading: Bool

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isLoading {
                loadingStateView
            } else if suggestions.isEmpty {
                emptyStateView
            } else {
                suggestionsContent
            }

            Divider()
            actionButtons
        }
        .frame(
            minWidth: 700,
            idealWidth: suggestions.isEmpty && !isLoading ? 800 : 900,
            maxWidth: 1200,
            minHeight: isLoading ? 400 : (suggestions.isEmpty ? 500 : 600),
            idealHeight: suggestions.isEmpty && !isLoading ? 600 : 800,
            maxHeight: 1000
        )
        .background(Color(NSColor.windowBackgroundColor))
        .presentationCompactAdaptation(.none)
        .presentationBackground(.regularMaterial)
    }

    @ViewBuilder
    private var loadingStateView: some View {
        VStack(spacing: 24) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))

            VStack(spacing: 12) {
                Text("Generating AI Suggestions")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Please wait while the AI generates suggestions...")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }
}
```

### Loading State Management

#### Comprehensive Loading States
Provide clear feedback during all phases of async operations:

```swift
// ✅ CORRECT: Comprehensive loading state management
struct AsyncModalView: View {
    @StateObject private var viewModel = AsyncViewModel()
    @State private var showingModal = false
    @State private var currentData: AsyncData?

    var body: some View {
        VStack {
            Button("Load and Show Modal") {
                loadDataAndShowModal()
            }
            .disabled(viewModel.isLoading)
        }
        .sheet(isPresented: $showingModal) {
            if let data = currentData {
                ModalContentView(
                    data: data,
                    isLoading: viewModel.isLoading,
                    error: viewModel.error,
                    onDismiss: {
                        showingModal = false
                        currentData = nil
                        viewModel.clearState()
                    }
                )
            }
        }
        .overlay {
            if viewModel.isLoading && !showingModal {
                LoadingOverlay(message: "Preparing content...")
            }
        }
    }

    private func loadDataAndShowModal() {
        Task { @MainActor in
            do {
                // Show loading state during data preparation
                let data = try await viewModel.loadData()

                // Only present modal after data is fully loaded
                currentData = data
                showingModal = true
            } catch {
                // Handle error without showing modal
                viewModel.handleError(error)
            }
        }
    }
}
```

### Error Handling in Async Presentations

#### Graceful Error Recovery
Handle async failures without breaking the presentation flow:

```swift
// ✅ CORRECT: Graceful error handling in async presentations
struct ResilientAsyncView: View {
    @StateObject private var viewModel = ResilientViewModel()
    @State private var showingModal = false
    @State private var presentationState: PresentationState = .idle

    enum PresentationState {
        case idle, loading, ready(data: Any), error(Error)
    }

    var body: some View {
        VStack {
            Button("Show Modal") {
                prepareAndShowModal()
            }
        }
        .sheet(isPresented: $showingModal) {
            modalContent
        }
        .alert("Error", isPresented: .constant(presentationState.isError)) {
            Button("Retry") { prepareAndShowModal() }
            Button("Cancel", role: .cancel) { presentationState = .idle }
        } message: {
            if case .error(let error) = presentationState {
                Text(error.localizedDescription)
            }
        }
    }

    @ViewBuilder
    private var modalContent: some View {
        switch presentationState {
        case .loading:
            LoadingModalView()
        case .ready(let data):
            ContentModalView(data: data)
        case .error(let error):
            ErrorModalView(error: error, onRetry: prepareAndShowModal)
        case .idle:
            EmptyView()
        }
    }

    private func prepareAndShowModal() {
        Task { @MainActor in
            presentationState = .loading
            showingModal = true  // Show modal with loading state

            do {
                let data = try await viewModel.loadData()
                presentationState = .ready(data: data)
            } catch {
                presentationState = .error(error)
            }
        }
    }
}
```

### Validation Requirements for Async Presentations

#### Mandatory Checks for AI-Generated Code
All AI-generated sheet presentations with async content must include:

1. **Async Completion Verification**: Ensure async operations complete before state changes that trigger presentation
2. **MainActor Coordination**: All UI state updates must use explicit MainActor coordination
3. **Loading State Coverage**: Provide loading indicators for all async operations
4. **Error State Handling**: Include error recovery for all async failures
5. **State Cleanup**: Proper state reset on modal dismissal
6. **Dynamic Sizing**: Content-aware frame sizing based on loading/content state

#### Code Review Checklist
- [ ] Does the sheet wait for async completion before presenting?
- [ ] Are all UI state updates coordinated with MainActor?
- [ ] Is there a loading state while async operations run?
- [ ] Are async errors handled gracefully?
- [ ] Does the modal size adapt to content state?
- [ ] Is state properly cleaned up on dismissal?

This comprehensive approach prevents the race conditions and UI rendering issues that commonly occur when combining async operations with SwiftUI sheet presentations.

## Error Handling and Recovery

**Critical Requirement**: All SwiftUI implementations must provide user-friendly, responsive, and accessible error handling that maintains positive user experience. Errors should be declarative, localized, and provide actionable recovery options. Error types should conform to the patterns defined in SwiftCodeGeneration.md.

### Declarative Error Presentation

#### Alert-Based Error Display
Use SwiftUI's declarative alert modifier for modal error presentation:

```swift
// ✅ GOOD: Declarative error alerts with state binding
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var showError = false
    @State private var currentError: LocalizedError?

    var body: some View {
        VStack {
            if viewModel.isLoading {
                ProgressView("Loading...")
            } else {
                ContentList(items: viewModel.items)
            }
        }
        .alert(isPresented: $showError, error: currentError) { error in
            // Provide recovery actions
            Button("Retry") {
                Task {
                    await viewModel.loadData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: { error in
            Text(error.recoverySuggestion ?? "Please try again.")
        }
        .task {
            await loadDataWithErrorHandling()
        }
    }

    private func loadDataWithErrorHandling() async {
        do {
            try await viewModel.loadData()
        } catch let error as LocalizedError {
            currentError = error
            showError = true
        } catch {
            // Fallback for non-localized errors
            currentError = GenericError(description: "An unexpected error occurred")
            showError = true
        }
    }
}

// ✅ GOOD: Custom LocalizedError implementation
struct GenericError: LocalizedError {
    let description: String

    var errorDescription: String? { description }
    var recoverySuggestion: String? { "Please try again or contact support if the problem persists." }
}
```

#### Inline Error Display
For non-critical errors, use inline messages that don't disrupt user flow:

```swift
// ✅ GOOD: Inline error banners for non-disruptive feedback
struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    @State private var bannerError: LocalizedError?

    var body: some View {
        ZStack(alignment: .top) {
            VStack {
                ContentList(items: viewModel.items)

                Button("Refresh") {
                    Task {
                        await loadWithInlineError()
                    }
                }
            }

            // Inline error banner
            if let error = bannerError {
                ErrorBanner(error: error) {
                    bannerError = nil
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(1)
            }
        }
        .animation(.default, value: bannerError)
    }

    private func loadWithInlineError() async {
        do {
            bannerError = nil // Clear previous errors
            try await viewModel.loadData()
        } catch let error as LocalizedError {
            bannerError = error
        }
    }
}

// ✅ GOOD: Reusable error banner component
struct ErrorBanner: View {
    let error: LocalizedError
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 2) {
                Text(error.errorDescription ?? "Error")
                    .font(.headline)
                    .foregroundColor(.primary)

                if let suggestion = error.recoverySuggestion {
                    Text(suggestion)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Button(action: dismissAction) {
                Image(systemName: "xmark")
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
        .padding(.horizontal)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Error: \(error.errorDescription ?? "Unknown error")")
        .accessibilityHint("Tap the X to dismiss")
    }
}
```

#### Alternative Error Display Strategies
Choose appropriate error presentation based on severity and context:

```swift
// ✅ GOOD: Adaptive error display based on context
enum ErrorSeverity {
    case transient, recoverable, critical
}

struct AdaptiveErrorView: View {
    let error: LocalizedError
    let severity: ErrorSeverity
    let retryAction: () -> Void

    var body: some View {
        Group {
            switch severity {
            case .transient:
                // Subtle inline notification
                transientErrorView
            case .recoverable:
                // Modal alert with recovery options
                recoverableErrorView
            case .critical:
                // Full-screen error state
                criticalErrorView
            }
        }
    }

    private var transientErrorView: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.exclamationmark")
                .foregroundColor(.orange)
            Text(error.errorDescription ?? "Connection issue")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }

    private var recoverableErrorView: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(error.recoverySuggestion ?? "Please try again.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                Button("Cancel", role: .cancel) {}
                Button("Retry", action: retryAction)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }

    private var criticalErrorView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(.red)

            Text("Unable to continue")
                .font(.title)
                .fontWeight(.bold)

            Text(error.errorDescription ?? "A critical error occurred")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Button("Restart App", action: restartApp)
                .buttonStyle(.borderedProminent)
                .tint(.red)

            Spacer()
        }
        .padding()
        .background(Color(.systemGroupedBackground).edgesIgnoringSafeArea(.all))
    }

    private func restartApp() {
        // Implementation would depend on app architecture
        // This is a placeholder for app restart logic
    }
}
```

### Localized Error Messages

#### LocalizedError Protocol Implementation
All custom errors should conform to LocalizedError for user-friendly messages:

```swift
// ✅ GOOD: Comprehensive LocalizedError implementations
enum NetworkError: LocalizedError {
    case connectionFailed
    case timeout
    case serverError(code: Int)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .connectionFailed:
            return "Connection Failed"
        case .timeout:
            return "Request Timed Out"
        case .serverError(let code):
            return "Server Error (\(code))"
        case .invalidResponse:
            return "Invalid Response"
        }
    }

    var failureReason: String? {
        switch self {
        case .connectionFailed:
            return "Unable to connect to the server"
        case .timeout:
            return "The request took too long to complete"
        case .serverError:
            return "The server encountered an error"
        case .invalidResponse:
            return "The server returned unexpected data"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .connectionFailed, .timeout:
            return "Check your internet connection and try again"
        case .serverError:
            return "Please try again in a few moments"
        case .invalidResponse:
            return "Try refreshing the data or contact support"
        }
    }
}

enum ValidationError: LocalizedError {
    case emptyField(field: String)
    case invalidEmail
    case passwordTooShort(minimum: Int)
    case passwordsDontMatch

    var errorDescription: String? {
        switch self {
        case .emptyField(let field):
            return "\(field) is required"
        case .invalidEmail:
            return "Invalid Email"
        case .passwordTooShort:
            return "Password Too Short"
        case .passwordsDontMatch:
            return "Passwords Don't Match"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .emptyField:
            return "Please fill in this required field"
        case .invalidEmail:
            return "Please enter a valid email address"
        case .passwordTooShort(let minimum):
            return "Password must be at least \(minimum) characters long"
        case .passwordsDontMatch:
            return "Please make sure both passwords match"
        }
    }
}
```

### Error Propagation and Hierarchy

#### Structured Error Handling
Implement proper error propagation through the view hierarchy:

```swift
// ✅ GOOD: Error propagation through view model hierarchy
@MainActor
class AppViewModel: ObservableObject {
    @Published private(set) var currentError: LocalizedError?
    @Published private(set) var isLoading = false

    private let dataService: DataServiceProtocol
    private let networkService: NetworkServiceProtocol

    init(dataService: DataServiceProtocol, networkService: NetworkServiceProtocol) {
        self.dataService = dataService
        self.networkService = networkService
    }

    func performComplexOperation() async {
        isLoading = true
        currentError = nil

        do {
            // Step 1: Network operation
            let data = try await networkService.fetchData()

            // Step 2: Data processing
            let processedData = try await dataService.processData(data)

            // Step 3: Local storage
            try await dataService.saveData(processedData)

        } catch let error as NetworkError {
            // Handle network-specific errors
            currentError = error
        } catch let error as ValidationError {
            // Handle validation errors
            currentError = error
        } catch let error as DataServiceError {
            // Handle data service errors
            currentError = DataError.storageFailed(underlying: error)
        } catch {
            // Fallback for unexpected errors
            currentError = GenericError(description: "An unexpected error occurred")
        }

        isLoading = false
    }
}

// ✅ GOOD: Error handling in SwiftUI views
struct AppView: View {
    @StateObject private var viewModel = AppViewModel(
        dataService: DataService(),
        networkService: NetworkService()
    )

    var body: some View {
        ZStack {
            MainContentView()

            if viewModel.isLoading {
                LoadingOverlay()
            }
        }
        .errorAlert(error: viewModel.currentError) {
            // Clear error when alert is dismissed
            viewModel.currentError = nil
        }
        .task {
            await viewModel.performComplexOperation()
        }
    }
}

// ✅ GOOD: Reusable error alert modifier
extension View {
    func errorAlert(error: LocalizedError?, onDismiss: @escaping () -> Void) -> some View {
        self.alert(
            "Error",
            isPresented: .init(get: { error != nil }, set: { if !$0 { onDismiss() } }),
            presenting: error
        ) { error in
            Button("Retry") {
                Task {
                    // Retry logic would be passed in or handled by parent
                }
            }
            Button("OK", role: .cancel) {}
        } message: { error in
            Text(error.recoverySuggestion ?? "Please try again.")
        }
    }
}
```

### Logging, Fallbacks, and Crash Prevention

#### Proper Logging Implementation
Use unified logging instead of print statements for production code:

```swift
import OSLog

// ✅ GOOD: Structured logging for errors
extension Logger {
    static let network = Logger(subsystem: "com.homermobilepoc", category: "network")
    static let data = Logger(subsystem: "com.homermobilepoc", category: "data")
    static let ui = Logger(subsystem: "com.homermobilepoc", category: "ui")
}

@MainActor
class ErrorHandlingViewModel: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var error: LocalizedError?

    private let dataService: DataServiceProtocol
    private let cacheService: CacheServiceProtocol

    init(dataService: DataServiceProtocol, cacheService: CacheServiceProtocol) {
        self.dataService = dataService
        self.cacheService = cacheService
    }

    func loadItems() async {
        do {
            Logger.data.info("Starting item load")

            // Try network first
            let freshItems = try await dataService.fetchItems()
            items = freshItems

            // Cache successful results
            try await cacheService.cacheItems(freshItems)

            Logger.data.info("Successfully loaded \(freshItems.count) items")

        } catch let networkError as NetworkError {
            Logger.network.error("Network error loading items: \(networkError.localizedDescription)")

            // Fallback to cache
            do {
                let cachedItems = try await cacheService.loadCachedItems()
                items = cachedItems
                Logger.data.info("Loaded \(cachedItems.count) items from cache")

                // Show user-friendly error about using cached data
                error = CacheError.networkFailedUsingCache
            } catch {
                Logger.data.error("Failed to load cached items: \(error.localizedDescription)")
                error = networkError
            }

        } catch let validationError as ValidationError {
            Logger.data.error("Validation error: \(validationError.localizedDescription)")
            error = validationError

        } catch {
            Logger.data.error("Unexpected error loading items: \(error.localizedDescription)")
            error = GenericError(description: "An unexpected error occurred")
        }
    }
}
```

#### Fallback Strategies
Implement multiple fallback layers for resilience:

```swift
// ✅ GOOD: Multi-layer fallback strategy
@MainActor
class ResilientViewModel: ObservableObject {
    @Published private(set) var content: Content?
    @Published private(set) var error: LocalizedError?

    private let primaryService: ContentServiceProtocol
    private let cacheService: CacheServiceProtocol
    private let defaultService: DefaultContentServiceProtocol

    init(primaryService: ContentServiceProtocol,
         cacheService: CacheServiceProtocol,
         defaultService: DefaultContentServiceProtocol) {
        self.primaryService = primaryService
        self.cacheService = cacheService
        self.defaultService = defaultService
    }

    func loadContent() async {
        error = nil

        do {
            // Try primary service first
            content = try await primaryService.loadContent()
            Logger.ui.info("Loaded content from primary service")

        } catch let primaryError {
            Logger.ui.warning("Primary service failed: \(primaryError.localizedDescription)")

            do {
                // Fallback to cache
                content = try await cacheService.loadCachedContent()
                Logger.ui.info("Loaded content from cache")
                error = CacheError.usingCachedData

            } catch let cacheError {
                Logger.ui.warning("Cache failed: \(cacheError.localizedDescription)")

                do {
                    // Final fallback to defaults
                    content = try await defaultService.loadDefaultContent()
                    Logger.ui.info("Loaded default content")
                    error = FallbackError.usingDefaultContent

                } catch let defaultError {
                    Logger.ui.error("All fallbacks failed: \(defaultError.localizedDescription)")
                    error = FallbackError.noContentAvailable
                }
            }
        }
    }
}

// ✅ GOOD: Error types for different fallback scenarios
enum CacheError: LocalizedError {
    case networkFailedUsingCache

    var errorDescription: String? {
        "Using cached data due to connection issues"
    }

    var recoverySuggestion: String? {
        "Content may not be up to date. Check your connection to refresh."
    }
}

enum FallbackError: LocalizedError {
    case usingDefaultContent
    case noContentAvailable

    var errorDescription: String? {
        switch self {
        case .usingDefaultContent:
            return "Using default content"
        case .noContentAvailable:
            return "Unable to load content"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .usingDefaultContent:
            return "Some features may be limited"
        case .noContentAvailable:
            return "Please check your connection and try again"
        }
    }
}
```

### Error Testing and Previews

#### Comprehensive Error Testing
Include error scenarios in unit tests and previews:

```swift
// ✅ GOOD: Error scenario testing
@testable import MyApp

@Suite("Error Handling Tests")
struct ErrorHandlingTests {
    @Test("Network error fallback to cache")
    func testNetworkErrorFallback() async throws {
        let mockNetworkService = MockNetworkService()
        mockNetworkService.shouldFail = true

        let cacheService = MockCacheService()
        cacheService.cachedItems = [mockItem]

        let viewModel = ErrorHandlingViewModel(
            dataService: MockDataService(networkService: mockNetworkService),
            cacheService: cacheService
        )

        await viewModel.loadItems()

        #expect(viewModel.items.count == 1)
        #expect(viewModel.error is CacheError)
    }

    @Test("Complete failure with user feedback")
    func testCompleteFailure() async throws {
        let mockNetworkService = MockNetworkService()
        mockNetworkService.shouldFail = true

        let mockCacheService = MockCacheService()
        mockCacheService.shouldFail = true

        let viewModel = ErrorHandlingViewModel(
            dataService: MockDataService(networkService: mockNetworkService),
            cacheService: mockCacheService
        )

        await viewModel.loadItems()

        #expect(viewModel.items.isEmpty)
        #expect(viewModel.error is NetworkError)
    }
}

// ✅ GOOD: Preview with error states
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Normal state
            ContentView(viewModel: MockViewModel.normal)

            // Loading state
            ContentView(viewModel: MockViewModel.loading)

            // Error state
            ContentView(viewModel: MockViewModel.error)

            // Cache fallback state
            ContentView(viewModel: MockViewModel.cached)
        }
    }
}

class MockViewModel: ObservableObject {
    @Published var items: [Item] = []
    @Published var error: LocalizedError?
    @Published var isLoading = false

    static var normal: MockViewModel {
        let vm = MockViewModel()
        vm.items = [Item(id: "1", name: "Test Item")]
        return vm
    }

    static var loading: MockViewModel {
        let vm = MockViewModel()
        vm.isLoading = true
        return vm
    }

    static var error: MockViewModel {
        let vm = MockViewModel()
        vm.error = NetworkError.connectionFailed
        return vm
    }

    static var cached: MockViewModel {
        let vm = MockViewModel()
        vm.items = [Item(id: "1", name: "Cached Item")]
        vm.error = CacheError.networkFailedUsingCache
        return vm
    }
}
```

This comprehensive error handling approach ensures SwiftUI applications provide excellent user experience even when things go wrong, with proper localization, accessibility, testing, and recovery mechanisms built into every component.

## Modern Navigation with NavigationStack

**Critical Requirement**: All navigation must use modern SwiftUI structures. Never use deprecated `NavigationView` - always use `NavigationStack` and `NavigationLink` for deep linking and path management. Navigation must be state-driven and avoid imperative patterns.

### NavigationStack Fundamentals

#### State-Driven Navigation
Navigation state should be managed through observable objects and environment values, not imperative navigation calls:

```swift
// ✅ GOOD: State-driven navigation with observable object
class NavigationManager: ObservableObject {
    @Published var path: [Destination] = []

    enum Destination: Hashable {
        case itemDetail(ContentItem)
        case settings
        case profile(User)
        case deepLink(section: String, item: String)
    }

    func navigate(to destination: Destination) {
        path.append(destination)
    }

    func navigateToRoot() {
        path.removeAll()
    }

    func goBack() {
        path.removeLast()
    }

    func goBack(to destination: Destination) {
        if let index = path.firstIndex(of: destination) {
            path = Array(path.prefix(through: index))
        }
    }
}

// ✅ GOOD: Environment integration for global navigation
struct ContentView: View {
    @StateObject private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            HomeView()
                .navigationDestination(for: NavigationManager.Destination.self) { destination in
                    switch destination {
                    case .itemDetail(let item):
                        ContentDetailView(item: item)
                    case .settings:
                        SettingsView()
                    case .profile(let user):
                        ProfileView(user: user)
                    case .deepLink(let section, let item):
                        DeepLinkView(section: section, item: item)
                    }
                }
        }
        .environmentObject(navigationManager)
    }
}
```

### NavigationLink Patterns

#### Programmatic Navigation
Use NavigationLink with binding for state-driven navigation:

```swift
// ✅ GOOD: Programmatic navigation with state binding
struct HomeView: View {
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        List(items) { item in
            NavigationLink(value: NavigationManager.Destination.itemDetail(item)) {
                ContentItemRow(item: item)
            }
        }
        .navigationTitle("Home")
        .toolbar {
            Button("Settings") {
                navigationManager.navigate(to: .settings)
            }
        }
    }
}

// ✅ GOOD: Conditional navigation with state
struct ConditionalNavigationView: View {
    @State private var isAuthenticated = false
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        VStack {
            if isAuthenticated {
                NavigationLink(value: NavigationManager.Destination.profile(currentUser)) {
                    Text("View Profile")
                }
            } else {
                Button("Login Required") {
                    // Handle login flow
                }
            }
        }
    }
}
```

#### Deep Linking Support
Implement deep linking through URL handling and NavigationStack path management:

```swift
// ✅ GOOD: Deep linking with URL support
struct AppView: View {
    @StateObject private var navigationManager = NavigationManager()

    var body: some View {
        NavigationStack(path: $navigationManager.path) {
            HomeView()
                .navigationDestination(for: NavigationManager.Destination.self) { destination in
                    destinationView(for: destination)
                }
        }
        .environmentObject(navigationManager)
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Parse URL and navigate
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }

        switch components.path {
        case "/item":
            if let itemId = components.queryItems?.first(where: { $0.name == "id" })?.value,
               let item = findItem(by: itemId) {
                navigationManager.navigate(to: .itemDetail(item))
            }
        case "/settings":
            navigationManager.navigate(to: .settings)
        case "/profile":
            if let userId = components.queryItems?.first(where: { $0.name == "user" })?.value,
               let user = findUser(by: userId) {
                navigationManager.navigate(to: .profile(user))
            }
        default:
            break
        }
    }

    private func destinationView(for destination: NavigationManager.Destination) -> some View {
        Group {
            switch destination {
            case .itemDetail(let item):
                ContentDetailView(item: item)
            case .settings:
                SettingsView()
            case .profile(let user):
                ProfileView(user: user)
            case .deepLink(let section, let item):
                DeepLinkView(section: section, item: item)
            }
        }
    }
}
```

### Navigation Path Management

#### Complex Path Handling
Use NavigationPath for type-safe path management with multiple destination types:

```swift
// ✅ GOOD: Type-safe path management with NavigationPath
struct AppNavigation: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView()
                .navigationDestination(for: ContentItem.self) { item in
                    ContentDetailView(item: item)
                }
                .navigationDestination(for: User.self) { user in
                    ProfileView(user: user)
                }
                .navigationDestination(for: SettingsSection.self) { section in
                    SettingsDetailView(section: section)
                }
        }
    }
}

// ✅ GOOD: Programmatic path manipulation
extension NavigationPath {
    mutating func navigateToItem(_ item: ContentItem) {
        append(item)
    }

    mutating func navigateToUser(_ user: User) {
        append(user)
    }

    mutating func goToSettingsSection(_ section: SettingsSection) {
        append(section)
    }
}
```

#### Back Navigation Control
Implement proper back navigation with state management:

```swift
// ✅ GOOD: Controlled back navigation
struct DetailView: View {
    let item: ContentItem
    @EnvironmentObject private var navigationManager: NavigationManager

    var body: some View {
        VStack {
            Text(item.title)

            Button("Go Back to Home") {
                navigationManager.navigateToRoot()
            }

            Button("Go Back to Settings") {
                navigationManager.goBack(to: .settings)
            }

            Button("Custom Back Action") {
                // Perform cleanup or validation before going back
                performCleanup()
                navigationManager.goBack()
            }
        }
        .navigationTitle(item.title)
        .navigationBarBackButtonHidden() // Hide default back button
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    // Custom back action
                    navigationManager.goBack()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back")
                    }
                }
            }
        }
    }

    private func performCleanup() {
        // Cleanup logic before navigation
        print("Cleaning up before navigation")
    }
}
```

### Navigation Presentation Styles

#### Sheet and Full Screen Cover
Use modern presentation styles with NavigationStack compatibility:

```swift
// ✅ GOOD: Sheet presentation with NavigationStack
struct ModalNavigationView: View {
    @State private var showSheet = false
    @State private var showFullScreen = false

    var body: some View {
        NavigationStack {
            VStack {
                Button("Show Sheet") {
                    showSheet = true
                }

                Button("Show Full Screen") {
                    showFullScreen = true
                }
            }
            .navigationTitle("Modal Demo")
            .sheet(isPresented: $showSheet) {
                NavigationStack {
                    ModalContentView()
                        .navigationTitle("Sheet Content")
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button("Done") {
                                    showSheet = false
                                }
                            }
                        }
                }
            }
            .fullScreenCover(isPresented: $showFullScreen) {
                NavigationStack {
                    FullScreenContentView()
                        .navigationTitle("Full Screen Content")
                }
            }
        }
    }
}
```

### Navigation State Persistence

#### State Restoration
Implement navigation state persistence for deep linking and app resumption:

```swift
// ✅ GOOD: Navigation state persistence
class PersistentNavigationManager: ObservableObject {
    @Published var path: [NavigationManager.Destination] = [] {
        didSet {
            saveNavigationState()
        }
    }

    private let navigationStateKey = "navigationState"

    init() {
        loadNavigationState()
    }

    private func saveNavigationState() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(path) {
            UserDefaults.standard.set(data, forKey: navigationStateKey)
        }
    }

    private func loadNavigationState() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: navigationStateKey),
           let savedPath = try? decoder.decode([NavigationManager.Destination].self, from: data) {
            path = savedPath
        }
    }

    func clearSavedState() {
        UserDefaults.standard.removeObject(forKey: navigationStateKey)
        path.removeAll()
    }
}

// Make Destination conform to Codable for persistence
extension NavigationManager.Destination: Codable {
    enum CodingKeys: String, CodingKey {
        case itemDetail, settings, profile, deepLink
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .itemDetail(let item):
            try container.encode(item, forKey: .itemDetail)
        case .settings:
            try container.encode(true, forKey: .settings)
        case .profile(let user):
            try container.encode(user, forKey: .profile)
        case .deepLink(let section, let item):
            let deepLinkData = ["section": section, "item": item]
            try container.encode(deepLinkData, forKey: .deepLink)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        if let item = try? container.decode(Item.self, forKey: .itemDetail) {
            self = .itemDetail(item)
        } else if (try? container.decode(Bool.self, forKey: .settings)) != nil {
            self = .settings
        } else if let user = try? container.decode(User.self, forKey: .profile) {
            self = .profile(user)
        } else if let deepLinkData = try? container.decode([String: String].self, forKey: .deepLink),
                  let section = deepLinkData["section"],
                  let item = deepLinkData["item"] {
            self = .deepLink(section: section, item: item)
        } else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: "Invalid destination"))
        }
    }
}
```

### Deprecated Patterns to Avoid

#### ❌ NEVER USE: NavigationView
```swift
// ❌ AVOID: Deprecated NavigationView
struct BadNavigationView: View {
    var body: some View {
        NavigationView {  // Deprecated - do not use
            List {
                NavigationLink(destination: DetailView()) {
                    Text("Go to detail")
                }
            }
            .navigationBarTitle("Home")
        }
    }
}
```

#### ❌ NEVER USE: Imperative Navigation
```swift
// ❌ AVOID: Imperative navigation patterns
struct BadImperativeView: View {
    var body: some View {
        VStack {
            Button("Navigate Imperatively") {
                // ❌ Never do this - navigation should be state-driven
                // No direct navigation calls in button actions
            }
        }
    }
}
```

### Navigation Testing Requirements

#### Unit Testing Navigation State
```swift
// ✅ GOOD: Test navigation state management
@testable import MyApp

@Suite("Navigation Manager Tests")
struct NavigationManagerTests {
    @Test("Navigate to item detail")
    func testNavigateToItemDetail() async throws {
        let navigationManager = NavigationManager()

        let item = ContentItem(id: "1", title: "Test Item")
        navigationManager.navigate(to: .itemDetail(item))

        #expect(navigationManager.path.count == 1)
        #expect(navigationManager.path.first == .itemDetail(item))
    }

    @Test("Navigate back")
    func testNavigateBack() async throws {
        let navigationManager = NavigationManager()

        navigationManager.navigate(to: .settings)
        navigationManager.navigate(to: .profile(User(id: "1", name: "Test")))

        navigationManager.goBack()

        #expect(navigationManager.path.count == 1)
        #expect(navigationManager.path.first == .settings)
    }

    @Test("Navigate to root")
    func testNavigateToRoot() async throws {
        let navigationManager = NavigationManager()

        navigationManager.navigate(to: .settings)
        navigationManager.navigate(to: .profile(User(id: "1", name: "Test")))

        navigationManager.navigateToRoot()

        #expect(navigationManager.path.isEmpty)
    }
}
```

#### UI Testing Navigation Flows
```swift
// ✅ GOOD: UI test navigation flows
import XCTest

class NavigationUITests: XCTestCase {
    func testNavigationToItemDetail() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate to item detail
        app.buttons["item-1"].tap()

        // Verify navigation occurred
        XCTAssertTrue(app.navigationBars["Item Detail"].exists)
        XCTAssertTrue(app.staticTexts["Item Title"].exists)
    }

    func testDeepLinkNavigation() throws {
        let app = XCUIApplication()
        app.launch(with: ["url": "myapp://item?id=1"])

        // Verify deep link navigation worked
        XCTAssertTrue(app.navigationBars["Item Detail"].exists)
    }

    func testBackNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Navigate forward
        app.buttons["settings-button"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)

        // Navigate back
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.navigationBars["Home"].exists)
    }
}
```

### Navigation Best Practices

#### State Management
- **Observable Objects**: Use @StateObject and @ObservedObject for navigation state
- **Environment Objects**: Inject navigation managers through environment
- **State-Driven**: All navigation should be triggered by state changes, not imperative calls

#### Path Management
- **Type Safety**: Use enums for destinations to ensure type safety
- **Hashable Conformance**: Make destination types conform to Hashable for NavigationStack
- **Codable Support**: Implement Codable for state persistence and deep linking

#### User Experience
- **Consistent Patterns**: Follow iOS navigation conventions
- **Back Button Behavior**: Respect system back button expectations
- **Loading States**: Show appropriate loading states during navigation
- **Error Handling**: Handle navigation failures gracefully

#### Performance
- **Lazy Loading**: Defer expensive view creation until needed
- **State Optimization**: Minimize unnecessary navigation state updates
- **Memory Management**: Clean up unused navigation paths

This modern navigation approach ensures type-safe, state-driven navigation with full deep linking support while maintaining compatibility with SwiftUI's latest navigation APIs.

## View Decomposition with @ViewBuilder

### @ViewBuilder Pattern Requirements
- **Function Size Limit**: No view body function should exceed 50 lines
- **Single Responsibility**: Each @ViewBuilder function should handle one logical UI section
- **Private Functions**: All decomposed functions must be private
- **Descriptive Naming**: Use clear, descriptive names for decomposed functions

### When to Decompose
- **Complex Conditional Logic**: When view body contains multiple if-else branches
- **Large Lists/Collections**: When rendering arrays of subviews
- **Repeated UI Patterns**: When similar UI structures appear multiple times
- **Nested View Hierarchies**: When views are deeply nested (>3 levels)

### @ViewBuilder Function Examples
```swift
struct ComplexView: View {
    @StateObject private var viewModel = ComplexViewModel()

    var body: some View {
        VStack(spacing: 20) {
            headerSection
            contentSection
            footerSection
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(spacing: 12) {
            Text(viewModel.title)
                .font(.title)
                .fontWeight(.bold)

            if let subtitle = viewModel.subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }

    @ViewBuilder
    private var contentSection: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(viewModel.items) { item in
                    contentItemRow(for: item)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func contentItemRow(for item: ContentItem) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            if item.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .shadow(radius: 2)
    }

    @ViewBuilder
    private var footerSection: some View {
        HStack(spacing: 16) {
            Button(action: viewModel.cancelAction) {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.primary)
                    .cornerRadius(8)
            }

            Button(action: viewModel.confirmAction) {
                Text("Confirm")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}
```

### Benefits of View Decomposition
- **Readability**: Each function focuses on one UI concern
- **Maintainability**: Easier to modify individual UI sections
- **Testability**: Smaller functions are easier to test
- **Reusability**: Decomposed views can be reused in other contexts
- **Performance**: SwiftUI can optimize rendering of smaller view hierarchies

## Declarative SwiftUI Programming

### Core Principle
SwiftUI describes what the UI should look like, not how to build it. Focus on state and relationships, not step-by-step construction.

### Declarative Constructs to Use
- **Modifiers**: `.foregroundColor()`, `.font()`, `.padding()`, `.background()`, etc.
- **Stacks**: `VStack`, `HStack`, `ZStack` for layout
- **Conditionals**: Ternary operators `condition ? viewA : viewB` for conditional views
- **Collections**: `ForEach` for dynamic lists
- **State Bindings**: `@State`, `@Binding`, `@ObservedObject` for reactive updates

### Imperative Patterns to Avoid
```swift
// ❌ AVOID: Imperative UIKit-style logic
struct BadView: View {
    var body: some View {
        let label = UILabel() // UIKit object in SwiftUI!
        label.text = "Hello"
        label.textColor = .black
        return Text("Hello") // Ignoring the UILabel
    }
}

// ❌ AVOID: Manual view construction steps
struct BadView: View {
    var body: some View {
        var result = Text("Base")
        if showExtra {
            result = result.bold() // Imperative mutation
        }
        if isLarge {
            result = result.font(.largeTitle) // More mutation
        }
        return result
    }
}
```

### Declarative Patterns to Embrace
```swift
// ✅ GOOD: Declarative state description
struct GoodView: View {
    @State private var isLarge = false
    @State private var showExtra = true

    var body: some View {
        Text("Hello World")
            .font(isLarge ? .largeTitle : .body)          // Conditional modifier
            .fontWeight(showExtra ? .bold : .regular)     // Another conditional
            .foregroundColor(.primary)                    // Declarative styling
            .padding()                                    // Declarative spacing
    }
}

// ✅ GOOD: Using stacks for layout (small lists)
struct SmallListView: View {
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {        // Declarative layout
            Text("My Items")
                .font(.headline)

            ForEach(items, id: \.self) { item in           // Declarative iteration
                HStack {                                   // Declarative horizontal layout
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 8, height: 8)

                    Text(item)
                        .font(.body)

                    Spacer()                               // Declarative spacing

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))             // Declarative theming
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

// ✅ GOOD: Using lazy stacks for large lists
struct LargeListView: View {
    let items = Array(1...100).map { "Item \($0)" }       // Large dataset

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 12) { // Lazy loading for performance
                Text("My Large List")
                    .font(.headline)

                ForEach(items, id: \.self) { item in
                    HStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)

                        Text(item)
                            .font(.body)

                        Spacer()

                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
    }
}

// ✅ GOOD: Conditional views with ternary operators
struct ConditionalView: View {
    @State private var isLoggedIn = false
    @State private var hasError = false

    var body: some View {
        VStack(spacing: 20) {
            // Conditional view rendering
            isLoggedIn ?
                loggedInContent :
                loginPrompt

            // Conditional styling
            Text(hasError ? "Error occurred" : "All good")
                .foregroundColor(hasError ? .red : .green)
                .font(hasError ? .headline : .body)
        }
    }

    @ViewBuilder
    private var loggedInContent: some View {
        VStack(spacing: 16) {
            Text("Welcome back!")
                .font(.title)
            Button("Logout") {
                isLoggedIn = false
            }
        }
    }

    @ViewBuilder
    private var loginPrompt: some View {
        VStack(spacing: 16) {
            Text("Please log in")
                .font(.title)
            Button("Login") {
                isLoggedIn = true
            }
        }
    }
}
```

### Key Declarative Concepts
- **State Drives UI**: Changes to `@State` or `@ObservedObject` automatically update the UI
- **Compositional**: Build complex UIs by composing simpler views
- **Reactive**: UI reacts to state changes automatically
- **Immutable**: View bodies are computed properties, not mutable procedures

### Benefits of Declarative Programming
- **Predictable**: State changes predictably update the UI
- **Maintainable**: Easier to reason about and modify
- **Testable**: Pure functions are easier to test
- **Performant**: SwiftUI optimizes rendering automatically
- **Concise**: Less boilerplate code than imperative approaches

## Type-Safe View Composition (Avoiding AnyView)

### Critical Requirement
Never use `AnyView` as it erases type information, prevents SwiftUI optimizations, and degrades performance. Always use type-preserving alternatives.

### Why Avoid AnyView
- **Type Erasure**: Loses compile-time type checking and optimization opportunities
- **Performance Impact**: Prevents SwiftUI from optimizing view diffing and rendering
- **Debugging Difficulty**: Makes view hierarchy inspection harder
- **Optimization Barriers**: Blocks SwiftUI's ability to perform static analysis

### Type-Preserving Alternatives

#### 1. Group for Logical Grouping (No Layout Impact)
```swift
// ✅ GOOD: Group preserves types without affecting layout
struct ContentView: View {
    @State private var showAdvanced = false

    var body: some View {
        VStack {
            Group {                    // Groups views logically
                if showAdvanced {
                    advancedControls
                } else {
                    basicControls
                }
            }
            .padding()                 // Applied to the group result

            toggleButton
        }
    }

    @ViewBuilder
    private var basicControls: some View {
        Text("Basic Mode")
        Button("Action") { }
    }

    @ViewBuilder
    private var advancedControls: some View {
        Text("Advanced Mode")
        Slider(value: .constant(0.5))
        Toggle("Setting", isOn: .constant(true))
    }

    private var toggleButton: some View {
        Button(showAdvanced ? "Simple" : "Advanced") {
            showAdvanced.toggle()
        }
    }
}
```

#### 2. @ViewBuilder for Conditional View Building
```swift
// ✅ GOOD: @ViewBuilder maintains type information
struct AdaptiveView: View {
    let userType: UserType

    var body: some View {
        userContent      // Type-safe composition
    }

    @ViewBuilder
    private var userContent: some View {
        switch userType {
        case .guest:
            guestInterface
        case .member:
            memberInterface
        case .admin:
            adminInterface
        }
    }

    private var guestInterface: some View {
        Text("Welcome, Guest!")
        Button("Sign Up") { }
    }

    private var memberInterface: some View {
        Text("Welcome back, Member!")
        Button("View Profile") { }
        Button("Access Features") { }
    }

    private var adminInterface: some View {
        Text("Admin Panel")
        Button("Manage Users") { }
        Button("System Settings") { }
        Button("Analytics") { }
    }
}
```

#### 3. Ternary Operators for Simple Conditionals
```swift
// ✅ GOOD: Ternary operators preserve types
struct StatusView: View {
    @State private var isOnline = true

    var body: some View {
        HStack {
            Circle()
                .fill(isOnline ? Color.green : Color.red)  // Type-safe conditional
                .frame(width: 12, height: 12)

            Text(isOnline ? "Online" : "Offline")          // Type-safe conditional
                .foregroundColor(isOnline ? .primary : .secondary)
        }
    }
}
```

#### 4. Enum-Based View Selection
```swift
// ✅ GOOD: Enum with associated values maintains type safety
enum ContentMode {
    case list, grid, detail(Item)
}

struct ContentView: View {
    @State private var mode: ContentMode = .list

    var body: some View {
        contentView
    }

    @ViewBuilder
    private var contentView: some View {
        switch mode {
        case .list:
            ListView()
        case .grid:
            GridView()
        case .detail(let item):
            DetailView(item: item)
        }
    }
}
```

#### 5. Protocol-Based View Abstraction
```swift
// ✅ GOOD: Protocol preserves type information
protocol ConfigurableView: View {
    associatedtype Configuration
    init(configuration: Configuration)
}

struct SettingsView<Model: ConfigurableView>: View {
    let model: Model

    var body: some View {
        model  // Type-safe view composition
    }
}
```

### Performance Benefits of Type Preservation
- **Compile-Time Optimization**: SwiftUI can analyze and optimize view hierarchies at compile time
- **Runtime Efficiency**: Faster view diffing and rendering without type erasure overhead
- **Memory Optimization**: Better memory layout and reduced boxing/unboxing
- **Debugging**: Clearer view hierarchy inspection and error reporting

### When Type Preservation Matters Most
- **Complex View Hierarchies**: Deep nesting benefits most from optimization
- **Frequently Updating Views**: State changes render faster with preserved types
- **Reusable Components**: Type safety ensures correct usage across the app
- **Performance-Critical UI**: Animations and interactions perform better

## Accessibility Implementation

**Critical Requirement**: All generated SwiftUI code must include accessibility modifiers by default for inclusive design. Accessibility is not an afterthought - it must be built into every view from the start.

### VoiceOver Support

#### Accessibility Modifiers (Required by Default)
Every interactive element must include appropriate accessibility modifiers:

```swift
// ✅ GOOD: Comprehensive accessibility modifiers
Button(action: addItem) {
    Image(systemName: "plus")
        .font(.title)
}
.accessibilityLabel("Add new item")
.accessibilityHint("Adds a new item to your collection")
.accessibilityIdentifier("add-item-button")

// ✅ GOOD: Custom controls with full accessibility
struct CustomControl: View {
    @State private var isEnabled = true

    var body: some View {
        Toggle(isOn: $isEnabled) {
            Label("Advanced Mode", systemImage: "gear")
        }
        .accessibilityLabel("Advanced mode")
        .accessibilityHint("Toggles advanced features and settings")
        .accessibilityValue(isEnabled ? "Enabled" : "Disabled")
        .accessibilityIdentifier("advanced-mode-toggle")
    }
}

// ✅ GOOD: Complex views with grouped accessibility
VStack(spacing: 16) {
    Text("Profile Information")
        .font(.headline)

    TextField("Name", text: $name)
        .accessibilityLabel("Full name")
        .accessibilityHint("Enter your complete name")

    TextField("Email", text: $email)
        .accessibilityLabel("Email address")
        .accessibilityHint("Enter your email for account recovery")
}
.accessibilityElement(children: .combine)
.accessibilityLabel("Profile information form")
.accessibilityHint("Complete your profile details")
```

#### Accessibility Best Practices
- **Labels**: Provide meaningful, descriptive labels for all interactive elements
- **Hints**: Include contextual hints for complex interactions
- **Grouping**: Use `accessibilityElement(children: .combine)` for logical grouping
- **Order**: Ensure logical reading order with `accessibility(sortPriority:)`
- **Values**: Use `accessibilityValue()` to communicate current state
- **Identifiers**: Include `accessibilityIdentifier()` for UI testing

### Dynamic Type Support

#### Font Scaling Requirements
All text must automatically adapt to user's preferred text size:

```swift
// ✅ GOOD: Dynamic type with system fonts
struct AdaptiveTextView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.title, design: .default, weight: .bold))
                .minimumScaleFactor(0.8) // Allow slight scaling down

            Text(subtitle)
                .font(.system(.body, design: .default))
                .minimumScaleFactor(0.75)
                .lineLimit(3)
        }
    }
}

// ✅ GOOD: Custom font sizes with dynamic type
struct CustomSizedTextView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Large Title")
                .font(.system(size: 34, weight: .bold, design: .default))
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)

            Text("Body Text")
                .font(.system(size: 17, weight: .regular, design: .default))
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)

            Text("Caption")
                .font(.system(size: 12, weight: .regular, design: .default))
                .dynamicTypeSize(...DynamicTypeSize.accessibility5)
        }
    }
}
```

#### Layout Adaptation Requirements
Views must adapt their layout based on dynamic type size:

```swift
// ✅ GOOD: Adaptive layout based on type size
struct AdaptiveLayoutView: View {
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        Group {
            if typeSize >= .accessibility3 {
                // Simplified layout for very large text
                VStack(spacing: 16) {
                    titleView
                    contentView
                }
            } else if typeSize >= .large {
                // Compact layout for large text
                HStack(spacing: 12) {
                    titleView
                    contentView
                }
            } else {
                // Standard layout
                VStack(alignment: .leading, spacing: 8) {
                    titleView
                    contentView
                }
            }
        }
    }

    private var titleView: some View {
        Text("Title")
            .font(.system(.headline, design: .default))
    }

    private var contentView: some View {
        Text("Content description that provides context")
            .font(.system(.body, design: .default))
    }
}
```

### Color Scheme Adaptation (Light/Dark Mode)

#### Semantic Color Usage
Always use semantic colors that automatically adapt to light/dark mode:

```swift
// ✅ GOOD: Semantic colors for automatic adaptation
struct AdaptiveColorView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text("Primary Content")
                .foregroundColor(.primary) // Adapts to light/dark

            Text("Secondary Content")
                .foregroundColor(.secondary) // Adapts with reduced opacity

            ZStack {
                Color(.systemBackground) // Adapts to system background
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGroupedBackground)) // Adapts to grouped background
                        .frame(height: 100)
                        .overlay(
                            Text("Card Content")
                                .foregroundColor(.primary)
                        )

                    Button("Action") {
                        // Action
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue) // Semantic color
                }
                .padding()
            }
        }
    }
}

// ✅ GOOD: Custom colors with color scheme awareness
struct ColorSchemeAwareView: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 16) {
            Circle()
                .fill(colorScheme == .dark ? Color.blue.opacity(0.8) : Color.blue)
                .frame(width: 50, height: 50)

            Text(colorScheme == .dark ? "Dark Mode Active" : "Light Mode Active")
                .foregroundColor(.primary)

            // Conditional styling based on color scheme
            if colorScheme == .dark {
                Text("Dark mode specific content")
                    .foregroundColor(.white.opacity(0.9))
            } else {
                Text("Light mode specific content")
                    .foregroundColor(.black.opacity(0.8))
            }
        }
    }
}
```

### Device Trait Adaptation

#### Size Classes and Orientation
Views must adapt to different device sizes and orientations:

```swift
// ✅ GOOD: Adaptive layout for different size classes
struct AdaptiveDeviceView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                // Phone portrait/landscape or narrow layouts
                compactLayout
            } else {
                // iPad or wide layouts
                wideLayout
            }
        }
    }

    private var compactLayout: some View {
        VStack(spacing: 16) {
            Text("Compact Layout")
                .font(.title)
            contentGrid.columns(2) // 2 columns for compact
        }
    }

    private var wideLayout: some View {
        HStack(spacing: 24) {
            Text("Wide Layout")
                .font(.title)
            contentGrid.columns(4) // 4 columns for wide
        }
    }

    private var contentGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))]) {
            ForEach(0..<8) { index in
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.blue.opacity(0.3))
                    .frame(height: 100)
                    .overlay(
                        Text("Item \(index)")
                            .foregroundColor(.primary)
                    )
            }
        }
    }
}

// ✅ GOOD: Orientation-aware layout
struct OrientationAwareView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        GeometryReader { geometry in
            if geometry.size.width > geometry.size.height {
                // Landscape orientation
                landscapeLayout
            } else {
                // Portrait orientation
                portraitLayout
            }
        }
    }

    private var portraitLayout: some View {
        VStack(spacing: 20) {
            headerView
            contentView
            footerView
        }
    }

    private var landscapeLayout: some View {
        HStack(spacing: 20) {
            VStack {
                headerView
                footerView
            }
            contentView
        }
    }

    private var headerView: some View {
        Text("Header")
            .font(.title)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var contentView: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(0..<10) { index in
                    Text("Content Item \(index)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(8)
                }
            }
        }
    }

    private var footerView: some View {
        Text("Footer")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

### Motor Accessibility

#### Touch Target Requirements
Ensure all interactive elements meet minimum touch target sizes:

```swift
// ✅ GOOD: Adequate touch targets
struct AccessibleButtonView: View {
    var body: some View {
        VStack(spacing: 16) {
            // Standard button (already meets requirements)
            Button("Standard Button") {
                // Action
            }

            // Custom touch target for small elements
            HStack(spacing: 16) {
                Image(systemName: "star")
                    .foregroundColor(.yellow)
                    .frame(width: 24, height: 24) // Visual size
                    .contentShape(Rectangle()) // Extends touch area
                    .frame(width: 44, height: 44) // Minimum touch target

                // Or use padding to increase touch area
                Image(systemName: "heart")
                    .foregroundColor(.red)
                    .frame(width: 24, height: 24)
                    .padding(10) // Adds 10pt padding on all sides
                    .contentShape(Rectangle())
            }
        }
    }
}

// ✅ GOOD: List items with proper spacing
struct AccessibleListView: View {
    let items = ["Item 1", "Item 2", "Item 3"]

    var body: some View {
        List(items, id: \.self) { item in
            HStack {
                Text(item)
                    .font(.body)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle()) // Makes entire row tappable
            .padding(.vertical, 8) // Additional vertical spacing
        }
        .listStyle(.plain)
    }
}
```

- **Touch Targets**: Ensure minimum 44pt × 44pt touch targets (44×44 points)
- **Spacing**: Provide adequate spacing between interactive elements
- **Gestures**: Avoid requiring complex multi-touch gestures as primary interactions
- **Content Shapes**: Use `.contentShape(Rectangle())` to extend touch areas

### Accessibility Implementation Checklist

#### For Every View Component
- [ ] Include `.accessibilityLabel()` for all interactive elements
- [ ] Add `.accessibilityHint()` for complex interactions
- [ ] Provide `.accessibilityIdentifier()` for UI testing
- [ ] Use semantic colors (`.primary`, `.secondary`, etc.)
- [ ] Implement dynamic type with `.font(.system(...))`
- [ ] Adapt layout for different size classes
- [ ] Test with VoiceOver enabled
- [ ] Verify touch targets meet minimum size requirements
- [ ] Test with different dynamic type sizes
- [ ] Validate in both light and dark mode
- [ ] Test on different device orientations

#### Automatic Inclusion Requirements
AI-generated code must automatically include these accessibility features by default:

```swift
// Generated code template with accessibility built-in
struct GeneratedView: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "star")
                    .font(.system(.body, design: .default))
                Text(title)
                    .font(.system(.body, design: .default))
            }
            .padding()
        }
        .accessibilityLabel("\(title) button") // Automatically generated
        .accessibilityHint("Tap to \(title.lowercased())") // Context-aware hint
        .accessibilityIdentifier("generated-\(title.lowercased().replacingOccurrences(of: " ", with: "-"))-button") // For testing
        .buttonStyle(.bordered)
        .foregroundColor(.primary) // Semantic color
    }
}
```

This ensures inclusive design is built into every component from the start, rather than being added as an afterthought.

## Dynamic View Sizing with containerRelativeFrame

**Critical Requirement**: When implementing responsive modal presentations and dynamic content views, use appropriate sizing strategies that adapt to container size and content state. While `containerRelativeFrame` is the preferred modern approach, implementation must account for API complexity and provide fallback strategies.

### When to Use Dynamic Sizing

#### Optimal Use Cases for containerRelativeFrame
- **Modal presentations**: Sheets and fullScreenCover modals that need to adapt to device size
- **Sidebar components**: Navigation sidebars that should scale with window size
- **Content-aware layouts**: Views that need different sizes based on content state
- **Responsive design**: Views that adapt to different screen sizes and orientations

```swift
// ✅ CORRECT: Modal presentation with containerRelativeFrame
struct SettingsView: View {
    var body: some View {
        NavigationSplitView {
            settingsSidebar
        } detail: {
            settingsDetail
        }
        .containerRelativeFrame(.horizontal) { width, _ in
            min(max(width * 0.85, 800), 1400)
        }
        .containerRelativeFrame(.vertical) { _, height in
            min(max(height * 0.8, 500), 1000)
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// ✅ CORRECT: Sidebar with responsive width
struct NavigationSidebar: View {
    var body: some View {
        VStack {
            sidebarContent
        }
        .containerRelativeFrame(.horizontal) { width, _ in
            min(max(width * 0.3, 280), 400)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}
```

### Content-Aware Dynamic Sizing

#### Adapting Size Based on Content State
Views should adjust their size based on loading state, content availability, and user interaction:

```swift
// ✅ CORRECT: Content-aware modal sizing
struct AISuggestionsView: View {
    let suggestions: [String]
    let isLoading: Bool
    let error: Error?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()

            if isLoading {
                loadingStateView
            } else if suggestions.isEmpty {
                emptyStateView
            } else {
                suggestionsContent
            }

            Divider()
            actionButtons
        }
        .containerRelativeFrame(.horizontal) { width, _ in
            min(max(width * 0.8, 700), 1200)
        }
        .containerRelativeFrame(.vertical) { _, height in
            let minHeight: CGFloat = isLoading ? 400 : (suggestions.isEmpty ? 500 : 600)
            let idealHeight: CGFloat = suggestions.isEmpty && !isLoading ? 600 : 800
            return min(max(height * 0.7, minHeight), min(idealHeight, 1000))
        }
        .background(Color(NSColor.windowBackgroundColor))
        .presentationCompactAdaptation(.none)
        .presentationBackground(.regularMaterial)
    }
}
```

### containerRelativeFrame Implementation Guidelines

#### Best Practices for Safe Implementation
1. **Always provide fallback minimums**: Ensure views have minimum usable sizes
2. **Set reasonable maximums**: Prevent views from becoming too large on large screens
3. **Use percentage-based scaling**: Scale relative to container size for responsiveness
4. **Test across device sizes**: Verify behavior on different screen sizes

```swift
// ✅ CORRECT: Safe containerRelativeFrame implementation
.containerRelativeFrame(.horizontal) { width, _ in
    min(max(width * 0.6, 500), 800)  // 60% of width, min 500pt, max 800pt
}
.containerRelativeFrame(.vertical) { _, height in
    min(max(height * 0.7, 400), 600)  // 70% of height, min 400pt, max 600pt
}
```

#### Parameter Types and Error Prevention
The `containerRelativeFrame` API has specific parameter type expectations that must be handled carefully:

```swift
// ⚠️ POTENTIAL ISSUE: Parameter type complexity
// The .vertical variant expects (CGFloat, Axis) -> CGFloat parameters
// This can cause compilation errors in complex scenarios

// ✅ SAFE APPROACH: Use explicit type annotations when needed
.containerRelativeFrame(.vertical) { (width: CGFloat, height: CGFloat) in
    max(height * 0.4, 300)
}

// ✅ ALTERNATIVE: Use underscore for unused parameters
.containerRelativeFrame(.vertical) { _, height in
    max(height * 0.4, 300)
}
```

### Fallback Strategy: Fixed Frame Sizing

#### When containerRelativeFrame Is Not Suitable
In cases where `containerRelativeFrame` causes implementation complexity or compilation issues, use comprehensive fixed frame sizing:

```swift
// ✅ ACCEPTABLE FALLBACK: Fixed frame with comprehensive sizing
struct ModalView: View {
    let hasLongContent: Bool

    var body: some View {
        VStack {
            modalContent
        }
        .frame(
            minWidth: 700,
            idealWidth: hasLongContent ? 900 : 800,
            maxWidth: 1200,
            minHeight: 400,
            idealHeight: hasLongContent ? 600 : 500,
            maxHeight: 1000
        )
        .background(Color(NSColor.windowBackgroundColor))
        .presentationCompactAdaptation(.none)
    }
}

// ✅ CORRECT: Content-aware fixed sizing
struct ResponsiveContentView: View {
    @State private var contentSize: ContentSize = .medium

    enum ContentSize {
        case small, medium, large

        var frameSize: (width: (min: CGFloat, ideal: CGFloat, max: CGFloat),
                       height: (min: CGFloat, ideal: CGFloat, max: CGFloat)) {
            switch self {
            case .small:
                return (width: (min: 500, ideal: 600, max: 700),
                       height: (min: 300, ideal: 400, max: 500))
            case .medium:
                return (width: (min: 600, ideal: 750, max: 900),
                       height: (min: 400, ideal: 550, max: 700))
            case .large:
                return (width: (min: 700, ideal: 900, max: 1200),
                       height: (min: 500, ideal: 700, max: 1000))
            }
        }
    }

    var body: some View {
        VStack {
            content
        }
        .frame(
            minWidth: contentSize.frameSize.width.min,
            idealWidth: contentSize.frameSize.width.ideal,
            maxWidth: contentSize.frameSize.width.max,
            minHeight: contentSize.frameSize.height.min,
            idealHeight: contentSize.frameSize.height.ideal,
            maxHeight: contentSize.frameSize.height.max
        )
    }
}
```

### Responsive Layout Patterns

#### Adaptive Sidebar Layouts
For complex layouts with multiple panels, combine responsive sizing techniques:

```swift
// ✅ CORRECT: Adaptive split view layout
struct AdaptiveSplitView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        NavigationSplitView {
            SidebarView()
                .containerRelativeFrame(.horizontal) { width, _ in
                    // Adaptive sidebar width based on available space
                    let sidebarRatio: CGFloat = horizontalSizeClass == .compact ? 0.4 : 0.25
                    return min(max(width * sidebarRatio, 200), 350)
                }
        } detail: {
            DetailView()
                .containerRelativeFrame(.horizontal) { width, _ in
                    // Detail view takes remaining space with minimum
                    let detailRatio: CGFloat = horizontalSizeClass == .compact ? 0.6 : 0.75
                    return max(width * detailRatio, 400)
                }
        }
    }
}
```

#### Content Section Responsive Heights
For content sections within scrollable views, use responsive heights:

```swift
// ✅ CORRECT: Responsive content section heights
struct SpecificationSectionView: View {
    let sectionType: SectionType

    enum SectionType {
        case brief, standard, detailed

        var heightMultiplier: CGFloat {
            switch self {
            case .brief: return 0.15
            case .standard: return 0.25
            case .detailed: return 0.4
            }
        }
    }

    var body: some View {
        VStack {
            sectionContent
        }
        .containerRelativeFrame(.vertical) { _, height in
            max(height * sectionType.heightMultiplier, 150)
        }
    }
}
```

### Testing Dynamic Sizing

#### Validation Requirements
All dynamic sizing implementations must be tested across:

```swift
// ✅ TESTING CHECKLIST for Dynamic Sizing
// 1. Different device sizes (iPhone, iPad, Mac)
// 2. Various content states (loading, empty, populated)
// 3. Different window sizes on macOS
// 4. Accessibility text sizes
// 5. Landscape and portrait orientations

#Preview("Responsive Modal - Various States") {
    VStack(spacing: 20) {
        // Test different content states
        ModalView(contentState: .loading)
        ModalView(contentState: .empty)
        ModalView(contentState: .populated)
    }
}

#Preview("Responsive Modal - Different Sizes") {
    HStack(spacing: 20) {
        // Test different container sizes
        ModalView()
            .frame(width: 800, height: 600)
        ModalView()
            .frame(width: 1200, height: 800)
    }
}
```

### AI Code Generation Guidelines

#### Automatic Sizing Strategy Selection
AI-generated code should follow this decision hierarchy:

1. **Primary Choice**: Use `containerRelativeFrame` for modal presentations and responsive layouts
2. **Fallback Choice**: Use comprehensive `frame` modifiers when `containerRelativeFrame` causes complexity
3. **Content Awareness**: Always adapt sizing based on content state (loading, empty, populated)
4. **Minimum Sizes**: Always specify minimum usable sizes for all views
5. **Maximum Limits**: Set reasonable maximum sizes to prevent oversized views

```swift
// ✅ AI GENERATION TEMPLATE: Dynamic modal with fallback
struct AIGeneratedModal: View {
    let contentState: ContentState

    var body: some View {
        VStack(spacing: 0) {
            modalHeader
            Divider()
            modalContent
            Divider()
            modalActions
        }
        // Primary approach: containerRelativeFrame
        .containerRelativeFrame(.horizontal) { width, _ in
            min(max(width * 0.7, 600), 1000)
        }
        .containerRelativeFrame(.vertical) { _, height in
            let minHeight = contentState.minimumHeight
            let idealHeight = contentState.idealHeight
            return min(max(height * 0.6, minHeight), idealHeight)
        }
        // Fallback: If containerRelativeFrame fails, use:
        // .frame(minWidth: 600, idealWidth: 800, maxWidth: 1000,
        //        minHeight: contentState.minimumHeight,
        //        idealHeight: contentState.idealHeight,
        //        maxHeight: contentState.maximumHeight)
        .background(Color(NSColor.windowBackgroundColor))
        .presentationCompactAdaptation(.none)
    }
}
```

This comprehensive approach ensures responsive, content-aware sizing while providing reliable fallback strategies when the modern APIs present implementation challenges.

## Performance Optimization

### Lazy Loading for Lists
- **LazyVStack**: Use for vertical scrolling lists with many items to prevent upfront rendering
- **LazyHStack**: Use for horizontal scrolling lists with many items to prevent upfront rendering
- **LazyVGrid**: Use for grid layouts with many items to prevent upfront rendering
- **Automatic Detection**: AI should identify dynamic/long content (>10 items) and default to lazy variants
- **Memory Efficiency**: Only renders visible items plus buffer, reducing memory usage
- **Scroll Performance**: Smooth scrolling even with hundreds of items

### Rendering Performance
- **View Updates**: Minimize unnecessary view updates with proper state management
- **View Identity**: Use proper id parameters for stable view identities
- **State Observation**: Be mindful of observation overhead with @ObservedObject

### Animation Guidelines
- **System Animations**: Use .animation(.default, value: ...) for consistent timing
- **Purposeful Motion**: Apply animations only where they enhance user experience
- **Performance**: Avoid complex animations that impact 60fps target
- **Accessibility**: Respect reduced motion preferences

## Testing Requirements for SwiftUI

**Note**: This section focuses on **SwiftUI-specific testing requirements**. For comprehensive Swift testing patterns, unit testing frameworks, and testing methodologies, refer to SwiftTestingSpec.md.

### SwiftUI-Specific Unit Testing
- **View State**: Test SwiftUI view state management (@State, computed properties, business logic)
- **View Logic**: Test computed properties and view state transformations directly
- **Environment Integration**: Test @Environment and @EnvironmentObject usage
- **Accessibility Modifiers**: Verify accessibility labels, hints, and identifiers are set
- **Navigation State**: Test NavigationStack path management and state transitions

### SwiftUI-Specific UI Testing
- **SwiftUI View Testing**: Test view hierarchies, modifiers, and state changes
- **Accessibility Testing**: Verify VoiceOver navigation, Dynamic Type adaptation, and touch targets
- **Navigation Testing**: Test NavigationStack deep linking and programmatic navigation
- **Layout Testing**: Verify responsive layouts across size classes and orientations
- **Animation Testing**: Test SwiftUI animations and transitions

### Accessibility Validation Testing
```swift
// ✅ GOOD: Accessibility-focused UI tests
class SwiftUIAccessibilityTests: XCTestCase {
    func testAccessibilityLabels() throws {
        let app = XCUIApplication()
        app.launch()

        // Test that all interactive elements have accessibility labels
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            XCTAssertFalse(button.label.isEmpty, "Button should have accessibility label")
        }
    }

    func testDynamicTypeSupport() throws {
        let app = XCUIApplication()
        app.launch()

        // Test that content adapts to different text sizes
        // This would require setting up different dynamic type sizes
        XCTAssertTrue(app.staticTexts.firstMatch.exists)
    }

    func testTouchTargets() throws {
        let app = XCUIApplication()
        app.launch()

        // Test minimum touch target sizes (44x44 points)
        // This would require measuring element frames
        let buttons = app.buttons.allElementsBoundByIndex
        for button in buttons {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Touch target width should be at least 44pt")
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Touch target height should be at least 44pt")
        }
    }
}
```

### Layout and Responsiveness Testing
```swift
// ✅ GOOD: Layout testing across size classes
class SwiftUILayoutTests: XCTestCase {
    func testCompactLayout() throws {
        let app = XCUIApplication()
        app.launch()

        // Force compact horizontal size class
        XCUIDevice.shared.orientation = .portrait

        // Test layout adapts appropriately
        XCTAssertTrue(app.collectionViews.firstMatch.exists)
    }

    func testRegularLayout() throws {
        let app = XCUIApplication()
        app.launch()

        // Force regular horizontal size class (iPad)
        // Test layout adapts to wider screens
        XCTAssertTrue(app.splitViews.firstMatch.exists)
    }
}
```

### Navigation Testing
```swift
// ✅ GOOD: Navigation flow testing
class SwiftUINavigationTests: XCTestCase {
    func testNavigationStackDeepLinking() throws {
        let app = XCUIApplication()
        // Launch with deep link URL
        app.launch(with: ["url": "myapp://content?id=123"])

        // Verify navigation occurred
        XCTAssertTrue(app.navigationBars["Content Detail"].waitForExistence(timeout: 5))
    }

    func testProgrammaticNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        // Trigger navigation
        app.buttons["navigate-button"].tap()

        // Verify navigation state
        XCTAssertTrue(app.navigationBars["Detail View"].exists)
    }
}
```

### Performance Testing for SwiftUI
- **View Update Performance**: Measure time for view updates and state changes
- **Lazy Loading Verification**: Ensure LazyVStack/HStack/VGrid only load visible content
- **Animation Performance**: Test 60fps animation performance
- **Memory Usage**: Monitor view hierarchy memory usage with large datasets

## Migration from MVVM to SwiftUI-Native Patterns

This section provides guidance for teams transitioning from traditional MVVM patterns to SwiftUI-native state management approaches.

### When to Use Traditional ViewModels
While SwiftUIWithoutMVVM.md argues that ViewModels are generally unnecessary, these scenarios might still benefit from ViewModel classes:

- **Cross-platform shared logic** requiring different implementations per platform
- **Legacy code integration** during gradual migration
- **Heavy computation isolation** that needs to run completely off the main thread
- **Complex state coordination** across multiple unrelated views

### When to Use SwiftUI-Native Patterns
For most SwiftUI development, prefer direct state management:

- **Standard iOS/macOS app development** with typical UI complexity
- **Business logic naturally belonging to UI state** (sorting, filtering, validation)
- **Simple to complex view hierarchies** with local state management
- **Data presentation and user interaction flows**

### Migration Strategy

#### Step 1: Identify ViewModel Responsibilities
Analyze existing ViewModels and categorize their responsibilities:

- **Data fetching** → Move to `@StateObject` or view methods
- **Business logic** → Move to computed properties or private view methods
- **State management** → Use SwiftUI's built-in `@State`, `@StateObject`, `@EnvironmentObject`
- **User interactions** → Handle directly in view closures with `Task { }`

#### Step 2: Convert Simple ViewModels
Start with ViewModels that only manage local view state:

```swift
// BEFORE: Traditional MVVM
class SearchViewModel: ObservableObject {
    @Published var query = ""
    @Published var results: [SearchResult] = []
    @Published var isSearching = false

    func performSearch() async {
        isSearching = true
        results = await searchService.search(query: query)
        isSearching = false
    }
}

struct SearchView: View {
    @StateObject var viewModel = SearchViewModel()
    // ...
}

// AFTER: SwiftUI-native
struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        // Direct state usage without ViewModel
        TextField("Search", text: $query)
            .onSubmit {
                Task { await performSearch() }
            }
        // ...
    }

    private func performSearch() async {
        isSearching = true
        results = await searchService.search(query: query)
        isSearching = false
    }
}
```

#### Step 3: Handle Complex State
For complex ViewModels, break them down into focused state objects:

```swift
// BEFORE: Monolithic ViewModel
class ComplexViewModel: ObservableObject {
    @Published var user: User?
    @Published var posts: [Post] = []
    @Published var comments: [Comment] = []
    @Published var isLoading = false
    // Many responsibilities...
}

// AFTER: Focused state management
struct UserProfileView: View {
    @StateObject private var userStore = UserStore()
    @StateObject private var postsStore = PostsStore()
    @StateObject private var commentsStore = CommentsStore()

    var body: some View {
        // Each store handles one concern
        UserHeader(user: userStore.user)
        PostsList(posts: postsStore.posts, comments: commentsStore.comments)
    }
}
```

#### Step 4: Update Testing Approach
Shift from ViewModel testing to direct view state testing:

```swift
// BEFORE: ViewModel testing
func testViewModelSearch() async {
    let viewModel = SearchViewModel()
    await viewModel.performSearch(query: "test")
    #expect(viewModel.results.count > 0)
}

// AFTER: View state testing
struct SearchViewTests {
    @Test func testSearchFunctionality() async {
        // Test view directly, no ViewModel abstraction
        let view = SearchView()
        // Test state changes and UI updates directly
    }
}
```

### Benefits of Migration

- **Reduced boilerplate**: No ObservableObject conformance for simple cases
- **Better type safety**: SwiftUI's property wrappers provide compile-time guarantees
- **Easier testing**: Test views directly without mocking protocols
- **Better performance**: Direct data flow without intermediary objects
- **Simplified debugging**: Clear state flow through SwiftUI's system

### Gradual Migration Approach

1. **New features**: Use SwiftUI-native patterns immediately
2. **Refactoring**: Convert existing ViewModels incrementally
3. **Testing**: Update tests as you migrate
4. **Documentation**: Reference SwiftUIWithoutMVVM.md for architectural decisions

This migration guidance ensures teams can transition smoothly while maintaining code quality and leveraging SwiftUI's architectural advantages.

This specification provides comprehensive guidance for implementing SwiftUI user interfaces that are performant, accessible, and maintainable. All SwiftUI implementations must adhere to these standards for optimal user experience and code quality.
