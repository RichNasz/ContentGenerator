# Swift Technical Specifications

## Purpose
This document provides Swift-specific implementation guidance for functionality defined in FunctionalSpecs.md. It contains code signatures, architectural patterns, and SwiftData model definitions - NOT complete implementations.

**Swift 6 + Default MainActor Context**: This project uses Swift 6 with default actor isolation set to MainActor, which significantly impacts concurrency patterns and class design.

## Architecture Patterns

### Architecture Foundation
This project follows patterns defined in the CommonSpecs for consistency and reusability:

- **Swift 6 Concurrency**: See [SwiftCodeGeneration.md](../../../CommonSpecs/SwiftCodeGeneration.md#swift-6-concurrency-with-default-mainactor-isolation) for comprehensive concurrency patterns
- **SwiftUI State Management**: See [SwiftUIWithoutMVVM.md](../../../CommonSpecs/SwiftUIWithoutMVVM.md) for @Observable patterns and ViewModel-free architecture
- **SwiftData Integration**: See [SwiftDataPatterns.md](../../../CommonSpecs/SwiftDataPatterns.md) for universal data layer patterns
- **Navigation Patterns**: See [NavigationPatterns.md](../../../CommonSpecs/NavigationPatterns.md) for reusable navigation architectures

## View Architecture (Swift 6 + Default MainActor)

### Application Window Structure
- **Single Window Application:** All functionality contained within one main window
- **NavigationSplitView Architecture:** Two-column layout with sidebar and detail content area

### CRITICAL: NavigationSplitView Pattern Requirements

**MANDATORY**: All NavigationSplitView implementations MUST use value-based NavigationLink with enum destinations. This is SwiftUI's recommended pattern and prevents navigation state corruption.

**Why This Matters**:
- Mixing Button-based and NavigationLink-based navigation causes state conflicts
- Manual selection state management breaks after NavigationLink transitions
- SwiftUI manages navigation state automatically with value-based NavigationLink
- Enum-driven navigation provides type safety and prevents invalid states

### Main Application Window Pattern (REQUIRED)
```swift
// Navigation destination enum - REQUIRED for type-safe navigation
enum NavigationDestination: Hashable {
    case project(ContentProject)
    case llmConnections
    case applicationSettings
    // Add other destinations as needed
}

// Main application window with value-based NavigationSplitView
struct ContentView: View {
    @Query(sort: \ContentProject.modifiedAt, order: .reverse)
    private var projects: [ContentProject]

    // REQUIRED: Selection state for NavigationSplitView
    @State private var selectedDestination: NavigationDestination?

    var body: some View {
        NavigationSplitView {
            // Sidebar - List with selection binding and NavigationLink values
            List(selection: $selectedDestination) {
                Section("Projects") {
                    ForEach(projects) { project in
                        NavigationLink(value: NavigationDestination.project(project)) {
                            ProjectSidebarRow(project: project)
                        }
                    }
                }

                Section("Settings") {
                    NavigationLink("LLM Connections", value: NavigationDestination.llmConnections)
                    NavigationLink("Application Settings", value: NavigationDestination.applicationSettings)
                }
            }
        } detail: {
            // Detail section switches on selection state
            if let destination = selectedDestination {
                switch destination {
                case .project(let project):
                    ProjectContentView(project: project)
                case .llmConnections:
                    LLMConnectionListView(modelContext: dataManager.createContext())
                case .applicationSettings:
                    ApplicationSettingsView()
                }
            } else {
                ContentUnavailableView(
                    "No Selection",
                    systemImage: "sidebar.left",
                    description: Text("Select a project or settings from the sidebar")
                )
            }
        }
    }
}
```

**CRITICAL DIFFERENCES from NavigationStack**:
- List(selection:) binding is REQUIRED
- Detail section switches on selection state directly
- NO .navigationDestination(for:) modifier (that's for NavigationStack only!)
- @State var selectedDestination is needed for detail routing

### Anti-Patterns (DO NOT USE)

#### Anti-Pattern 1: Using .navigationDestination with NavigationSplitView
```swift
// WRONG: .navigationDestination is for NavigationStack, NOT NavigationSplitView!
NavigationSplitView {
    List {
        NavigationLink("Item", value: item)
    }
} detail: {
    ContentUnavailableView("No Selection")  // Static view
}
.navigationDestination(for: Item.self) { item in  // WRONG API
    DetailView(item: item)  // This will NEVER show!
}
```

#### Anti-Pattern 2: Mixed Button and NavigationLink Navigation
```swift
// WRONG: Mixing Button-based and NavigationLink-based navigation
struct BadSidebar: View {
    @State private var selectedProject: ContentProject?  // Manual state

    var body: some View {
        List {
            ForEach(projects) { project in
                Button {  // Button-based navigation
                    selectedProject = project
                } label: {
                    Text(project.name)
                }
            }

            NavigationLink("Settings") {  // Mixed with NavigationLink
                SettingsView()
            }
        }
    }
}
// This causes navigation to break after using NavigationLink!
```

#### Anti-Pattern 3: Missing List Selection Binding
```swift
// WRONG: NavigationLink without List selection binding
NavigationSplitView {
    List {  // No selection: binding
        NavigationLink(value: item) {
            Text(item.name)
        }
    }
} detail: {
    if let selection = ??? {  // Where does selection come from?
        DetailView(selection)
    }
}
```

### Navigation Structure Requirements
- **Value-Based NavigationLink**: MANDATORY - All sidebar items must use NavigationLink with enum values
- **List Selection Binding**: REQUIRED - List(selection:) must bind to selection state
- **Detail Switches on Selection**: Detail section must switch on selectedDestination
- **No .navigationDestination**: This modifier is for NavigationStack, NOT NavigationSplitView
- **Hashable Destinations**: All destination types must conform to Hashable
- **Type Safety**: Enum ensures only valid destinations are possible

### Navigation Destination Enum Pattern
```swift
// REQUIRED: Define all possible navigation destinations
enum NavigationDestination: Hashable {
    case project(ContentProject)  // ContentProject must be Hashable
    case llmConnections
    case applicationSettings
    // Add more destinations as needed

    // Hashable conformance automatic for enums with Hashable associated values
}

// For @Model types, ensure Hashable conformance
extension ContentProject: Hashable {
    nonisolated public static func == (lhs: ContentProject, rhs: ContentProject) -> Bool {
        lhs.id == rhs.id
    }

    nonisolated public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
// Note: SwiftData's @Model macro provides Hashable automatically in many cases
```

### NavigationSplitView Implementation Checklist
- [ ] NavigationDestination enum defined with all destinations
- [ ] All model types used in enum conform to Hashable
- [ ] @State var selectedDestination declared in view
- [ ] List(selection: $selectedDestination) binding present
- [ ] Sidebar items use NavigationLink(value:) exclusively
- [ ] Detail section switches on selectedDestination with if-let
- [ ] NO .navigationDestination(for:) modifier (that's for NavigationStack!)
- [ ] No Button-based navigation mixed with NavigationLink

### State Management Pattern (Direct @State/@Bindable)

This project does **not** use ViewModels. Views manage state directly using SwiftUI property wrappers:

```swift
// Views use direct state management - no ViewModel layer
struct ProjectDetailView: View {
    @Bindable var project: ContentProject
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var specificationSections: [SpecificationSectionData] = []
    @State private var draggingSectionId: UUID?

    var body: some View {
        // View body uses @Bindable for two-way binding to model properties
        // and @State for local UI state
    }
}

struct SomeListView: View {
    @State private var items: [SomeModel] = []
    @State private var searchText = ""
    @State private var showingDeleteConfirmation = false

    // Data fetched via ModelContext, not through a ViewModel
    private func loadItems() {
        let context = modelContext
        let descriptor = FetchDescriptor<SomeModel>()
        items = (try? context.fetch(descriptor)) ?? []
    }
}
```

### Service Layer Patterns

#### ProjectDataManager
```swift
// Manages the SwiftData ModelContainer for the application
@MainActor
@Observable
final class ProjectDataManager {
    private let container: ModelContainer

    init(bundleURL: URL) throws {
        // Creates ModelContainer with all app models, stored within the bundle
        container = try ModelContainer(
            for: Schema([
                ContentProject.self,
                ContentSpecification.self,
                SpecificationSection.self,
                GeneratedContentData.self,
                FileAttachment.self,
                ApplicationSettings.self,
                LLMConnection.self   // From LLMmanagement package
            ]),
            configurations: ModelConfiguration(url: bundleURL.appending(path: "swiftdata/Application.store"))
        )
    }

    func getContainer() -> ModelContainer {
        return container
    }

    func createContext() -> ModelContext {
        return ModelContext(container)
    }
}
```

#### GlobalSettingsService
```swift
// Settings service that operates independently of projects
@MainActor
@Observable
final class GlobalSettingsService {
    private let dataManager: ProjectDataManager

    init(dataManager: ProjectDataManager) {
        self.dataManager = dataManager
    }

    func getSettings() async throws -> ApplicationSettings {
        let context = dataManager.createContext()
        let descriptor = FetchDescriptor<ApplicationSettings>()
        let settings = try context.fetch(descriptor)
        return settings.first ?? ApplicationSettings.defaultSettings()
    }

    func updateSettings(_ settings: ApplicationSettings) async throws {
        let context = dataManager.createContext()
        settings.modifiedAt = Date()
        try context.save()
    }
}
```

#### BundleManager Pattern
```swift
// Manages bundle creation, opening, and restoration
@MainActor
@Observable
final class BundleManager {
    var bundleState: BundleState = .noBundleSelected

    enum BundleState {
        case noBundleSelected
        case loading
        case ready(URL)
        case error(String)
    }

    func createNewBundle() { /* ... */ }
    func openExistingBundle() { /* ... */ }
    func restoreSavedBundle() { /* ... */ }
}
```

### File Attachment Service Pattern

The `FileAttachmentManager` handles file attachments with security-scoped bookmark support for macOS sandbox compliance.

**Architecture Pattern:**
- Uses `@MainActor` and `@Observable` for UI integration
- Depends on `ProjectDataManager` for persistence
- Manages security-scoped bookmark creation and resolution
- Handles file access in sandboxed environment

**Security-Scoped Bookmark Pattern:**
- Bookmarks created when files are attached (user-granted access)
- Bookmarks resolved to URLs when file content is needed
- `startAccessingSecurityScopedResource()` called before file access
- `stopAccessingSecurityScopedResource()` called when access complete
- Bookmarks are app-specific and machine-specific (not portable)

### Project Import/Export Service Pattern

The `ProjectExportService` handles project import and export operations, following the established service patterns used by `GlobalSettingsService` and `FileAttachmentManager`.

**Architecture Pattern:**
- Uses `@MainActor` and `@Observable` for UI integration
- Depends on `ProjectDataManager` and `FileAttachmentManager`
- Leverages the `ProjectExchange` package for portable Codable transfer objects
- Transfer objects are independent of SwiftData for cross-application portability

**Import Flow Pattern:**
1. Preview import first (parse JSON without database commit)
2. Check for LLM connection conflicts by case-insensitive name matching
3. Present conflict resolution UI if match found
4. Complete import with user's chosen resolution
5. Return result containing new project, connection ID, and warnings list

**Conflict Resolution Options:**
- `skip`: Use existing connection, ignore imported configuration
- `useExisting`: Link project to existing connection without updates
- `overwriteExisting`: Update existing connection with imported values (preserves API key)
- `createNew`: Create new connection with "(Imported)" suffix appended to name

**Security Considerations:**
- API keys are never included in exports
- Security-scoped bookmark data is not portable and is excluded
- File contents are not embedded; only metadata (path, name, size) is exported

**UI Integration Points:**
- Export: Action menu in `ProjectDetailView` with `NSSavePanel` for file selection
- Import: Sidebar header button in `ContentView` with `NSOpenPanel` for file selection
- Conflict Resolution: `LLMConnectionConflictSheet` presents side-by-side comparison
- Post-import alerts display warnings (e.g., files need re-attachment, API key needed)

### Content Generation Window Patterns

The application uses dedicated windows for content generation workflows, separate from the main application window.

**ProjectContentGenerationWindow:**
- Standalone window for project-level content generation
- Three-column layout: project overview, LLM controls, generated content
- Manages window state independently from main app via `ProjectContentGenerationWindowState`

**SectionContentGenerationWindow:**
- Focused window for single-section content generation
- Three-column layout: current content, LLM controls/prompts, generated content
- Includes prompt export (copy to clipboard, save to .md file)

**Window State Management Pattern:**
- Use `@Observable` classes for window state (e.g., `ContentGenerationWindowState`)
- State includes: target project/section, LLM connection, generation status, result
- Window state passed via environment for view access
- Use `@Environment(\.openWindow)` to launch generation windows
- Window scenes registered in app definition with appropriate identifiers

### LLM Integration Patterns

#### OpenAI Endpoint Type
The LLMmanagement package defines `OpenAIEndpointType` with two cases:
```swift
enum OpenAIEndpointType: String, CaseIterable, Codable {
    case chatCompletions = "chat_completions"
    case responses = "responses"

    var defaultPath: String { /* ... */ }
    var displayName: String { /* ... */ }
}
```

#### LLM Connection Model (from LLMmanagement package)
The `LLMConnection` model lives in the LLMmanagement package and is a SwiftData `@Model`:
```swift
@Model
final class LLMConnection {
    @Attribute(.unique) var id: UUID
    var name: String
    var baseUrl: String
    var urlPath: String?
    var endpointType: OpenAIEndpointType
    var apiKey: String
    var selectedModel: String
    var requestTimeoutSeconds: Int  // Clamped 60-600
    var createdAt: Date
    var lastUsed: Date

    var fullApiUrl: String { /* combines baseUrl + urlPath or endpointType.defaultPath */ }
    var isConfigured: Bool { /* validates URL format and model selection */ }

    // Copy initializer for updates preserving identity
    init(updatingFrom original: LLMConnection, ...) { /* ... */ }
}
```

## Error Handling Patterns

### Error Handling Foundation
Error handling follows patterns defined in [SwiftCodeGeneration.md](../../../CommonSpecs/SwiftCodeGeneration.md#error-types-with-sendable) for Sendable conformance and proper actor isolation.

### ContentGenerator-Specific Error Types
```swift
enum ContentGeneratorError: LocalizedError, Sendable {
    case aiServiceUnavailable
    case invalidContentRequest(String)
    case contentGenerationFailed(String)
    case projectIsolationViolation
    case projectNotFound(UUID)
    case specificationRequired(String)
    case settingsAccessError
    case llmConnectionFailed(String)
    case llmConfigurationInvalid(String)
    case noLLMConnectionsAvailable
    case chatCompletionsAPIError(String)
    case chatCompletionsConfigurationMissing
    case swiftChatCompletionsDSLError(String)

    var errorDescription: String? { /* ... */ }
    var failureReason: String? { /* ... */ }
    var recoverySuggestion: String? { /* ... */ }
}
```

### Error Presentation and Recovery
Error presentation and recovery patterns follow the universal patterns defined in [SwiftUIWithoutMVVM.md](../../../CommonSpecs/SwiftUIWithoutMVVM.md) using @State for error state management in views.

## Testing Patterns

### Testing Foundation
Testing follows the universal patterns defined in [SwiftTestingSpec.md](../../../CommonSpecs/SwiftTestingSpec.md) for Swift 6 + Default MainActor projects. Background services use nonisolated testing patterns.

### ContentGenerator-Specific Testing
Testing focuses on project-specific functionality:
- Project data isolation verification
- Content generation workflow testing
- AI service integration testing
- Settings persistence across project contexts

## ContentGenerator SwiftData Implementation

### Foundation
ContentGenerator uses the universal SwiftData patterns defined in [SwiftDataPatterns.md](../../../CommonSpecs/SwiftDataPatterns.md) as the foundation for all data models and implements project-specific data isolation requirements.

### Project-Specific Model Definitions
```swift
@Model
final class ContentProject: PersistentModel {
    var id: UUID
    var name: String
    var projectDescription: String?
    var systemPrompt: String?
    var llmConnectionId: UUID?
    var createdAt: Date
    var modifiedAt: Date
    var status: ProjectStatus

    // Proper relationship syntax (prevents ERR-DATA-001)
    @Relationship(deleteRule: .cascade, inverse: \ContentSpecification.project)
    var specification: ContentSpecification?

    @Relationship(deleteRule: .cascade)
    var generatedContent: [GeneratedContentData]

    @Relationship(deleteRule: .cascade)
    var attachments: [FileAttachment]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.status = .active
        self.generatedContent = []
        self.attachments = []
    }

    // Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class SpecificationSection: PersistentModel {
    var id: UUID
    var name: String
    var sectionDescription: String?       // Optional description for organizational clarity
    var content: String
    var orderIndex: Int
    var contentGenerationPrompt: String?  // Prompt for AI-assisted section content generation
    var contentUsagePrompt: String?       // Prompt for how section content should be applied
    var isEnabled: Bool                   // Include/exclude from generation
    var assistantLLMConnectionId: UUID?   // Section-level LLM assistant connection
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to specification
    var specification: ContentSpecification?

    init(name: String, content: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.sectionDescription = nil
        self.content = content
        self.orderIndex = orderIndex
        self.contentGenerationPrompt = nil
        self.contentUsagePrompt = nil
        self.isEnabled = true
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class ContentSpecification: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to project (prevents ERR-DATA-001)
    var project: ContentProject?

    // One-to-many relationship with sections
    @Relationship(deleteRule: .cascade, inverse: \SpecificationSection.specification)
    var sections: [SpecificationSection]

    init() {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.sections = []
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }

    // Convenience methods for section management
    func addSection(name: String, content: String) -> SpecificationSection {
        let newSection = SpecificationSection(
            name: name,
            content: content,
            orderIndex: sections.count
        )
        newSection.specification = self
        sections.append(newSection)
        updateModifiedDate()
        return newSection
    }
}

@Model
final class GeneratedContentData: PersistentModel {
    var id: UUID
    var text: String                      // The generated content text
    var metadataJSON: String?             // Flexible metadata stored as JSON
    var llmConnectionId: UUID?            // Reference to the LLM connection used
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to project
    var project: ContentProject?

    init(text: String, metadata: [String: Any]? = nil, llmConnectionId: UUID? = nil) {
        self.id = UUID()
        self.text = text
        self.llmConnectionId = llmConnectionId
        self.createdAt = Date()
        self.modifiedAt = Date()

        // Serialize metadata to JSON
        if let metadata = metadata {
            self.metadataJSON = try? String(
                data: JSONSerialization.data(withJSONObject: metadata),
                encoding: .utf8
            )
        }
    }

    // Computed property for metadata access
    var metadata: [String: Any]? {
        get {
            guard let json = metadataJSON,
                  let data = json.data(using: .utf8) else { return nil }
            return try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        }
        set {
            if let value = newValue {
                metadataJSON = try? String(
                    data: JSONSerialization.data(withJSONObject: value),
                    encoding: .utf8
                )
            } else {
                metadataJSON = nil
            }
            modifiedAt = Date()
        }
    }
}

@Model
final class FileAttachment: PersistentModel {
    var id: UUID
    var originalFileName: String          // Original file name when attached
    var fileExtension: String?            // File extension (e.g., "txt", "md")
    var fileSizeBytes: Int64              // File size in bytes
    var securityScopedBookmarkData: Data? // Security-scoped bookmark for sandbox access
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to project
    var project: ContentProject?

    init(originalFileName: String, fileExtension: String?, fileSizeBytes: Int64) {
        self.id = UUID()
        self.originalFileName = originalFileName
        self.fileExtension = fileExtension
        self.fileSizeBytes = fileSizeBytes
        self.createdAt = Date()
        self.modifiedAt = Date()
    }
}
```

### Application Settings Model
```swift
@Model
final class ApplicationSettings {
    var id: UUID
    var aiServiceEndpoint: String
    var aiServiceAPIKey: String
    var appearanceTheme: AppearanceTheme
    var autoSaveEnabled: Bool
    var dataBackupLocation: String?
    var createdAt: Date
    var modifiedAt: Date

    init(
        aiServiceEndpoint: String = "",
        aiServiceAPIKey: String = "",
        appearanceTheme: AppearanceTheme = .system,
        autoSaveEnabled: Bool = true,
        dataBackupLocation: String? = nil
    ) {
        self.id = UUID()
        self.aiServiceEndpoint = aiServiceEndpoint
        self.aiServiceAPIKey = aiServiceAPIKey
        self.appearanceTheme = appearanceTheme
        self.autoSaveEnabled = autoSaveEnabled
        self.dataBackupLocation = dataBackupLocation
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    static func defaultSettings() -> ApplicationSettings {
        return ApplicationSettings()
    }
}

enum AppearanceTheme: String, CaseIterable, Codable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}
```

### Enum Support (String-Backed for SwiftData)
```swift
enum ProjectStatus: String, CaseIterable, Codable, Sendable {
    case draft = "draft"
    case active = "active"
    case generating = "generating"
    case completed = "completed"

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .generating: return "Generating..."
        case .completed: return "Completed"
        }
    }
}
```

## SwiftUI Layout Best Practices

### Layout Architecture Principles

#### Container vs Content Responsibility
SwiftUI follows a clear separation between containers and content for sizing:

- **Containers control sizing**: NavigationSplitView, VStack, HStack determine available space
- **Content adapts naturally**: Views should specify internal layout only (padding, alignment, spacing)
- **Avoid fighting the framework**: Trust SwiftUI's intrinsic sizing and layout system

#### NavigationSplitView Layout Patterns

##### Correct Pattern - Natural Content Sizing
```swift
// Container manages all sizing
NavigationSplitView {
    // Sidebar content - no size specifications
    VStack {
        // Internal layout only
        Text("Projects")
            .padding()
    }
} detail: {
    // Detail content - no size specifications
    VStack {
        // Internal layout only
        List {
            // Content flows naturally
        }
        .padding()
    }
}
```

##### Anti-Pattern - Content Driving Container Size
```swift
// NEVER: Content specifying container dimensions
NavigationSplitView {
    VStack {
        Text("Projects")
    }
    .frame(maxHeight: 600)  // Fights container
} detail: {
    List {
        // Content
    }
    .frame(maxHeight: .infinity)  // Can cause window auto-resize
    .frame(minHeight: 300)        // Rigid constraints
}
```

### Frame Modifier Guidelines

#### When to Use Frame Modifiers

##### Appropriate Usage
```swift
// Horizontal expansion within container
.frame(maxWidth: .infinity)

// Specific content sizing (buttons, images)
.frame(width: 200, height: 44)

// Minimum content requirements
.frame(minWidth: 100)
```

##### Avoid These Patterns
```swift
// Multiple stacked frame modifiers
.frame(maxHeight: 600)
.frame(minHeight: 300)  // Overcomplicating

// Height constraints in container content
.frame(maxHeight: .infinity)  // Can interfere with container

// Rigid size specifications
.frame(width: .infinity, height: 600)  // Fighting natural flow
```

### Common Layout Anti-Patterns

#### Problem: Window Auto-Resizing
**Symptom**: Window expands to screen height when view appears
**Cause**: Content specifying unlimited height requirements
**Solution**: Remove all height frame modifiers from content

```swift
// Causes window auto-resize
VStack {
    List { /* content */ }
        .frame(maxHeight: .infinity)  // Requests unlimited space
}

// Natural sizing
VStack {
    List { /* content */ }
        // No frame modifiers - adapts to container
}
```

#### Problem: NavigationSplitView Column Conflicts
**Symptom**: Columns don't resize proportionally with window
**Cause**: Conflicting frame constraints on NavigationSplitView
**Solution**: Remove external frame constraints, use only column width settings

```swift
// Conflicting constraints
NavigationSplitView { /* content */ }
    .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 400)
    .frame(minWidth: 800, maxWidth: .infinity)  // Conflicts
    .frame(minHeight: 500, maxHeight: 800)      // Conflicts

// Clean column specification
NavigationSplitView { /* content */ }
    .navigationSplitViewColumnWidth(min: 200, ideal: 250)
```

### SwiftUI Layout Debugging

#### Identifying Layout Issues
1. **Window auto-resizing**: Look for `.frame(maxHeight:)` in content
2. **Rigid layouts**: Multiple stacked `.frame()` modifiers
3. **Container conflicts**: Frame modifiers on NavigationSplitView
4. **Overcomplication**: More than one frame modifier per view

#### Quick Fixes
1. **Remove all height constraints** from list/content views
2. **Use only essential frame modifiers** (maxWidth for expansion)
3. **Trust container sizing** - let NavigationSplitView handle dimensions
4. **Simplify progressively** - remove constraints until layout works naturally

### Testing Layout Behavior

#### Validation Checklist
- [ ] Window respects user-defined size (no auto-expansion)
- [ ] Content fills available space appropriately
- [ ] Resizing window affects both sidebar and detail proportionally
- [ ] Empty states have same layout footprint as populated states
- [ ] No conflicting frame modifiers on same view

#### Common Test Scenarios
1. **Empty to populated transitions** (lists, content areas)
2. **Window resizing** (small to large and vice versa)
3. **Column proportions** (sidebar vs detail scaling)
4. **Content overflow** (long lists, large content)

### Migration from Rigid to Natural Layout

#### Step-by-Step Process
1. **Identify problematic constraints**: Search for `.frame(max/minHeight:)`
2. **Remove constraints progressively**: Start with most restrictive
3. **Test at each step**: Verify layout still works
4. **Simplify container setup**: Remove external NavigationSplitView constraints
5. **Validate responsiveness**: Test window resizing behavior

This approach prevents the overcomplication that leads to layout conflicts and ensures SwiftUI can manage sizing naturally.

## Performance Guidelines (Swift 6 Optimized)

### Memory Management (Actor-Safe)
- Use `weak` references in closures to prevent retain cycles across actors
- Implement lazy loading for large datasets with proper isolation
- Cache frequently accessed content with Sendable conformance
- Avoid capturing strong references to MainActor objects in background tasks

### Concurrency Optimization
- Leverage default MainActor isolation for UI operations
- Use `nonisolated` for CPU-intensive operations
- Implement proper task cancellation for long-running operations
- Minimize actor switching with bulk operations

#### Task-Based Debouncing Pattern (preferred over DispatchWorkItem)
```swift
// CORRECT: Cancellable Task debounce — no GCD
@State private var saveTask: Task<Void, Never>?

private func scheduleSave() {
    saveTask?.cancel()
    saveTask = Task { @MainActor in
        try? await Task.sleep(for: .milliseconds(500))
        guard !Task.isCancelled else { return }
        await performSave()
    }
}
```
Do NOT use `DispatchWorkItem` + `DispatchQueue.main.asyncAfter` for debouncing — this crosses the GCD/actor boundary and may produce concurrency warnings under strict concurrency checking.

### SwiftData Performance
```swift
// Efficient batch operations
nonisolated func batchUpdateProjects(_ updates: [ProjectUpdate]) async throws {
    let context = ModelContext(modelContainer)

    for update in updates {
        if let project = try context.fetch(
            FetchDescriptor<ContentProject>(
                predicate: #Predicate { $0.id == update.projectId }
            )
        ).first {
            project.updateFromBatch(update)
        }
    }

    try context.save()
}
```

---

**Last Updated**: 2026-03-03
**Swift Version**: 6.2.3 (Xcode toolchain), language version 6.2, with Default MainActor Isolation
**Important:** This document provides implementation guidance only. Actual code should be generated and compiled to ensure correctness. Update this document as architectural decisions are made during development.
