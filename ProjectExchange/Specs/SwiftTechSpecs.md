# Swift Technical Specifications

This document captures the "HOW" of implementing ProjectExchange functionality in Swift. It provides guidance on patterns and implementation approaches without complete solution code.

## Common Specifications Integration

This implementation must follow patterns and standards defined in the common specifications:
- **SwiftCodeGeneration.md**: Core Swift implementation guidance and Sendable conformance patterns
- **SwiftTestingSpec.md**: Comprehensive testing patterns using Swift Testing framework

## Transfer Object Patterns

### Struct Design

**Required Conformances**
- `Codable`: All transfer objects must support JSON encoding/decoding
- `Sendable`: All transfer objects must be safe for concurrent access
- `Identifiable`: Objects with UUID properties should conform for SwiftUI compatibility

**Design Guidelines**
- Use structs exclusively (value semantics, immutability)
- All properties should be `let` constants
- Provide public initializers with all parameters
- No dependencies on SwiftData or persistence frameworks
- No business logic or side effects in transfer objects

### Property Naming

**Naming Conventions**
- Match source model property names where semantically appropriate
- Use `originalFilePath` not `filePath` to clarify export-time resolution
- Use descriptive names for export-specific properties (e.g., `schemaVersion`)
- Avoid abbreviations except for well-known terms (URL, UUID, LLM)

**Property Documentation**
- Document deviations from source model naming
- Explain nullable properties and when they might be nil
- Note security-excluded properties in documentation comments

### Computed Properties

**Appropriate Uses**
- Formatted display values (e.g., `formattedFileSize`)
- Derived URL construction (e.g., `fullApiUrl`)
- Sorted or filtered collections (e.g., `sortedSections`)

**Avoid**
- Side effects in computed properties
- Network or file system access
- Heavy computation without caching

## Serialization Patterns

### JSON Encoder Configuration

**Required Settings**
- Date encoding strategy: `.iso8601` for portable timestamps
- Output formatting: `.prettyPrinted` for human readability

**Not Used**
- `.sortedKeys`: Not used because Swift's KeyedEncodingContainer does not preserve insertion order anyway; key ordering is not guaranteed

**Rationale**
- ISO8601 dates are timezone-aware and universally parseable
- Pretty printing aids debugging and manual inspection
- Key order is unspecified (Swift's JSONEncoder limitation)

### JSON Decoder Configuration

**Required Settings**
- Date decoding strategy: `.iso8601` matching encoder

**Error Handling**
- Catch decoding errors and wrap in domain-specific error types
- Provide meaningful error messages for common parsing failures
- Handle missing optional fields gracefully (nil values)

### Serializer Service Design

**Service Characteristics**
- Stateless design (no instance state beyond configuration)
- Thread-safe through Sendable conformance
- Static encoder/decoder instances for efficiency

**Method Categories**
- Export to Data, String, or file URL
- Import from Data, String, or file URL
- Validation helpers for round-trip testing

## Error Handling Patterns

### Error Enum Design

**Required Conformances**
- `LocalizedError`: Provide `errorDescription` for user-facing messages
- `Sendable`: Safe for concurrent error propagation

**Case Design**
- Separate cases for distinct failure modes
- Include associated values for context (e.g., error messages)
- Provide actionable error descriptions

**Error Categories**
- Encoding failures with underlying reason
- Decoding failures with parsing details
- File operation failures with path/permission info
- Schema version mismatches with expected vs found versions
- Validation failures with specific issues

## Testing Patterns

### Serialization Testing

**Round-Trip Tests**
- Create object → encode to JSON → decode from JSON → compare
- Verify all properties survive serialization unchanged
- Test with fully populated objects
- Test with minimal objects (all optionals nil)

**Edge Case Testing**
- Empty strings and empty arrays
- Maximum and minimum numeric values
- Special characters in text content
- Large content payloads

**Schema Validation**
- Verify schema version is present in output
- Test detection of version mismatches
- Validate JSON structure matches specification

### Test Fixture Patterns

**Factory Functions**
- Create helper functions that produce valid test objects
- Support customization through parameters
- Ensure test data is realistic but deterministic

## Package Structure

### Target Organization

**Main Target: ProjectExchange**
- All public transfer object types
- Serialization service
- Error types
- Enums for status and endpoint types

**Test Target: ProjectExchangeTests**
- Depends on main ProjectExchange target
- Uses Swift Testing framework
- Organized by component (serializer, models, errors)

### Platform Requirements

**Swift Version**
- Swift tools version 6.2+
- Full Swift 6 concurrency support

**Supported Platforms**
- iOS 17+
- macOS 14+
- visionOS 1+

### Import Requirements

**Foundation Only**
- No SwiftData dependency (portability requirement)
- No SwiftUI dependency (data layer only)
- No third-party dependencies

### File Organization

**Recommended Structure**
```
Sources/ProjectExchange/
├── Models/           # Transfer object structs
├── Enums/            # Status and type enumerations
├── Services/         # Serialization service
└── Errors/           # Error type definitions
```

## Versioning Patterns

### Schema Version Management

**Version Constant**
- Maintain current version as static constant
- Include version in all exported projects
- Update version when export format changes

**Compatibility Checking**
- Compare versions on import
- Support reading older versions where possible
- Reject unsupported future versions with clear error

---

*This specification provides implementation guidance without complete code solutions. Always generate and compile actual implementations rather than copying code snippets. All implementations must comply with referenced common specifications.*

---

**Last Updated**: 2026-03-03
**Swift Version**: 6.2 (swift-tools-version: 6.2)
**Note**: ProjectExchange is a Foundation-only Swift Package with no SwiftData or SwiftUI dependencies. Full Swift 6 strict concurrency applies (`Sendable` conformance required on all public types).
