# Swift Technical Specifications

## Purpose
This document provides Swift-specific implementation guidance for functionality defined in FunctionalSpecs.md. It describes architectural patterns, data model fields, service responsibilities, and implementation approaches — NOT complete code implementations.

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

The main application window uses a `NavigationDestination: Hashable` enum to drive all sidebar navigation. All required elements:

- Define `NavigationDestination` as a `Hashable` enum with cases: `project(ContentProject)`, `llmConnections`, and `applicationSettings` (add others as needed)
- Declare `@State private var selectedDestination: NavigationDestination?` in the view
- Use `List(selection: $selectedDestination)` to bind the sidebar's selection state
- Each sidebar item uses `NavigationLink(value: NavigationDestination.project(project))` — never `Button`
- The detail column switches on `selectedDestination` using an `if let` + `switch` to render the appropriate view
- Show `ContentUnavailableView` when `selectedDestination` is nil
- `@Model` types used in enum cases must conform to `Hashable` using `id`-based `==` and `hash(into:)` implementations with `nonisolated` qualifier

**CRITICAL DIFFERENCES from NavigationStack**:
- `List(selection:)` binding is REQUIRED
- Detail section switches on selection state directly
- NO `.navigationDestination(for:)` modifier — that modifier is for `NavigationStack` only
- `@State var selectedDestination` is needed for detail routing

### Anti-Patterns (DO NOT USE)

**Anti-Pattern 1: Using `.navigationDestination` with NavigationSplitView** — `.navigationDestination(for:)` is a `NavigationStack` modifier. Applying it to a `NavigationSplitView` compiles but never shows the destination view — the detail column remains static no matter what sidebar item is tapped.

**Anti-Pattern 2: Mixed Button and NavigationLink Navigation** — Using `Button { selectedProject = project }` for some items and `NavigationLink(...)` for others in the same `List` causes navigation to break after the first `NavigationLink` transition. All sidebar items must use `NavigationLink(value:)` exclusively.

**Anti-Pattern 3: Missing List Selection Binding** — Using `List { ... }` without a `selection:` parameter means tapping a `NavigationLink(value:)` item has no connection to the detail column. The detail column has no source of truth for which item is selected.

### Navigation Structure Requirements
- **Value-Based NavigationLink**: MANDATORY — all sidebar items must use `NavigationLink` with enum values
- **List Selection Binding**: REQUIRED — `List(selection:)` must bind to selection state
- **Detail Switches on Selection**: Detail section must switch on `selectedDestination`
- **No `.navigationDestination`**: This modifier is for `NavigationStack`, NOT `NavigationSplitView`
- **Hashable Destinations**: All destination types must conform to `Hashable`
- **Type Safety**: Enum ensures only valid destinations are possible

### NavigationSplitView Implementation Checklist
- [ ] `NavigationDestination` enum defined with all destinations
- [ ] All model types used in enum conform to `Hashable`
- [ ] `@State var selectedDestination` declared in view
- [ ] `List(selection: $selectedDestination)` binding present
- [ ] Sidebar items use `NavigationLink(value:)` exclusively
- [ ] Detail section switches on `selectedDestination` with if-let
- [ ] NO `.navigationDestination(for:)` modifier (that's for NavigationStack!)
- [ ] No Button-based navigation mixed with NavigationLink

### State Management Pattern (Direct @State/@Bindable)

This project does **not** use ViewModels. Views manage state directly using SwiftUI property wrappers:

- `@Bindable var project: ContentProject` for two-way binding to SwiftData model properties
- `@State private var` for all local UI state (error flags, loading states, transient data such as section lists or drag state)
- Data is fetched inside `.task` handlers or helper methods by calling `modelContext.fetch(FetchDescriptor<T>(...))` directly — no intermediate ViewModel

### Service Layer Patterns

#### ProjectDataManager
`ProjectDataManager` is an `@Observable final class` that manages the SwiftData `ModelContainer` for the application. No explicit `@MainActor` — default isolation applies.

Stored properties:
- `bundleURL: URL` — stored at init time; exposed publicly for services that resolve bundle-relative file paths

Key methods:
- `init(bundleURL: URL) throws` — creates `ModelContainer` with all app models (`ContentProject`, `ContentSpecification`, `SpecificationSection`, `GeneratedContentData`, `FileAttachment`, `ApplicationSettings`, `LLMConnection`) stored in a file at `bundleURL/swiftdata/default.store`
- `getContainer() -> ModelContainer` — returns the underlying container
- `createContext() -> ModelContext` — creates and returns a fresh `ModelContext` from the container
- `attachmentsDirectory(for projectId: UUID) throws -> URL` — returns the `projects/<uuid>/attachments/` directory within the bundle, creating it if it does not exist

#### GlobalSettingsService
`GlobalSettingsService` is a `@MainActor @Observable final class` for reading and writing application settings, independent of any project.

- `init(dataManager: ProjectDataManager)`
- `getSettings() async throws -> ApplicationSettings` — fetches the first `ApplicationSettings` record, or creates a default instance if none exists
- `updateSettings(_ settings: ApplicationSettings) async throws` — sets `modifiedAt` to the current date and saves the context

#### Project Deletion Bundle Cleanup Pattern

When a project is deleted in `confirmDeleteProjects()` (ContentView), its `projects/<uuid>/` directory must be removed from the bundle after the SwiftData save succeeds:

1. **Capture IDs before deletion**: Map offsets → project UUIDs while the `@Query` objects are still live (before `context.delete` is called)
2. **Delete after save**: After `try context.save()`, iterate over the captured UUIDs and remove each project directory using `try? FileManager.default.removeItem(at:)`
3. **Non-fatal**: Use `try?` so a missing directory (project had no attachments) does not interrupt cleanup of subsequent projects
4. **Path construction**: `dataManager.bundleURL.appendingPathComponent("projects").appendingPathComponent(projectId.uuidString)` — stops at the project level (not the `attachments/` subdirectory) to clean up the full project footprint

This mirrors the non-fatal `try? FileManager.default.removeItem(at:)` pattern used in `FileAttachmentManager.removeAttachment(_:from:)`.

#### BundleManager Pattern
`BundleManager` is a `@MainActor @Observable final class` that manages bundle creation, opening, and restoration. Stored properties:
- `bundleURL: URL?` (private setter)
- `bundleState: BundleState`

Methods:
- `createNewBundle() async -> URL?` — creates a new `.cgspecs` bundle with `swiftdata/` and `projects/` subdirectories
- `openExistingBundle() async -> URL?` — presents an open panel and returns the selected bundle URL
- `restoreSavedBundle() -> URL?` — restores the previously-used bundle URL from persistent storage
- `attachmentsDirectory(for projectId: UUID) throws -> URL` — returns the `projects/<uuid>/attachments/` path; throws `BundleManagerError.noBundleSelected` if no bundle is open

Supporting types:
- `BundleState` enum (Sendable): cases `noBundleSelected`, `loading`, `ready(URL)`, `error(String)`
- `BundleManagerError` enum (LocalizedError): case `noBundleSelected`

### File Attachment Service Pattern

`FileAttachmentManager` handles file attachments by copying files into the `.cgspecs` bundle at attach time. The bundle's single security-scoped bookmark (held by `BundleManager`) covers all files inside it, eliminating per-file bookmark management.

**Architecture Pattern:**
- `@Observable` class with default MainActor isolation (no explicit `@MainActor` needed on the class)
- Depends on `ProjectDataManager` (which exposes `bundleURL: URL`)
- Files stored at `bundle/projects/<uuid>/attachments/<filename>`; a relative path string is stored on `FileAttachment`
- Legacy attachments (created before this pattern) use `securityScopedBookmarkData` as a fallback

**`FileSelectionResult`** (returned by `selectAndAttachFiles(to:)`):
A struct with two properties:
- `attachments: [FileAttachment]` — successfully created attachment records, ready to add to the project
- `duplicates: [(url: URL, existingFileName: String)]` — files the user selected that already exist in the project; `url` is the source URL of the new file, `existingFileName` is the `originalFileName` of the conflicting existing record (used to look up the record via `project.attachments.first(where:)`)

`selectAndAttachFiles(to:)` catches `.duplicateAttachment` separately from other errors. New and duplicate files are returned together so the caller can add the new ones immediately and queue the duplicates for confirmation. Per-file loop behavior:
- `.duplicateAttachment(fileName:)` → appended to `result.duplicates`; processing continues for remaining files
- Any other error → logged to console; file skipped; processing continues
- If the user cancels the file picker: returns an empty `FileSelectionResult` immediately

**Bundle Storage Pattern:**
- On attach: copy the user-selected file into `dataManager.attachmentsDirectory(for: project.id)`; store the relative path in `FileAttachment.relativeBundlePath`
- Filename conflicts within the same project's attachments directory resolved with a numeric suffix (`report-2.md`, etc.)
- On access: resolve `dataManager.bundleURL.appendingPathComponent(relativeBundlePath)` directly — no `startAccessingSecurityScopedResource()` needed
- On remove: call `FileAttachmentManager.removeAttachment(_:from:)` — deletes the physical bundle copy via `FileManager.default.removeItem(at:)` (using `try?` so a missing file is not an error), then removes the SwiftData record via `project.removeAttachment(_:)`. Views must NOT call `project.removeAttachment(_:)` directly; always go through `FileAttachmentManager`
- On replace: call `FileAttachmentManager.replaceAttachment(_:withFileAt:)` — deletes the old bundle copy (`try?`), copies the new file using `existing.originalFileName` as the canonical destination name (normalises any previously suffixed path), and mutates the existing `FileAttachment` record in-place (same UUID, updated `relativeBundlePath`, `fileSizeBytes`, `isAccessible`, and `modifiedAt`). The SwiftData record is never removed and re-added; identity is preserved

**`replaceAttachment(_:withFileAt:)` on `FileAttachmentManager`:**

A `@MainActor async throws` method. Parameters:
- `existing: FileAttachment` — the in-place SwiftData record to update
- `sourceURL: URL` — the URL of the new file to copy into the bundle

Execution sequence (all on MainActor):
1. `validateFile(at: sourceURL)` — type, size, file-URL checks; throws on failure before touching anything
2. Guard `existing.project?.id` — throws `.fileCopyFailed` if attachment has no associated project
3. `try? FileManager.default.removeItem(at: oldURL)` — delete old bundle copy (non-fatal; continues if missing)
4. `FileManager.default.copyItem(at: sourceURL, to: attachmentsDir.appendingPathComponent(existing.originalFileName))` — uses `originalFileName` as canonical destination; throws `.fileCopyFailed(error)` on copy failure
5. Update existing record in-place: `relativeBundlePath`, `isAccessible = true`, `fileSizeBytes` (via `try?` resourceValues; non-fatal), `updateModifiedDate()`

Error cases:
- `.fileCopyFailed(NSError)` — no associated project
- `.fileCopyFailed(Error)` — file copy to bundle failed
- Validation errors from `validateFile()`: `.notAFileURL`, `.notARegularFile`, `.fileTooLarge`, `.unsupportedFileType`

- Calling `stopAccessingSecurityScopedResource()` on a bundle-file URL is a safe no-op; callers do not need to change their defer patterns
- Stale bookmark detection and refresh are not needed for bundle-based attachments

**Legacy Fallback:**
- If `relativeBundlePath` is nil, fall back to resolving `securityScopedBookmarkData` via the old security-scoped bookmark API
- Old attachments show "Locate" button; when user locates the file, it is copied into the bundle and `relativeBundlePath` is set

**`FileAttachmentError` cases:**
- `.fileCopyFailed(Error)` — file copy to bundle failed
- `.fileNotFoundInBundle` — `relativeBundlePath` set but file missing from bundle
- `.noBookmarkData` — legacy path: neither relative path nor bookmark available
- `.bookmarkResolutionFailed(Error)` — legacy path: bookmark resolve failed
- `.cannotAccessSecurityScopedResource` — legacy path: could not start accessing
- `.fileTooLarge`, `.unsupportedFileType`, `.notAFileURL`, `.notARegularFile`, `.duplicateAttachment`, `.fileReadFailed`, `.unableToReadFileSize` — validation errors

**Duplicate Confirmation Pattern (`FileAttachmentSection`):**

The view maintains these `@State private var` properties for attachment handling:
- `isLoading: Bool` — disables Add button; shown in file list
- `showingError: Bool` — drives error `.alert`
- `errorMessage: String` — error alert message text
- `dragIsTargeted: Bool` — drives drop-zone highlight border
- `pendingReplacements: [(url: URL, existingFileName: String)]` — queue of duplicates awaiting user confirmation
- `showingReplaceConfirmation: Bool` — drives the confirmation dialog

`showNextReplacement()` sets `showingReplaceConfirmation = !pendingReplacements.isEmpty`.

**File-picker path (`addAttachments()`):**
1. Call `attachmentManager.selectAndAttachFiles(to: project)` → `FileSelectionResult`
2. Add `result.attachments` to project immediately
3. Append `result.duplicates` to `pendingReplacements`; call `showNextReplacement()`

**Drag-and-drop path (`processDraggedFile(url:)`):**
- Catch `.duplicateAttachment(let fileName)` specifically: append `(url: url, existingFileName: fileName)` to `pendingReplacements`, set `isLoading = false`, call `showNextReplacement()`
- Catch all other errors: set `errorMessage` + `showingError = true`, set `isLoading = false`

**`.confirmationDialog` (chained after `.alert` on the view body):**
- Title: `"Replace \"<pendingReplacements.first?.existingFileName>\"?"`; `titleVisibility: .visible`
- Message: warns that replacing cannot be undone
- Button "Replace" (`role: .destructive`):
  1. Pop `pendingReplacements.first`
  2. Look up `existing = project.attachments.first(where: { $0.originalFileName == pending.existingFileName })`
  3. If found: call `attachmentManager.replaceAttachment(existing, withFileAt: pending.url)` inside `Task`; on error set `errorMessage`/`showingError`; call `showNextReplacement()` regardless (error or success)
  4. If not found (edge case — attachment was removed between queue and dialog): call `showNextReplacement()` directly
- Button "Keep Existing" (`role: .cancel`): pop `pendingReplacements.first`, call `showNextReplacement()`

### Project Import/Export Service Pattern

`ProjectExportService` handles project import and export operations, following the established service patterns used by `GlobalSettingsService` and `FileAttachmentManager`.

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
- File contents are base64-encoded into `ExportableFileAttachment.fileContentBase64` when the attachment is stored inside the bundle and readable at export time; legacy inaccessible attachments export with `fileContentBase64 = nil`
- On import, base64 content is decoded and written to `bundle/projects/<uuid>/attachments/`; the attachment is immediately accessible

**UI Integration Points:**
- Export: Action menu in `ProjectDetailView` with `NSSavePanel` for file selection
- Import: Sidebar header button in `ContentView` with `NSOpenPanel` for file selection
- Conflict Resolution: `LLMConnectionConflictSheet` presents side-by-side comparison
- Post-import alerts display warnings (e.g., files need re-attachment, API key needed)

### Content Generation Window Patterns

The application uses dedicated windows for content generation workflows, separate from the main application window.

**ProjectContentGenerationWindow:**
- Standalone window for project-level content generation
- Two-column layout: LLM controls | generated content (project overview column removed)
- Default window size: `minWidth: 700, idealWidth: 1200, idealHeight: 700`
- macOS remembers user-resized dimensions via window restoration; ideal size applies only on first open

**SectionContentGenerationWindow:**
- Focused window for single-section content generation
- Three-column layout: current content (read-only) | LLM controls/prompts | generated content
- Includes prompt export (copy to clipboard, save to .md file)

**Window State Management Pattern:**
- Use `@Observable` classes for window state (e.g., `ContentGenerationWindowState`)
- State includes: target project/section, LLM connection, generation status, result
- Window state passed via environment for view access
- Use `@Environment(\.openWindow)` to launch generation windows
- Window scenes registered in app definition with appropriate identifiers

#### Dual-Endpoint Pattern (Both Generation Windows)

Both generation windows import `SwiftChatCompletionsDSL` and `SwiftOpenResponsesDSL` and switch on `llmConnection.endpointType` in `generateContent()` with a `switch` over the two cases (`.chatCompletions` and `.responses`), launching a `Task` for each path.

**Chat Completions path** (`SectionContentGenerationWindow`, `ProjectContentGenerationWindow`):
- Use `SwiftChatCompletionsDSL.LLMClient` + `ChatRequest` + `client.stream(request)`
- Extract streaming text from `delta.choices.first?.delta.content`
- Qualify builder types with the module prefix: `SwiftChatCompletionsDSL.Temperature`, `SwiftChatCompletionsDSL.RequestTimeout`, `SwiftChatCompletionsDSL.ResourceTimeout`
- Catch streaming errors as `SwiftChatCompletionsDSL.LLMError`

**Responses path** (`SectionContentGenerationWindow`, `ProjectContentGenerationWindow`):
- Use `SwiftOpenResponsesDSL.LLMClient` + `ToolSession(client:tools:[],maxIterations:1,handlers:[:])` + `session.stream(model:input:[User(msg)],configParams:)`
- Extract streaming text by matching `.llm` events and `.contentPartDelta` sub-events
- Config params array type: `[any ResponseConfigParameter]` — includes `RequestTimeout`, `ResourceTimeout`, and in `ProjectContentGenerationWindow`, also `Instructions(buildSystemPrompt())`
- Catch streaming errors as `SwiftOpenResponsesDSL.LLMError`

**`formatLLMError` overloading pattern** (required when both DSLs are imported):
Define two overloads of `private func formatLLMError(...)` — one accepting `SwiftChatCompletionsDSL.LLMError` and one accepting `SwiftOpenResponsesDSL.LLMError`. Both have identical bodies since both DSLs expose the same case names. Swift resolves the correct overload by parameter type. See `CodeLessonsLearned.md ERR-COMPILE-005` for the ambiguity details.

**Throttled UI update pattern** (both paths, both windows):
Track a `lastUpdateTime: Date` (initially `.distantPast`) alongside the accumulated full content string. During streaming, check if at least 50ms have elapsed since the last update before assigning `generatedContent` via `MainActor.run`. Always perform one final assignment after the loop ends to flush any remaining content. This throttles SwiftUI diffing to ~20 fps without dropping content.

#### LLM Picker Grouping Pattern (Both Standard Generation Windows)

Both `SectionContentGenerationWindow` and `ProjectContentGenerationWindow` group connections by endpoint type and show a locality icon.

**Computed filter properties** on the view:
- `chatCompletionsConnections: [LLMConnection]` — filters `configuredLLMConnections` to `.chatCompletions` endpoint type
- `responsesConnections: [LLMConnection]` — filters `configuredLLMConnections` to `.responses` endpoint type

**`isLocalConnection(_ connection: LLMConnection) -> Bool`** — private helper that parses the connection's `baseUrl` with `URLComponents`, lowercases the host, and returns `true` for `localhost`, `127.0.0.1`, `0.0.0.0`, `::1`, or `[::1]`.

**Picker structure**: A `Picker("LLM", selection: $selectedLLMId)` with `.pickerStyle(.menu)`. The picker body contains a "Select LLM" placeholder with `nil` tag, then conditionally a `Section("Chat Completions")` (when `!chatCompletionsConnections.isEmpty`) and a `Section("Responses")` (when `!responsesConnections.isEmpty`). Each connection row uses `Label(connection.name, systemImage: isLocalConnection(connection) ? "house.fill" : "cloud")` tagged with `connection.id as UUID?`.

The agent window (`ProjectAgentGenerationWindow` in `AgentGen`) applies `isLocalConnection()` with the same logic and filters `configuredLLMConnections` to `.responses` only at source. Icons: `"house.fill"` for local, `"cloud"` for cloud/remote connections.

### Agent Generation Window Pattern (AgentGen Package)

The `AgentGen` local Swift package (at `AgentGen/`) provides the agent-based generation window with pluggable inference backends. It is macOS-only; views and the Open Responses backend are guarded with `#if os(macOS)`.

#### Backend Architecture

The view delegates inference to `AgentInferenceBackend` conformers that yield `AgentEvent` values through `AsyncThrowingStream`. Two backends:
- **`AppleIntelligenceBackend`** — on-device via Foundation Models (`LanguageModelSession.respond()`)
- **`OpenResponsesBackend`** — cloud/local via `SwiftOpenResponsesDSL` (`ToolSession.stream()`)

The view consumes a unified event stream via `handleEvent(_:)` without knowing the backend.

#### Unified Activity Log

All interaction events (status, thinking, tool calls, token usage, completion/failure) are captured as `ActivityLogEntry` values in a single chronological `activityLog: [ActivityLogEntry]` array, displayed in Column 2. There are no separate thinking or tool call log sections.

#### Connection Filtering

Only `LLMConnection` instances with `endpointType == .responses` appear in the picker. Connections with local base URLs (localhost, 127.0.0.1, ::1) are grouped under "On-Device" alongside Apple Intelligence.

**Key constraints:**
- No `@Query` anywhere in the package — use manual `modelContext.fetch(FetchDescriptor<T>(...))` (see ERR-SWIFTDATA-001)
- Backend `run()` methods use `AsyncThrowingStream.makeStream()` + `Task { @MainActor in }` + static methods to avoid `sending` data race errors (see AgentGen CodeLessonsLearned ERR-COMPILE-003)
- See `AgentGen/Specs/SwiftTechSpecs.md` for full type descriptions and implementation details

### LLM Integration Patterns

#### OpenAI Endpoint Type
`OpenAIEndpointType` is a `String`-backed enum in the LLMmanagement package, conforming to `CaseIterable` and `Codable`. Cases:
- `chatCompletions` (raw value: `"chat_completions"`)
- `responses` (raw value: `"responses"`)

Computed properties: `defaultPath: String` (returns the standard OpenAI path for each endpoint) and `displayName: String` (returns a human-readable label).

#### LLM Connection Model (from LLMmanagement package)
`LLMConnection` is a SwiftData `@Model final class` in the LLMmanagement package. Fields:
- `id: UUID` — `@Attribute(.unique)` unique identifier
- `name: String` — display name
- `baseUrl: String` — base URL of the service
- `urlPath: String?` — optional custom path override
- `endpointType: OpenAIEndpointType` — chat completions or responses endpoint
- `apiKey: String` — bearer token (empty for unauthenticated local services)
- `selectedModel: String` — model identifier to use
- `requestTimeoutSeconds: Int` — clamped to 60–600 seconds
- `createdAt: Date` and `lastUsed: Date` — tracking timestamps

Computed properties:
- `fullApiUrl: String` — combines `baseUrl` + `urlPath` (if set) or `endpointType.defaultPath`
- `isConfigured: Bool` — validates URL format and non-empty model selection; API key is optional

Copy initializer `init(updatingFrom original: LLMConnection, ...)` creates an updated connection while preserving identity.

## Error Handling Patterns

### Error Handling Foundation
Error handling follows patterns defined in [SwiftCodeGeneration.md](../../../CommonSpecs/SwiftCodeGeneration.md#error-types-with-sendable) for Sendable conformance and proper actor isolation.

### ContentGenerator-Specific Error Types
`ContentGeneratorError` is an enum conforming to `LocalizedError` and `Sendable`. Cases:
- `aiServiceUnavailable`
- `invalidContentRequest(String)`
- `contentGenerationFailed(String)`
- `projectIsolationViolation`
- `projectNotFound(UUID)`
- `specificationRequired(String)`
- `settingsAccessError`
- `llmConnectionFailed(String)`
- `llmConfigurationInvalid(String)`
- `noLLMConnectionsAvailable`
- `chatCompletionsAPIError(String)`
- `chatCompletionsConfigurationMissing`
- `swiftChatCompletionsDSLError(String)`

Implement `errorDescription: String?`, `failureReason: String?`, and `recoverySuggestion: String?` for all cases.

### Error Presentation and Recovery
Error presentation and recovery patterns follow the universal patterns defined in [SwiftUIWithoutMVVM.md](../../../CommonSpecs/SwiftUIWithoutMVVM.md) using `@State` for error state management in views.

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

**`ContentProject`** — `@Model final class` representing a content generation project. Fields:
- `id: UUID` — auto-generated unique identifier
- `name: String` — project display name
- `projectDescription: String?` — optional description
- `systemPrompt: String?` — optional system prompt for generation
- `llmConnectionId: UUID?` — reference to the selected `LLMConnection.id`
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps
- `status: ProjectStatus` — current project status

Relationships:
- `specification: ContentSpecification?` — `@Relationship(deleteRule: .cascade, inverse: \ContentSpecification.project)`
- `generatedContent: [GeneratedContentData]` — `@Relationship(deleteRule: .cascade)`
- `attachments: [FileAttachment]` — `@Relationship(deleteRule: .cascade)`

Methods: `updateModifiedDate()` sets `modifiedAt` to the current date.

**`SpecificationSection`** — `@Model final class` representing one section in a project's specification. Fields:
- `id: UUID` — auto-generated unique identifier
- `name: String` — section name
- `sectionDescription: String?` — optional description for organizational clarity
- `content: String` — the section body text
- `orderIndex: Int` — position in the ordered section list
- `contentGenerationPrompt: String?` — prompt for AI-assisted section content generation
- `contentUsagePrompt: String?` — prompt for how section content should be applied in generation
- `isEnabled: Bool` — whether this section participates in content generation
- `assistantLLMConnectionId: UUID?` — section-level LLM assistant connection reference
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps
- `specification: ContentSpecification?` — inverse relationship back to the parent specification

Methods: `updateModifiedDate()` sets `modifiedAt` to the current date.

**`ContentSpecification`** — `@Model final class` representing the full specification for a project. Fields:
- `id: UUID` — auto-generated unique identifier
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps
- `project: ContentProject?` — inverse relationship (required to prevent ERR-DATA-001)
- `sections: [SpecificationSection]` — `@Relationship(deleteRule: .cascade, inverse: \SpecificationSection.specification)`

Methods:
- `updateModifiedDate()` — sets `modifiedAt` to the current date
- `addSection(name:content:) -> SpecificationSection` — convenience method that creates a new `SpecificationSection` with the next `orderIndex`, sets its `specification` inverse, appends it to `sections`, and calls `updateModifiedDate()` before returning the new section

**`GeneratedContentData`** — `@Model final class` representing one generation result for a project. Fields:
- `id: UUID` — auto-generated unique identifier
- `text: String` — the generated content text
- `metadataJSON: String?` — flexible metadata stored as a JSON string
- `llmConnectionId: UUID?` — reference to the LLM connection used for generation
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps
- `project: ContentProject?` — inverse relationship

Computed property `metadata: [String: Any]?` with getter (deserializes `metadataJSON`) and setter (serializes to `metadataJSON` and updates `modifiedAt`).

**`FileAttachment`** — `@Model final class` representing a file attached to a project. Fields:
- `id: UUID` — auto-generated unique identifier
- `originalFileName: String` — the original file name at attach time
- `fileExtension: String?` — file extension (e.g. "txt", "md"), derived from `originalFileName` at init
- `fileSizeBytes: Int64` — file size in bytes
- `securityScopedBookmarkData: Data?` — legacy bookmark data (kept for migration; `nil` on new attachments)
- `relativeBundlePath: String?` — path relative to bundle root (e.g. `"projects/<uuid>/attachments/report.md"`)
- `isAccessible: Bool` — whether the file is currently accessible
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps
- `project: ContentProject?` — inverse relationship

### Application Settings Model

**`ApplicationSettings`** — `@Model final class` for global application settings. Fields:
- `id: UUID` — auto-generated unique identifier
- `aiServiceEndpoint: String` — AI service base URL
- `aiServiceAPIKey: String` — API key
- `appearanceTheme: AppearanceTheme` — theme preference
- `autoSaveEnabled: Bool` — whether auto-save is active
- `dataBackupLocation: String?` — optional backup path
- `createdAt: Date` and `modifiedAt: Date` — tracking timestamps

Static method `defaultSettings() -> ApplicationSettings` returns a new instance with all defaults.

**`AppearanceTheme`** — `String`-backed enum conforming to `CaseIterable`, `Codable`, `Sendable`. Cases: `light`, `dark`, `system`. Each has a `displayName: String` computed property returning the human-readable label.

**`ProjectStatus`** — `String`-backed enum conforming to `CaseIterable`, `Codable`, `Sendable`. Cases: `draft`, `active`, `generating`, `completed`. Each has a `displayName: String` computed property.

## SwiftUI Layout Best Practices

### Layout Architecture Principles

#### Container vs Content Responsibility
SwiftUI follows a clear separation between containers and content for sizing:
- **Containers control sizing**: `NavigationSplitView`, `VStack`, `HStack` determine available space
- **Content adapts naturally**: Views should specify internal layout only (padding, alignment, spacing)
- **Avoid fighting the framework**: Trust SwiftUI's intrinsic sizing and layout system

#### NavigationSplitView Layout Patterns

**Correct Pattern — Natural Content Sizing**: Content views inside `NavigationSplitView` columns should not specify frame dimensions. The container manages all sizing. Internal views may specify padding and alignment but should not add `.frame(maxHeight:)` or `.frame(minHeight:)` modifiers that fight the container.

**Anti-Pattern — Content Driving Container Size**: Never add `.frame(maxHeight: .infinity)` or `.frame(minHeight:)` on list or content views inside a `NavigationSplitView` column. These constraints request specific space from the container and can cause the window to auto-resize to fill the screen.

### Frame Modifier Guidelines

#### Appropriate Usage
- `.frame(maxWidth: .infinity)` — horizontal expansion within a container
- `.frame(width:height:)` with specific values — for fixed-size content like buttons or images
- `.frame(minWidth:)` — minimum content requirements

#### Avoid These Patterns
- Multiple stacked `.frame()` modifiers on the same view — overcomplicates layout
- `.frame(maxHeight: .infinity)` on content inside a `NavigationSplitView` column — can interfere with container sizing
- Rigid height specifications on scrollable content — fights natural flow

### Common Layout Anti-Patterns

**Problem: Window Auto-Resizing**
- Symptom: Window expands to screen height when view appears
- Cause: A content view requests unlimited height (e.g. `.frame(maxHeight: .infinity)`)
- Solution: Remove all height frame modifiers from content views; let the container determine height

**Problem: NavigationSplitView Column Conflicts**
- Symptom: Columns don't resize proportionally with window
- Cause: Conflicting frame constraints on the `NavigationSplitView` itself
- Solution: Remove external `.frame(minHeight:maxHeight:)` constraints; use only `.navigationSplitViewColumnWidth(min:ideal:)` for column sizing

### SwiftUI Layout Debugging

#### Identifying Layout Issues
1. **Window auto-resizing**: Look for `.frame(maxHeight:)` in content views
2. **Rigid layouts**: Multiple stacked `.frame()` modifiers on the same view
3. **Container conflicts**: Frame modifiers applied to the `NavigationSplitView` itself
4. **Overcomplication**: More than one frame modifier per view

#### Quick Fixes
1. Remove all height constraints from list and content views
2. Use only essential frame modifiers (`.frame(maxWidth: .infinity)` for horizontal expansion)
3. Trust container sizing — let `NavigationSplitView` handle dimensions
4. Simplify progressively: remove constraints until the layout works naturally

### Testing Layout Behavior

#### Validation Checklist
- [ ] Window respects user-defined size (no auto-expansion)
- [ ] Content fills available space appropriately
- [ ] Resizing window affects both sidebar and detail proportionally
- [ ] Empty states have same layout footprint as populated states
- [ ] No conflicting frame modifiers on same view

#### Common Test Scenarios
1. Empty-to-populated transitions (lists, content areas)
2. Window resizing (small to large and vice versa)
3. Column proportions (sidebar vs detail scaling)
4. Content overflow (long lists, large content)

### Migration from Rigid to Natural Layout

#### Step-by-Step Process
1. Identify problematic constraints: search for `.frame(max/minHeight:)` on content views
2. Remove constraints progressively, starting with the most restrictive
3. Test at each step to verify the layout still works
4. Simplify container setup: remove external `NavigationSplitView` constraints
5. Validate responsiveness: test window resizing behavior

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
Store a `Task<Void, Never>?` as a `@State private var`. In the debounced method, cancel the previous task and start a new one that sleeps for the debounce interval (e.g. 500ms via `Task.sleep(for: .milliseconds(500))`), checks `Task.isCancelled` after waking, and only then performs the work. Do NOT use `DispatchWorkItem` + `DispatchQueue.main.asyncAfter` for debouncing — this crosses the GCD/actor boundary and may produce concurrency warnings under strict concurrency checking.

### SwiftData Performance
Batch update operations should be `nonisolated` functions that create a fresh `ModelContext` from the container, iterate over updates using `FetchDescriptor` predicates to locate each record, apply mutations in-place, and call `context.save()` once at the end. This keeps bulk writes off the MainActor and reduces context switching.

---

**Last Updated**: 2026-03-27 (converted all code blocks to prose per no-code-in-specs rule; content otherwise matches prior revision)
**Swift Version**: 6.2.3 (Xcode toolchain), language version 6.2, with Default MainActor Isolation
**Important:** This document provides implementation guidance only. Actual code should be generated and compiled to ensure correctness. Update this document as architectural decisions are made during development.
