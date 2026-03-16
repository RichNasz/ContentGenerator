# Error Resolution Database

## Purpose and Scope

This specification defines a **living knowledge base** that captures compilation errors, test failures, and runtime issues encountered during AI code generation for the LLMmanagement package, along with their proven fixes. This system enables instant error resolution, enforces consistency across the codebase, and creates a self-improving AI development environment.

**Critical Requirement**: Every error encountered must be documented with its proven solution to prevent re-solving the same problems and ensure consistent fixes throughout the codebase.

**Swift 6 + Default MainActor Context**: This project uses Swift 6 with default actor isolation set to MainActor, which changes common error patterns compared to manual @MainActor annotation projects.

## Quick Reference Index

- [High-Frequency Errors](#high-frequency-errors)
- [Compilation Errors](#compilation-errors)
- [SwiftData Errors](#swiftdata-errors)
- [SwiftUI Errors](#swiftui-errors)
- [Test Failure Errors](#test-failure-errors)
- [Runtime Errors](#runtime-errors)
- [Search Guidelines](#search-guidelines)

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

### ERR-SWIFT-001: Public SwiftData Model Requires Public Properties
- **Discovery Method**: Compilation
- **Frequency**: 1
- **Error Message**: `error: property 'id' must be declared public because it matches a requirement in public protocol 'Identifiable'`
- **Test Case**: N/A
- **Context**: When a SwiftData @Model class is declared public for library/framework use, all stored properties must also be declared public to satisfy protocol requirements
- **Root Cause**: Swift access control requires protocol conformance members to be at least as visible as the conforming type
- **Proven Fix**: Make all stored properties public on public @Model classes
- **Code Before**:
```swift
@Model
public final class LLMConnection {
    @Attribute(.unique) var id: UUID
    var name: String
    var apiUrl: String
}
```
- **Code After**:
```swift
@Model
public final class LLMConnection {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var apiUrl: String
}
```
- **Prevention Pattern**: When declaring a @Model class as public, always declare all stored properties as public
- **Verification**: Compilation succeeds without access control errors
- **Related Errors**: None
- **Last Updated**: 2025-10-21

---

## Compilation Errors

### ERR-DATA-001: SwiftData Availability Requirements Not Met in Swift Package
- **Discovery Method**: Compilation
- **Frequency**: 1
- **Error Message**: `error: 'Model()' is only available in macOS 14 or newer` / `error: 'Attribute(_:originalName:hashModifier:)' is only available in macOS 14 or newer`
- **Test Case**: N/A
- **Context**: Using SwiftData @Model decorator in Swift Package without specifying minimum platform versions in Package.swift
- **Root Cause**: SwiftData requires explicit platform availability specification in Package.swift; without it, the package defaults to older deployment targets that predate SwiftData
- **Proven Fix**: Add platform availability to Package.swift with minimum deployment targets that support SwiftData
- **Code Before**:
```swift
let package = Package(
    name: "LLMmanagement",
    // No platforms specified
    products: [...]
)
```
- **Code After**:
```swift
let package = Package(
    name: "LLMmanagement",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    products: [...]
)
```
- **Prevention Pattern**: Always specify platform targets in Package.swift when using SwiftData or other framework-version-dependent APIs
- **Verification**: `swift build` succeeds without availability errors
- **Related Errors**: ERR-UI-002
- **Last Updated**: 2025-10-21

---

## SwiftData Errors

*No additional SwiftData-specific errors beyond those in Compilation Errors.*

---

## SwiftUI Errors

### ERR-UI-001: Environment modelContext Access in Swift Packages
- **Discovery Method**: Compilation
- **Frequency**: 1
- **Error Message**: `error: no exact matches in call to initializer` / `error: cannot infer key path type from context; consider explicitly specifying a root type`
- **Test Case**: N/A
- **Context**: Swift packages targeting multiple platforms using `@Environment(\.modelContext)` for SwiftData access
- **Root Cause**: SwiftData environment keys need explicit typing in Swift packages; the key path inference fails in cross-platform package contexts
- **Proven Fix**: Inject ModelContext as a parameter instead of using @Environment
- **Code Before**:
```swift
@Environment(\.modelContext) private var modelContext
```
- **Code After**:
```swift
private let modelContext: ModelContext

public init(modelContext: ModelContext) {
    self.modelContext = modelContext
}
```
- **Prevention Pattern**: Use dependency injection for ModelContext in Swift packages rather than @Environment
- **Verification**: Package compiles for all target platforms
- **Related Errors**: ERR-DATA-001
- **Last Updated**: 2025-10-21

### ERR-UI-002: Platform-Specific SwiftUI APIs in Cross-Platform Packages
- **Discovery Method**: Compilation
- **Frequency**: 1
- **Error Message**: `error: 'navigationBarLeading' is unavailable in macOS` / `error: 'navigationBarTitleDisplayMode' has been explicitly marked unavailable here` / `error: value of type 'TextField<Text>' has no member 'keyboardType'`
- **Test Case**: N/A
- **Context**: Targeting multiple platforms (iOS, macOS, visionOS) with iOS-specific SwiftUI APIs
- **Root Cause**: Some SwiftUI APIs are platform-specific and not available on all targets
- **Proven Fix**: Use platform-appropriate APIs or conditional compilation with `#if os()`
- **Code Before**:
```swift
.toolbar {
    ToolbarItem(placement: .navigationBarLeading) { ... }
}
.keyboardType(.URL)
.autocapitalization(.none)
```
- **Code After**:
```swift
.toolbar {
    ToolbarItem(placement: .cancellationAction) { ... }
    ToolbarItem(placement: .confirmationAction) { ... }
}
#if os(iOS)
.keyboardType(.URL)
.autocapitalization(.none)
#endif
```
- **Prevention Pattern**: Use cross-platform toolbar placements and wrap iOS-specific modifiers in `#if os(iOS)` blocks
- **Verification**: `swift build` succeeds on all target platforms
- **Related Errors**: ERR-UI-001
- **Last Updated**: 2025-10-21

---

## Test Failure Errors

*No entries yet.*

---

## Runtime Errors

*No entries yet.*

---

## Search Guidelines

**When searching for error solutions in this file:**

1. **Search by error message**: Copy the exact compiler error text and search for it
2. **Search by category**: Browse the relevant section (Compilation, SwiftData, SwiftUI, etc.)
3. **Search by error ID**: Use the ERR-XXX-NNN format to find specific entries
4. **Check related errors**: Follow Related Errors links for similar issues

**When documenting new errors:**

- **Swift Compilation Errors**: Reference SwiftCodeGeneration.md compliance issues
- **SwiftData Errors**: Model definition and persistence patterns
- **SwiftUI Errors**: Reference SwiftUISpec.md for cross-platform considerations
- **Testing Errors**: Swift Testing framework issues, reference SwiftTestingSpec.md
- **Concurrency Errors**: @MainActor and async/await patterns, reference SwiftCodeGeneration.md
- **Package Manager Errors**: Swift Package specific compilation issues

**Cross-Reference with Common Specs**:
- Always note which common specification contains related guidance
- Include specific sections or patterns that should be followed
- Document when project-specific patterns deviate from common spec standards

---

*This file is automatically maintained during AI code generation sessions and should capture learning from both project-specific and common specification contexts.*

---

**Last Updated**: 2026-03-16
**Swift Version**: 6.2 (swift-tools-version: 6.2)
