#  Swift Implementation Guide

## Purpose and Scope

This specification provides **Swift-specific implementation guidance** to complement language-agnostic algorithms and functional requirements in Swift projects.

**Key Principle**: This guide focuses on how to implement algorithms using Swift's language features, ecosystem, and best practices. All Swift code generation must use Swift 6.2 (preferred) or Swift 6.1 (fallback only if functionality cannot be implemented).

**What This Guide Provides:**
- Swift-specific function signatures and type requirements
- Swift ecosystem library integration patterns (Foundation, SwiftUI, Swift Testing)
- Swift platform and tooling specifics (Xcode toolchain integration, cross-platform)
- Swift performance and error handling patterns

**What This Guide Does NOT Provide:**
- Complete algorithm implementations (AI should optimize these)
- Functional requirements (see project functional specification)
- Language-agnostic algorithms (implement using Swift best practices)
- Business logic or parsing rules (covered in functional specifications)
- Documentation standards (see DocumentationSpec.md for DocC and API documentation requirements)
- Comprehensive testing patterns (see SwiftTestingSpec.md for detailed testing framework guidance)

This guide provides the Swift-specific implementation contracts and ecosystem integration patterns needed to translate generic algorithms into idiomatic, efficient Swift code. All development targets iOS 26.0+ and must use Xcode 26.1.1+ for building and testing. By focusing on language-specific requirements rather than complete implementations, it allows AI code generators maximum creativity while ensuring proper Swift ecosystem integration.

## Code Quality Standards

All Swift code generated for any project must adhere to these quality standards:

- **Swift Concurrency Only**: Use only Swift's native concurrency features (async/await, Task, Actor, etc.) for all concurrent operations. Do not use GCD, OperationQueue, NSThread, or other legacy concurrency APIs. With MainActor as default actor isolation, use async/await patterns to prevent UI blocking. Use non-isolated functions or custom actors for long-running operations. Apply @MainActor attribute explicitly only when needed for clarity.
- **Memory Management**: Proper handling of reference cycles and memory lifecycle
- **Xcode Toolchain**: All development, building, and testing must use Xcode 26.1.1+
- **Swift Version**: Use Swift 6.2 for all code generation, fallback to Swift 6.1 only if functionality cannot be implemented
- **Human-Centric Code Structure**: All AI-generated code must be structured for human review and refinement, embracing modularity and avoiding monolithic files
- **UI Implementation**: All user interfaces must follow requirements in [SwiftUISpec.md](SwiftUISpec.md)

### Human-Centric Code Generation Requirements

**Code Structure for Human Collaboration:**
- **Modular Architecture**: Break down functionality into focused, single-responsibility modules
- **Review-Friendly File Sizes**: Keep files under 500 lines, ideally under 300 lines for easy review
- **Clear Separation of Concerns**: Separate business logic, UI components, data models, and utilities
- **Logical Code Organization**: Group related functionality with clear naming and structure
- **Documentation Integration**: Include inline documentation that explains complex logic for human reviewers

**Avoiding Monolithic Code Patterns:**
- ❌ Single massive files with multiple responsibilities
- ❌ Deep nesting and complex functions (>50 lines)
- ❌ Tight coupling between unrelated components
- ❌ Lack of clear abstraction boundaries
- ❌ Inadequate error handling and edge case coverage

**Embracing Modular Design Patterns:**
- ✅ Focused protocols and extensions for clean interfaces
- ✅ Dependency injection for testable, maintainable code
- ✅ Clear separation between view models, views, and services
- ✅ Well-defined data flow patterns (MVVM, observable objects)
- ✅ Comprehensive error handling with clear error types

**Human Review Optimization:**
- **Readable Code Structure**: Use consistent formatting and Swift style guidelines
- **Meaningful Naming**: Choose names that clearly convey intent and functionality
- **Progressive Complexity**: Start simple, allow for iterative refinement
- **Testable Components**: Design for easy unit testing and debugging
- **Documentation Comments**: Include clear explanations of complex algorithms and decisions

## SwiftUI Implementation Requirements

All SwiftUI implementation requirements and best practices are defined in [SwiftUISpec.md](SwiftUISpec.md). This includes:

- **Framework Requirements**: SwiftUI-only implementation, iOS 26.0+ compatibility
- **Architecture Patterns**: MVVM, state management, view composition
- **Human Interface Guidelines**: Layout, typography, interactions, component design
- **View Decomposition**: @ViewBuilder patterns for breaking down complex views
- **Type Safety**: Avoiding AnyView and using type-preserving alternatives
- **Declarative Programming**: Best practices for SwiftUI's declarative paradigm
- **Accessibility**: VoiceOver, Dynamic Type, motor accessibility requirements
- **Performance**: Lazy loading, rendering optimization, animation guidelines

AI code generators must follow all requirements specified in [SwiftUISpec.md](SwiftUISpec.md) for SwiftUI implementation.


## AI + Human Collaboration Approach

This project implements a structured AI + Human collaboration methodology where AI handles initial code generation and humans provide critical oversight, testing, and refinement.

### Full Codebase Regeneration Capability

**Critical Requirement**: At any time, a human developer must be able to request AI to regenerate the entire codebase from the current specifications without losing any functionality, except for functionality that has been intentionally removed from the specifications.

**Regeneration Guarantees:**
- **Complete Regeneration**: AI can regenerate all code files from specifications alone
- **Functionality Preservation**: No existing functionality is lost unless explicitly removed from specs
- **Specification as Source of Truth**: All code must be derivable from the specification files
- **Reproducible Development**: Any team member can regenerate the codebase from specs
- **Version Control Alignment**: Specification changes drive code regeneration, not vice versa

**Regeneration Process:**
1. **Specification Audit**: Ensure all current functionality is properly documented in specifications
2. **AI Regeneration Request**: Human requests complete codebase regeneration from specs
3. **Full Code Generation**: AI generates entire codebase based on current specifications
4. **Functionality Verification**: Confirm all previously working features remain functional
5. **Integration Testing**: Validate that regenerated code integrates properly with existing components
6. **Specification Updates**: Update specs if any functionality gaps are discovered during regeneration

### Roles and Responsibilities

**AI Responsibilities:**
- Generate initial Swift code based on specifications with human-centric structure
- Implement all user interfaces following requirements in [SwiftUISpec.md](SwiftUISpec.md)
- Implement modular, review-friendly code that avoids monolithic patterns
- Create focused, single-responsibility components under 300 lines each
- Implement algorithms using Swift best practices and idiomatic patterns
- Follow Swift-specific patterns from this specification
- Generate comprehensive unit tests using Swift Testing
- Include clear documentation for human reviewers
- Identify and attempt to resolve compilation errors

**Human Responsibilities:**
- Provide strategic oversight and final decision-making
- Design system architecture and component interactions
- Review and validate implementation against [SwiftUISpec.md](SwiftUISpec.md) requirements
- Review and refine AI-generated code structure for optimal human collaboration
- Validate modular design and separation of concerns
- Perform comprehensive testing and quality assurance including UI testing
- Refine and optimize code for performance and maintainability
- Ensure code remains review-friendly and maintainable
- Document lessons learned and update specifications

### Collaboration Workflow

1. **Specification Review**: Humans ensure specifications are clear and complete
2. **AI Code Generation**: AI generates code based on specifications and patterns
3. **Human Code Review**: Humans review, test, and refine AI-generated code
4. **Iterative Improvement**: AI incorporates feedback and regenerates improved code
5. **Joint Modifications**: AI and humans collaborate on code modifications, optimizations, and bug fixes
6. **Specification Updates**: All joint modifications must be reflected back into the relevant specifications (functional requirements, implementation patterns, or lessons learned)
7. **Final Validation**: Humans perform final testing and documentation
8. **Knowledge Capture**: Both AI and humans contribute to CodeGenLessonsLearned.md

### Specification Update Requirements

**Mandatory Updates After Joint Modifications:**
- **Functional Changes**: Update the project's functional specification with new features, requirements, or behavior changes
- **Implementation Patterns**: Update SwiftCodeGeneration.md with new patterns or best practices discovered
- **Error Solutions**: Document new error patterns and solutions in CodeGenLessonsLearned.md
- **API Changes**: Update DocumentationSpec.md with new documentation requirements if APIs change
- **Testing Requirements**: Update testing standards if new test patterns are established

**Update Process:**
1. **Identify Changes**: Document what was modified and why
2. **Update Specifications**: Modify relevant spec files to reflect the changes
3. **Version Control**: Commit specification updates with code changes
4. **Review**: Ensure specifications remain accurate and complete

## Code Generation Process and Testing

### 100% Error-Free Code Generation Requirement

All AI-generated code must be 100% error-free. Code generation is not complete until all compilation errors and logic errors are resolved through comprehensive testing.

### Swift Testing Integration

**For comprehensive testing patterns, requirements, and examples, see SwiftTestingSpec.md.**

**Mandatory Testing Process Overview:**
1. **Generate Code**: AI generates initial code based on specifications
2. **Compile Check**: Verify code compiles without errors using Xcode 26.1.1+
3. **Unit Test Generation**: Create comprehensive unit tests using Swift Testing framework (patterns in SwiftTestingSpec.md)
4. **Test Execution**: Run all tests to identify compilation and logic errors
5. **Error Analysis**: Reference lessons learned documentation for known error patterns and solutions
6. **Code Correction**: Fix identified errors using lessons learned and best practices
7. **Re-testing**: Re-run tests until 100% pass rate achieved
8. **Documentation Update**: Add new error patterns and solutions to lessons learned documentation

**Quality Gates:**
- ✅ Code compiles without warnings or errors
- ✅ All unit tests pass (100% success rate) - see SwiftTestingSpec.md for testing standards
- ✅ Code follows all quality standards (concurrency, memory management, etc.)
- ✅ Documentation is updated with any new lessons learned

## Swift 6 Concurrency with Default MainActor Isolation

**Swift 6 Context**: This section covers concurrency patterns for projects using Swift 6 with default actor isolation set to MainActor in compiler settings. This significantly changes how concurrency is handled compared to manual @MainActor annotation projects.

**Important**: Only Swift's native concurrency features (async/await, Task, Actor, etc.) should be used. Do not use legacy concurrency APIs like GCD, OperationQueue, NSThread, or DispatchQueue.

**Prohibited Legacy APIs**:
- `DispatchQueue.global().async { ... }`
- `OperationQueue`
- `Thread.detachNewThread { ... }`
- `NSThread`
- Any `@convention(c)` function pointers for concurrency

### Swift 6 + Default MainActor Architecture Principles

#### **Default Isolation Behavior**
- **Most classes are MainActor-isolated by default** - no explicit annotation needed
- **Explicit Nonisolation** - Use `nonisolated` for background processing classes/methods
- **Sendable Conformance** - All data transfer types must conform to Sendable
- **Actor Safety** - Leverage strict concurrency checking for data race prevention

#### **Observable Pattern (Swift 6 Preferred)**
```swift
// CORRECT: Use @Observable instead of @ObservableObject
@Observable  // MainActor by default - no explicit annotation needed
final class AppState {
    var currentUser: UserProfile?
    var isLoading: Bool = false
    var errorMessage: String?

    // Background operations explicitly nonisolated
    nonisolated func performBackgroundTask() async throws {
        // Background work properly isolated
    }
}

// AVOID: @ObservableObject is legacy pattern
// @MainActor  // Redundant with default isolation
// class AppState: ObservableObject {
//     @Published var isLoading = false
// }
```

### Default MainActor Isolation Patterns

#### **UI Classes (Automatic MainActor)**
```swift
// UI view models (MainActor by default)
@Observable
final class ContentListViewModel {
    private(set) var content: [ContentItem] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    func loadContent() {
        isLoading = true
        Task {
            do {
                let loadedContent = try await dataService.fetchContent()
                // UI updates automatically on MainActor
                self.content = loadedContent
                self.isLoading = false
            } catch {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
```

#### **Background Processing Classes (Explicit Nonisolated)**
```swift
// Background service (explicitly nonisolated)
nonisolated final class DataProcessor: Sendable {
    func processLargeDataset(_ data: [DataItem]) async throws -> [ProcessedItem] {
        // Heavy processing off main thread
        return try await withTaskGroup(of: ProcessedItem?.self) { group in
            for item in data {
                group.addTask {
                    return try await self.processItem(item)
                }
            }

            var results: [ProcessedItem] = []
            for try await result in group {
                if let processedItem = result {
                    results.append(processedItem)
                }
            }
            return results
        }
    }

    private func processItem(_ item: DataItem) async throws -> ProcessedItem {
        // Individual item processing
        return ProcessedItem(from: item)
    }
}
```

#### **Mixed Responsibility Classes**
```swift
// Class with both UI and background responsibilities
final class MixedResponsibilityClass {
    // UI methods (MainActor by default)
    func updateUI() {
        // UI updates here - automatically MainActor
    }

    // Background methods (explicitly nonisolated)
    nonisolated func processData() async throws -> ProcessedData {
        // Background processing
        return try await heavyComputation()
    }

    nonisolated private func heavyComputation() async throws -> ProcessedData {
        // Implementation
        return ProcessedData()
    }
}
```

### Sendable Conformance Patterns

#### **Data Transfer Types**
```swift
// CORRECT: Sendable conformance for cross-actor communication
struct UserProfile: Sendable {
    let id: UUID
    let name: String
    let preferences: UserPreferences
}

enum ContentType: String, CaseIterable, Codable, Sendable {
    case article = "article"
    case video = "video"
    case image = "image"
}

// CORRECT: Value types with nonisolated(unsafe) for isolation conflicts
nonisolated(unsafe) struct ValidationIssue: CustomStringConvertible, Equatable, Sendable {
    let field: String
    let issue: String

    var description: String {
        "\(field): \(issue)"
    }
}
```

#### **Error Types with Sendable**
```swift
enum AppError: LocalizedError, Sendable {
    case networkUnavailable
    case invalidData(String)
    case processingFailed(String)
    case actorIsolationViolation

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is currently unavailable"
        case .invalidData(let details):
            return "Invalid data: \(details)"
        case .processingFailed(let reason):
            return "Processing failed: \(reason)"
        case .actorIsolationViolation:
            return "Actor isolation violation detected"
        }
    }
}
```

### Key Path and Actor Isolation

#### **Avoiding Key Path Issues**
```swift
// INCORRECT: Key paths with actor-isolated properties
return "Validation failed: \(issues.map(\.description).joined(separator: ", "))"

// CORRECT: Use closure syntax instead
return "Validation failed: \(issues.map { $0.description }.joined(separator: ", "))"
```

### Error Prevention Checklist

1. **Assume MainActor isolation by default** - most classes don't need explicit annotation
2. **Use `nonisolated`** for background processing classes and methods
3. **Use `nonisolated(unsafe)`** for value types that have isolation conflicts
4. **Add `Sendable` conformance** to all data transfer types
5. **Avoid key paths** with actor-isolated properties - use closures instead
6. **Use `@Observable`** instead of `@ObservableObject` for new code

### Performance Considerations

#### **Actor Switching Optimization**
- Minimize actor switching with bulk operations
- Use `MainActor.run { }` sparingly - prefer natural async boundaries
- Leverage default MainActor isolation for UI operations
- Keep background processing truly background with `nonisolated`

#### **Memory Management (Actor-Safe)**
- Use `weak` references in closures to prevent retain cycles across actors
- Implement lazy loading for large datasets with proper isolation
- Cache frequently accessed content with Sendable conformance
- Avoid capturing strong references to MainActor objects in background tasks
- Use Task.detached() for fire-and-forget operations
- Consider @MainActor attribute only when explicit main thread execution is required

## Testing and Quality Assurance

For comprehensive testing requirements, patterns, and standards, see SwiftTestingSpec.md. Key requirements include:

- **Unit Testing**: Complete coverage of business logic, data models, and error handling
- **UI Testing**: User flows, accessibility, performance, and localization validation
- **Integration Testing**: Service integration and end-to-end workflow validation
- **Performance Testing**: Memory usage, concurrency, and performance benchmarks


## Swift Implementation Patterns

This section provides Swift-specific implementation guidance and patterns. Each section provides Swift-specific contracts, patterns, and architectural approaches for common implementation scenarios.

### Data Model Implementation

#### Swift Type System Contracts

**Value Types vs Reference Types:**
- **Structs** for immutable data models (User, Product, ContentItem)
- **Classes** only for reference-semantic types requiring identity (managers, services)
- **Actors** for thread-safe state management requiring isolation
- **Enums** for closed sets of values (Status, State)

**Swift Type Requirements:**
```swift
// Example contracts for data models
protocol IdentifiableModel {
    associatedtype ID: Hashable & Codable
    var id: ID { get }
}

protocol Timestampable {
    var createdAt: Date { get }
    var lastModified: Date? { get }
}
```

#### Codable Implementation Patterns

**Automatic Codable Synthesis:**
- Use `Codable` for all data models requiring JSON/API serialization
- Leverage automatic synthesis for simple structs
- Custom coding keys only when API contracts differ from Swift naming

**Coding Strategy Contract:**
```swift
struct CodingStrategy {
    // Use snake_case for JSON, camelCase for Swift properties
    static let jsonDecoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    static let jsonEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }()
}
```

### Authentication and Session Management

#### Swift Concurrency Contracts

**Authentication Service Contract:**
```swift
protocol AuthenticationService {
    func authenticate(email: String, password: String) async throws -> AuthenticationResult
    func refreshToken() async throws -> AuthenticationResult
    func logout() async
    func validateSession() async -> Bool
}
```

**Session State Management Pattern:**
```swift
@MainActor
@Observable
class AuthenticationManager {
    // Published properties automatically update UI
    private(set) var authenticationState: AuthenticationState

    // Async operations with proper error handling
    func login(email: String, password: String) async throws {
        // Implementation follows language-neutral auth flow
    }

    func checkSessionValidity() async -> Bool {
        // Implementation follows session management algorithm
    }
}
```

#### Error Handling Contracts

**Authentication Error Types:**
```swift
enum AuthenticationError: LocalizedError {
    case invalidCredentials
    case networkError(NetworkError)
    case sessionExpired
    case accountLocked

    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .sessionExpired:
            return "Your session has expired. Please log in again."
        case .accountLocked:
            return "Account temporarily locked due to security reasons"
        }
    }
}
```

### Data Management Patterns

#### Swift Collection and Filtering Contracts

**Generic Filtering Implementation:**
```swift
extension Array where Element: Filterable {
    func filterItems(filters: FilterCriteria) -> [Element] {
        // Implementation follows language-neutral filtering algorithm
        // Use Swift's filter, map, reduce operations
    }
}
```

**Comparison Algorithm Contract:**
```swift
struct ItemComparison<T: Comparable> {
    let valueDifference: T
    let betterValue: Bool
    let uniqueFeaturesA: [FeatureDescription]
    let uniqueFeaturesB: [FeatureDescription]
    let commonFeatures: [FeatureDescription]
    let categoryDifferences: [CategoryComparison]
    let qualityDifference: Int
    let performanceDifference: Int
}
```

#### Swift Generics for Type Safety

**Generic Data Management:**
```swift
protocol DataManageable {
    associatedtype DataType: IdentifiableModel
    associatedtype ConfigType: IdentifiableModel

    func createItem(configId: ConfigType.ID, parameters: Parameters) async throws -> DataType
    func updateItem(_ item: DataType, with config: ConfigType) async throws -> DataType
    func deleteItem(_ item: DataType, reason: DeletionReason) async throws
}
```

### Real-time Data Processing

#### Swift Concurrency for Real-time Updates

**Generic Data Monitor Contract:**
```swift
actor DataMonitor<T: Identifiable> {
    // Actor isolation ensures thread-safe monitoring state
    private var monitoredItems: [T.ID: T] = [:]
    private var updateHandlers: [T.ID: (T) async -> Void] = [:]

    func startMonitoring(itemId: T.ID, updateHandler: @escaping (T) async -> Void) {
        // Implementation follows monitoring algorithm
    }

    func processData(_ data: DataUpdate, for itemId: T.ID) async {
        // Implementation follows data processing algorithm
    }
}
```

#### Swift Result Types for Error Handling

**Processing Result Contract:**
```swift
enum ProcessingResult<T> {
    case success(T)
    case failure(ProcessingError)

    enum ProcessingError: Error {
        case connectionLost(duration: TimeInterval)
        case dataFailure(component: String)
        case dataCorruption
    }
}
```

### Configuration Management Patterns

#### Swift Validation Contracts

**Configuration Validator Protocol:**
```swift
protocol ConfigurationValidator {
    associatedtype ItemType: Configurable
    associatedtype SettingsType: ConfigurationSettings

    func validateConfiguration(_ settings: SettingsType, for item: ItemType, in context: Context) async throws -> ValidationResult
}

struct ValidationResult {
    let isValid: Bool
    let errors: [ValidationError]
    let warnings: [ValidationWarning]

    enum ValidationError: LocalizedError {
        case incompatibleConfiguration(item: String, context: String)
        case invalidRange(parameter: String, value: Any, range: ClosedRange<Any>)
        case configurationConflict(itemA: String, itemB: String)
        case limitExceeded(limit: Int, attempted: Int)
    }
}
```

#### Swift KeyPath for Type-Safe Configuration

**Configuration Preview Pattern:**
```swift
struct ConfigurationPreview<Settings: ConfigurationSettings> {
    let changedSettings: [PartialKeyPath<Settings>: Any]
    let impactAnalysis: ConfigurationImpact
    let simulationData: SimulationResult?
    let resourceUsage: ResourceUsage
    let recommendations: [ConfigurationRecommendation]
    let riskLevel: ConfigurationRisk
}
```

### State Management Architecture

#### ObservableObject and Combine Patterns

**Application State Structure:**
```swift
@MainActor
@Observable
class ApplicationState {
    // Published properties automatically update observing views
    private(set) var authentication = AuthenticationState()
    private(set) var data = DataState()
    private(set) var content = ContentState()
    private(set) var configuration = ConfigurationState()

    // Actions that modify state
    func dispatch(_ action: StateAction) async {
        switch action {
        case .loginSuccess(let user):
            authentication = AuthenticationState(isAuthenticated: true, currentUser: user)
        case .dataUpdated(let item):
            data.updateItem(item)
        // Additional action handling...
        }
    }
}
```

#### Swift Actor for State Synchronization

**State Synchronization Contract:**
```swift
actor StateSynchronizer {
    private let localState: ApplicationState
    private let apiClient: APIClient

    func synchronizeWithServer() async throws -> SynchronizationResult {
        // Implementation follows incremental sync algorithm
        // Use actor isolation for thread-safe state updates
    }

    func handleConflict(_ local: Any, server: Any, for keyPath: AnyKeyPath) async -> ConflictResolution {
        // Conflict resolution strategies
    }
}
```

### API Interaction Patterns

#### URLSession and Async/Await Contracts

**API Client Protocol:**
```swift
protocol APIClient {
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func request(_ endpoint: APIEndpoint) async throws
}

struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]?
    let body: Data?
    let queryParameters: [String: String]?

    enum HTTPMethod: String {
        case get = "GET"
        case post = "POST"
        case put = "PUT"
        case delete = "DELETE"
        case patch = "PATCH"
    }
}
```

#### Swift Result Builders for Request Building

**Request Builder Pattern:**
```swift
@resultBuilder
enum APIRequestBuilder {
    static func buildBlock(_ components: APIRequestComponent...) -> APIRequest {
        APIRequest(components: components)
    }
}

struct APIRequest {
    let components: [APIRequestComponent]

    func execute() async throws -> Data {
        // Build final request from components
        var urlComponents = URLComponents()
        var headers: [String: String] = [:]
        var body: Data?

        for component in components {
            switch component {
            case .path(let path):
                urlComponents.path = path
            case .header(let key, let value):
                headers[key] = value
            case .queryParameter(let key, let value):
                urlComponents.queryItems?.append(URLQueryItem(name: key, value: value))
            case .jsonBody(let encodable):
                body = try JSONEncoder().encode(encodable)
                headers["Content-Type"] = "application/json"
            }
        }

        // Execute request using URLSession
        let request = URLRequest(url: urlComponents.url!)
        request.allHTTPHeaderFields = headers
        request.httpBody = body

        let (data, response) = try await URLSession.shared.data(for: request)
        try validateResponse(response)
        return data
    }
}
```

### Error Handling and Recovery

#### Swift Error Types and Recovery Strategies

**Global Error Hierarchy:**
```swift
protocol AppError: LocalizedError {
    var recoveryStrategy: RecoveryStrategy { get }
    var shouldRetry: Bool { get }
    var userMessage: String { get }
}

enum RecoveryStrategy {
    case retryWithExponentialBackoff(maxAttempts: Int)
    case redirectToLogin
    case showValidationMessages([String])
    case showBusinessErrorMessage(String)
    case showGenericErrorAndReport
    case gracefulDegradation(DegradedMode)
}
```

#### Swift Throw/Catch with Async Context

**Error Recovery Implementation:**
```swift
func performOperation() async throws {
    do {
        try await potentiallyFailingOperation()
    } catch let error as AppError {
        switch error.recoveryStrategy {
        case .retryWithExponentialBackoff(let maxAttempts):
            try await retryWithBackoff(operation: potentiallyFailingOperation, maxAttempts: maxAttempts)
        case .redirectToLogin:
            await redirectToAuthentication()
        case .showValidationMessages(let messages):
            await showValidationAlert(messages)
        // Additional recovery strategies...
        }
    } catch {
        // Handle unexpected errors
        await showGenericError(error)
    }
}
```

### Performance Optimization Patterns

#### Swift Memory Management and Caching

**Cache Implementation Contract:**
```swift
protocol Cacheable {
    associatedtype Key: Hashable
    associatedtype Value

    func get(_ key: Key) -> Value?
    func set(_ value: Value, forKey key: Key, policy: CachePolicy)
    func remove(_ key: Key)
    func clear()
}

actor MemoryCache<Key: Hashable, Value>: Cacheable {
    private var storage: [Key: CacheEntry<Value>] = [:]

    struct CacheEntry<T> {
        let value: T
        let expirationDate: Date?
        let policy: CachePolicy
    }

    func get(_ key: Key) -> Value? {
        guard let entry = storage[key] else { return nil }
        if let expiration = entry.expirationDate, Date() > expiration {
            storage.removeValue(forKey: key)
            return nil
        }
        return entry.value
    }

    func set(_ value: Value, forKey key: Key, policy: CachePolicy) {
        let expirationDate = policy.calculateExpirationDate()
        storage[key] = CacheEntry(value: value, expirationDate: expirationDate, policy: policy)
    }
}
```

#### Swift Lazy Loading Patterns

**Lazy Loading Implementation:**
```swift
@propertyWrapper
struct LazyAsync<T> {
    private var _value: T?
    private let initializer: () async throws -> T

    init(wrappedValue: @autoclosure @escaping () -> T? = nil, initializer: @escaping () async throws -> T) {
        self._value = wrappedValue()
        self.initializer = initializer
    }

    var wrappedValue: T {
        get async throws {
            if let value = _value { return value }
            let value = try await initializer()
            _value = value
            return value
        }
    }
}
```

### Testing Patterns

For comprehensive testing patterns including Swift Testing framework contracts, mock implementation patterns, async testing, and performance testing, see SwiftTestingSpec.md.

### SwiftUI Integration Patterns

#### View Model Contracts

**Observable View Model Pattern:**
```swift
@MainActor
@Observable
class ContentListViewModel {
    // Published properties for SwiftUI binding
    private(set) var items: [ContentItem] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    private let dataService: DataService

    func loadItems() async {
        isLoading = true
        error = nil

        do {
            items = try await dataService.fetchAvailableItems()
        } catch let error {
            self.error = error
        }

        isLoading = false
    }

    func filterItems(_ filters: FilterCriteria) {
        // Implementation follows language-neutral filtering algorithm
        // Updates published properties automatically
    }
}
```

#### SwiftUI View Composition Patterns

**View Component Contracts:**
```swift
protocol ViewComponent: View {
    associatedtype ViewModel: Observable

    var viewModel: ViewModel { get }

    init(viewModel: ViewModel)
}

// Example implementation contract
struct ContentItemCard<ViewModel: ContentItemViewModel>: ViewComponent {
    let viewModel: ViewModel

    var body: some View {
        // SwiftUI implementation following SwiftUISpec.md requirements
        VStack {
            Text(viewModel.item.name)
            Text(viewModel.item.description)
            // Additional UI elements...
        }
    }
}
```

## Distribution Requirements

For TestFlight distribution, App Store compliance, and distribution documentation requirements, see DocumentationSpec.md.
