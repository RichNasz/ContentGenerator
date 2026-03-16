# AI Code Generation Specification

## Purpose and Scope

This specification defines the **exact implementation patterns and validation framework** for AI-first, error-free code generation in the ContentGenerator project. This document provides copy-paste ready code patterns that ensure 100% compilation success and eliminate ambiguity in AI implementation decisions.

**Critical Requirement**: All AI-generated code must compile on first attempt with zero errors, warnings, or human intervention required.

**Swift 6 + Default MainActor Context**: This project uses Swift 6 with default actor isolation set to MainActor, which significantly changes concurrency patterns compared to manual @MainActor projects.

## AI-First Generation Process

**CRITICAL**: Before beginning any phase, consult `CodeLessonsLearned.md` for known error patterns in the target area and apply prevention strategies.

## Swift 6 + Default MainActor Compliance

**MANDATORY**: All generated code must be Swift 6 compliant with strict concurrency checking enabled and default MainActor isolation.

### Actor Isolation Patterns (Adapted for Default MainActor)

#### Value Types and Sendable Conformance
```swift
// CORRECT: Simple value types with nonisolated(unsafe) for actor isolation issues
nonisolated(unsafe) struct ValidationIssue: CustomStringConvertible, Equatable, Sendable {
    let field: String
    let issue: String

    var description: String {
        "\(field): \(issue)"
    }
}

// CORRECT: Data models that are naturally Sendable
struct QualityScore: Sendable {
    let overall: Double
    let feedback: String
}
```

#### MainActor Isolation (Default Context)
```swift
// CORRECT: UI classes automatically MainActor isolated (no annotation needed)
@Observable
final class ProjectListViewModel {
    // All properties and methods are MainActor isolated by default
    private(set) var projects: [ContentProject] = []
    private(set) var isLoading = false
}

// CORRECT: Background processing classes must be explicitly nonisolated
nonisolated final class DataProcessor {
    func processContent() async throws -> ProcessedContent {
        // Background work properly isolated
    }
}

// CORRECT: When you need to override default isolation for specific methods
final class MixedResponsibilityClass {
    // UI methods (MainActor by default)
    func updateUI() {
        // UI updates here
    }

    // Background methods (explicitly nonisolated)
    nonisolated func processData() async throws {
        // Background processing
    }
}
```

#### Explicit MainActor (Only When Needed)
```swift
// CORRECT: Only use @MainActor when overriding default or for clarity
@MainActor
protocol UIUpdating {
    func refreshInterface()
}

// CORRECT: When conforming to protocols that require MainActor
extension ContentViewModel: UIUpdating {
    func refreshInterface() {
        // Implementation
    }
}
```

#### Avoiding Key Path Issues
```swift
// INCORRECT: Key paths with main actor-isolated properties
return "Content validation failed: \(issues.map(\.description).joined(separator: ", "))"

// CORRECT: Use closure syntax instead
return "Content validation failed: \(issues.map { $0.description }.joined(separator: ", "))"
```

### Concurrency Error Prevention (Default MainActor Context)
1. **Assume MainActor isolation by default** - most classes don't need explicit annotation
2. **Use `nonisolated`** for background processing classes and methods
3. **Use `nonisolated(unsafe)`** for value types that have isolation conflicts
4. **Add `Sendable` conformance** to all data transfer types
5. **Avoid key paths** with actor-isolated properties
6. **Use closures instead** of key paths for transformations

### Phase 0: Error Prevention Check (Error Rate Target: 0%)

#### Step 1: Pre-Generation Error Database Consultation
**Action**: Review CodeLessonsLearned.md for patterns related to upcoming work

**Process**:
1. **Category Search**: Look for errors in relevant category (SwiftData, SwiftUI, etc.)
2. **Context Matching**: Find errors similar to planned implementation
3. **Prevention Pattern Application**: Apply known prevention strategies

## SwiftData Model Generation Patterns

### Basic Model Structure
```swift
// CORRECT: SwiftData model with proper relationship syntax
import SwiftData
import Foundation

@Model
final class ContentProject {
    var id: UUID
    var name: String
    var projectDescription: String?
    var systemPrompt: String?
    var llmConnectionId: UUID?
    var createdAt: Date
    var modifiedAt: Date
    var status: ProjectStatus

    // Relationships with proper syntax
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

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class SpecificationSection {
    var id: UUID
    var name: String
    var sectionDescription: String?
    var content: String
    var contentGenerationPrompt: String?
    var contentUsagePrompt: String?
    var isEnabled: Bool
    var orderIndex: Int
    var assistantLLMConnectionId: UUID?   // Section-level LLM assistant connection
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to specification
    var specification: ContentSpecification?

    init(name: String, content: String, orderIndex: Int = 0) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.isEnabled = true
        self.orderIndex = orderIndex
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class ContentSpecification {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Inverse relationship to project
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
}
```

### Enum Support in SwiftData
```swift
// CORRECT: String-backed enum for SwiftData compatibility
enum ProjectStatus: String, CaseIterable, Codable {
    case draft = "draft"
    case active = "active"
    case generating = "generating"
    case completed = "completed"
}

```

## SwiftUI View Patterns (Default MainActor)

### View Model Pattern
```swift
// CORRECT: Observable view model (MainActor by default)
@Observable
final class ContentListViewModel {
    private(set) var content: [ContentProject] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let dataService: ContentDataService

    init(dataService: ContentDataService) {
        self.dataService = dataService
    }

    func loadContent() {
        isLoading = true
        errorMessage = nil

        Task {
            do {
                content = try await dataService.fetchContent()
                isLoading = false
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}
```

### SwiftUI View Structure
```swift
// CORRECT: SwiftUI view with proper state management
struct ContentListView: View {
    @State private var viewModel: ContentListViewModel
    @Environment(\.modelContext) private var modelContext

    init() {
        let dataService = ContentDataService()
        _viewModel = State(initialValue: ContentListViewModel(dataService: dataService))
    }

    var body: some View {
        NavigationStack {
            contentListBody
                .navigationTitle("Content Projects")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        addButton
                    }
                }
        }
        .task {
            viewModel.loadContent()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.clearError()
            }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var contentListBody: some View {
        if viewModel.isLoading {
            ProgressView("Loading content...")
        } else if viewModel.content.isEmpty {
            ContentUnavailableView("No Content", systemImage: "doc.text")
        } else {
            List(viewModel.content) { project in
                ContentProjectRow(project: project)
            }
        }
    }

    private var addButton: some View {
        Button("Add", systemImage: "plus") {
            // Add new content action
        }
    }
}
```

## Background Service Patterns

### Data Service (Nonisolated)
```swift
// CORRECT: Background service properly isolated
nonisolated final class ContentDataService {
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    func fetchContent() async throws -> [ContentProject] {
        // Background data fetching
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<ContentProject>(
            sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    func saveContent(_ project: ContentProject) async throws {
        let context = ModelContext(modelContainer)
        context.insert(project)
        try context.save()
    }
}
```

### AI Service Integration
```swift
// CORRECT: AI service for content generation
nonisolated final class AIContentService {
    private let apiKey: String
    private let endpoint: URL

    init(apiKey: String, endpoint: URL) {
        self.apiKey = apiKey
        self.endpoint = endpoint
    }

    func generateContent(for specification: ContentSpecification) async throws -> GeneratedContent {
        // AI content generation logic
        let request = ContentRequest(specification: specification)

        // Network call
        let response = try await performRequest(request)

        return GeneratedContent(
            content: response.content,
            metadata: response.metadata,
            generatedAt: Date()
        )
    }

    private func performRequest(_ request: ContentRequest) async throws -> ContentResponse {
        // Implementation details
    }
}
```

## Error Handling Patterns

### Custom Error Types
```swift
// CORRECT: Sendable error types
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

    var errorDescription: String? {
        switch self {
        case .aiServiceUnavailable:
            return "AI service is currently unavailable"
        case .invalidContentRequest(let details):
            return "Invalid content request: \(details)"
        case .contentGenerationFailed(let reason):
            return "Content generation failed: \(reason)"
        case .projectIsolationViolation:
            return "Attempted to access data from another project"
        case .projectNotFound(let projectId):
            return "Project not found: \(projectId)"
        case .specificationRequired(let details):
            return "Specification required: \(details)"
        case .settingsAccessError:
            return "Unable to access application settings"
        case .llmConnectionFailed(let details):
            return "LLM connection failed: \(details)"
        case .llmConfigurationInvalid(let details):
            return "LLM configuration invalid: \(details)"
        case .noLLMConnectionsAvailable:
            return "No LLM connections are available"
        case .chatCompletionsAPIError(let details):
            return "Chat Completions API error: \(details)"
        case .chatCompletionsConfigurationMissing:
            return "Chat Completions configuration is missing for this connection"
        case .swiftChatCompletionsDSLError(let details):
            return "SwiftChatCompletionsDSL error: \(details)"
        }
    }
}
```

## Testing Patterns (Default MainActor)

### View Model Testing
```swift
// CORRECT: Testing view models with MainActor isolation
@MainActor
final class ContentListViewModelTests: XCTestCase {
    private var viewModel: ContentListViewModel!
    private var mockDataService: MockContentDataService!

    override func setUp() async throws {
        mockDataService = MockContentDataService()
        viewModel = ContentListViewModel(dataService: mockDataService)
    }

    func testLoadContentSuccess() async throws {
        // Given
        let expectedContent = [ContentProject(name: "Test Project")]
        mockDataService.mockContent = expectedContent

        // When
        viewModel.loadContent()

        // Wait for async operation
        try await Task.sleep(for: .milliseconds(100))

        // Then
        XCTAssertEqual(viewModel.content.count, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.errorMessage)
    }
}
```

## Validation Commands

### Compilation Validation
```bash
# EXACT command sequence for AI to validate compilation
xcodebuild -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' clean build

# SUCCESS: "** BUILD SUCCEEDED **" appears in output
# FAILURE: Apply automated fixes based on error patterns in CodeLessonsLearned.md
```

### Quick Syntax Check
```bash
# Fast syntax validation without full build
xcodebuild -project ContentGenerator.xcodeproj -scheme ContentGenerator -destination 'platform=macOS' -dry-run build 2>&1 | grep -E "(error|warning):"

# SUCCESS: No output (empty result)
# FAILURE: Parse errors and apply automated fixes
```

## Phase-Based Generation Process

### Phase 1: Data Models (Error Rate Target: 0%)
1. Generate @Model classes with proper final keyword
2. Add @Relationship with deleteRule and inverse
3. Validate compilation with xcodebuild
4. Test model creation and relationships

### Phase 2: Service Layer (Error Rate Target: 0%)
1. Generate nonisolated service classes
2. Add proper Sendable conformance
3. Implement async/await patterns
4. Validate compilation and test service methods

### Phase 3: View Models (Error Rate Target: 0%)
1. Generate @Observable view models (MainActor by default)
2. Implement proper state management
3. Add error handling with custom error types
4. Validate compilation and test state changes

### Phase 4: SwiftUI Views (Error Rate Target: 0%)
1. Generate views with proper @State management
2. Implement @ViewBuilder for complex layouts
3. Add proper navigation and toolbar items
4. Validate compilation and test UI behavior

---

**Last Updated**: 2026-01-05
**Swift Version**: 6.2+ with Default MainActor Isolation
**Project**: ContentGenerator