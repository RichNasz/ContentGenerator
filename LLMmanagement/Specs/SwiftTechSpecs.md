# Swift Technical Specifications

This document captures the "HOW" of implementing LLMmanagement functionality in Swift. It provides guidance on protocols, signatures, and implementation patterns without complete solution code.

## Common Specifications Integration

This implementation must follow patterns and standards defined in the common specifications:
- **SwiftCodeGeneration.md**: Core Swift implementation guidance, concurrency patterns, and code quality standards
- **SwiftUISpec.md**: SwiftUI implementation requirements, architecture patterns, and view composition
- **SwiftUIWithoutMVVM.md**: Alternative SwiftUI architectural patterns if traditional MVVM is not suitable
- **SwiftTestingSpec.md**: Comprehensive testing patterns using Swift Testing framework
- **DocumentationSpec.md**: Documentation standards for Swift packages and API documentation

## Implementation Guidelines

### SwiftData Model Patterns

**LLMConnection Model**
- Use `@Model` decorator for SwiftData persistence
- Apply `@Attribute(.unique)` to `id: UUID` property
- Implement proper initializers with parameter validation
- Include copy initializer pattern for creating updated instances while preserving identity
- Use computed properties for validation logic rather than stored validation state

**OpenAI Endpoint Type Enum**
- Define `OpenAIEndpointType` enum with `String` and `Codable` conformance
- Include `chatCompletions` and `responses` cases with raw values
- Provide `defaultPath` computed property returning standard OpenAI paths
- Provide `displayName` computed property for UI display
- Make enum `CaseIterable` for picker/selection interfaces

**Property Constraints**
- Clamp timeout values to 60-600 seconds (1-10 minutes) in initializers using `max(60, min(600, value))`
- Validate base URLs using `URL(string:)` and check for `scheme` and `host` properties
- Trim whitespace from string inputs before validation
- Display timeout values in minutes:seconds format (e.g., "2:30" for 150 seconds)
- Handle optional urlPath by converting empty strings to nil in initializers
- Combine baseUrl and urlPath (or endpoint default) to create full API URL

### Concurrency Patterns

**MainActor Usage**
- Mark UI-related methods with `@MainActor` decorator
- Use for methods that create services or update UI state
- Apply to factory methods that will be called from UI contexts

### Validation Patterns

**Configuration Validation**
- Implement `isConfigured` as computed property
- Combine multiple validation checks using logical operators
- Make API keys optional to support local services
- Validate base URL format and model selection as required fields
- urlPath is optional and validation is not required (uses endpoint default if empty)

**URL Validation Helper**
- Create private helper method `isValidURL(_: String) -> Bool`
- Use `URL(string:)` initialization to test validity
- Check for presence of `scheme` and `host` properties
- Validate base URLs separately from path components

**Full URL Construction**
- Implement `fullApiUrl` computed property to combine base URL and path
- Use custom urlPath if provided, otherwise use endpointType.defaultPath
- Handle trailing/leading slashes properly in URL construction

### Error Handling Patterns

**Service Creation**
- Use do-catch blocks for service initialization
- Print error messages for debugging while returning nil for failures
- Handle service creation failures gracefully without throwing

### Property Organization

**Stored Properties**
- Group related properties logically
- Use meaningful property names that reflect business domain
- Apply appropriate access control (private for helpers, public for API)

**Computed Properties**
- Provide convenience accessors like `displayName`
- Implement validation logic as computed properties
- Use computed properties for derived state rather than storing redundant data

### Initialization Patterns

**Default Parameter Values**
- Provide sensible defaults for optional configuration
- Use empty strings for optional string parameters
- Set reasonable timeout defaults (e.g., 120 seconds)

**Parameter Validation in Initializers**
- Validate and clamp values immediately in initializer
- Generate UUIDs automatically for new instances
- Set timestamps (`createdAt`, `lastUsed`) appropriately

### Method Signatures

**Factory Methods**
- `createAIService(promptManager:)` — returns an optional `AIService?`; prints errors internally and returns `nil` on failure

**State Update Methods**
- `updateLastUsed()` — sets `lastUsed` to the current date

**Validation Methods**
- `isConfigured: Bool` — computed property combining URL and model checks
- `isValidURL(_:)` — private helper taking a `String`, returning `Bool`

### Testing Patterns

**Model Testing**
- Test initialization with valid and invalid parameters
- Verify constraint enforcement (timeout clamping)
- Test validation logic with edge cases
- Verify copy initializer preserves identity and timestamps

**Property Testing**
- Test computed properties with various input combinations
- Verify URL validation with malformed URLs
- Test configuration validation with missing required fields

### SwiftUI View Implementation Patterns

**Connection Management Views**
- Follow SwiftUISpec.md requirements for view composition and architecture
- Views use direct @State for connection management state (no ViewModel layer)
- Implement proper error handling and validation feedback patterns
- Apply accessibility requirements from SwiftUISpec.md

**State Management Pattern (Direct @State)**

Views manage state directly with no ViewModel layer. `LLMConnectionListView` holds `@State private var llmConnections: [LLMConnection]`, `searchText: String`, and `showingDeleteConfirmation: Bool` as direct state properties. Data is loaded by calling `modelContext.fetch(FetchDescriptor<LLMConnection>())` directly inside a helper method — not through `@Query`.

**SwiftUI + SwiftData Integration**
- Use manual `ModelContext` fetch for data loading (not @Query)
- Implement proper model context passing patterns
- Follow SwiftData persistence patterns with SwiftUI lifecycle

**Error Handling in SwiftUI**
- Implement error presentation patterns following SwiftUISpec.md
- Use proper alert and sheet presentation for validation feedback
- Apply error recovery patterns for network and validation errors

### Testing Patterns for SwiftUI

**View Testing**
- Apply SwiftUISpec.md testing requirements for view components
- Test accessibility compliance and Dynamic Type support
- Verify proper error state presentation and user interaction flows

### Package Structure

**Target Organization**
- Main target: `LLMmanagement`
- Test target: `LLMmanagementTests` with dependency on main target
- Swift tools version: 6.2+

**Import Requirements**
- `Foundation` for basic types (UUID, Date, URL)
- `SwiftData` for persistence model decorators
- `SwiftUI` for view components and @Observable patterns

**Architecture Compliance**
- Follow SwiftCodeGeneration.md concurrency requirements
- Implement SwiftUISpec.md view composition patterns
- Apply SwiftTestingSpec.md testing standards
- Use @MainActor patterns for UI-related operations

---

*This specification provides implementation guidance without complete code solutions. Always generate and compile actual implementations rather than copying code snippets. All implementations must comply with referenced common specifications.*

---

**Last Updated**: 2026-03-27
**Swift Version**: 6.2 (swift-tools-version: 6.2)
**Note**: LLMmanagement is a Swift Package — `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` is an Xcode build setting that does NOT apply when building the package standalone with `swift build`. Explicit `@MainActor` annotations are required on UI-facing methods.