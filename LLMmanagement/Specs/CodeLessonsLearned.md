# Code Lessons Learned

This file tracks compilation errors encountered during AI code generation and their solutions. This creates a feedback loop to improve error resolution speed and consistency.

## How to Use This File

1. **Before fixing any error**: Search this file for the error message or similar issues
2. **After solving a new error**: Add the error and solution to this file
3. **Keep solutions specific**: Include exact error messages and precise solutions
4. **Update regularly**: This file should grow with each development session

## Error Categories

### Swift Compilation Errors

### Error: Public SwiftData model requires public properties
**Error Message**:
```
error: property 'id' must be declared public because it matches a requirement in public protocol 'Identifiable'
```

**Solution**:
When a SwiftData @Model class is declared public, all its properties must also be declared public to satisfy protocol requirements. Make all stored properties public:
```swift
@Model
public final class LLMConnection {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var apiUrl: String
    // ... all other properties must be public
}
```

**Context**: Occurs when making a SwiftData model public for library/framework use
**Common Spec Reference**: SwiftCodeGeneration.md - access control patterns
**Date Added**: 2025-10-21

### SwiftData Model Errors

### Error: SwiftData availability requirements not met in Swift Package
**Error Message**:
```
error: 'Model()' is only available in macOS 14 or newer
error: 'Attribute(_:originalName:hashModifier:)' is only available in macOS 14 or newer
```

**Solution**:
Add platform availability to Package.swift to specify minimum deployment targets for SwiftData support. Update Package.swift with platforms specification (using latest platform versions for modern Swift features):
```swift
let package = Package(
    name: "LLMmanagement",
    platforms: [
        .iOS(.v26),
        .macOS(.v26),
        .visionOS(.v26)
    ],
    // ... rest of package configuration
)
```

**Context**: Occurs when using SwiftData @Model decorator in Swift Package without specifying minimum platform versions
**Common Spec Reference**: SwiftCodeGeneration.md - mentions iOS 26.0+ target but SwiftData requires explicit platform specification in Package.swift
**Date Added**: 2025-10-21

### SwiftUI Implementation Errors

### Error: Environment modelContext access in Swift packages
**Error Message**:
```
error: no exact matches in call to initializer
@Environment(\.modelContext) private var modelContext
error: cannot infer key path type from context; consider explicitly specifying a root type
```

**Solution**:
For Swift packages targeting multiple platforms, inject ModelContext as a parameter instead of using @Environment:
```swift
// Instead of @Environment(\.modelContext)
private let modelContext: ModelContext

public init(modelContext: ModelContext) {
    self.modelContext = modelContext
    // ... other initialization
}
```
This provides better cross-platform compatibility and clearer dependency injection.

**Context**: Occurs in Swift packages when SwiftData environment keys need explicit typing
**Common Spec Reference**: SwiftUISpec.md - cross-platform considerations
**Date Added**: 2025-10-21

### Error: Platform-specific SwiftUI APIs in cross-platform packages
**Error Message**:
```
error: 'navigationBarLeading' is unavailable in macOS
error: 'navigationBarTitleDisplayMode' has been explicitly marked unavailable here
error: value of type 'TextField<Text>' has no member 'keyboardType'
```

**Solution**:
Use platform-appropriate APIs or conditional compilation:
```swift
#if os(iOS)
.keyboardType(.URL)
.autocapitalization(.none)
#endif

// Use cross-platform toolbar placements
.toolbar {
    ToolbarItem(placement: .cancellationAction) { ... }
    ToolbarItem(placement: .confirmationAction) { ... }
}
```

**Context**: Occurs when targeting multiple platforms with iOS-specific SwiftUI APIs
**Common Spec Reference**: SwiftUISpec.md - platform compatibility requirements
**Date Added**: 2025-10-21

### SwiftUI + SwiftData Integration Errors
*No entries yet*

### @Observable View Model Errors
*No entries yet*

### Swift Package Manager Errors
*No entries yet*

### Testing Errors
*No entries yet*

### SwiftUI Testing Errors
*No entries yet*

### Accessibility Implementation Errors
*No entries yet*

### Swift Concurrency with SwiftUI Errors
*No entries yet*

## Template for New Entries

```
### Error: [Brief description]
**Error Message**:
```
[Exact error message]
```

**Solution**:
[Detailed solution with code examples if applicable]

**Context**: [When this typically occurs]
**Common Spec Reference**: [Which common spec contains related guidance]
**Date Added**: [YYYY-MM-DD]
```

## Error Pattern Guidelines

**When documenting errors, consider these contexts**:
- **SwiftUI Errors**: Reference SwiftUISpec.md compliance issues
- **SwiftData Errors**: Model definition and persistence patterns
- **Integration Errors**: SwiftUI + SwiftData integration challenges
- **Testing Errors**: Swift Testing framework issues, reference SwiftTestingSpec.md
- **Concurrency Errors**: @MainActor and async/await patterns, reference SwiftCodeGeneration.md
- **Package Manager Errors**: Swift Package specific compilation issues
- **Accessibility Errors**: VoiceOver, Dynamic Type, and accessibility implementation issues

**Cross-Reference with Common Specs**:
- Always note which common specification contains related guidance
- Include specific sections or patterns that should be followed
- Document when project-specific patterns deviate from common spec standards

---

*This file is automatically maintained during AI code generation sessions and should capture learning from both project-specific and common specification contexts.*

---

**Last Updated**: 2026-03-03
**Swift Version**: 6.2 (swift-tools-version: 6.2)