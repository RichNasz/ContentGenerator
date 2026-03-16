# API Reference

Complete reference documentation for all public APIs in the LLMmanagement package.

## Overview

The LLMmanagement package provides a single primary class, ``LLMConnection``, which serves as a SwiftData model for managing Large Language Model service connections. This reference documents all public properties, initializers, and methods.

## Core Classes

### LLMConnection

``LLMConnection`` is the primary class in the LLMmanagement package. It represents a configured connection to an LLM service with automatic SwiftData persistence.

```swift
@Model
final class LLMConnection {
    // Properties and methods documented below
}
```

## Properties

### Identity and Naming

#### ``LLMConnection/id``
```swift
@Attribute(.unique) var id: UUID
```
Unique identifier for the connection that persists across sessions. Automatically generated when creating new connections.

#### ``LLMConnection/name``
```swift
var name: String
```
Human-readable name for the connection used in user interfaces. Choose descriptive names like "OpenAI GPT-4" or "Local Ollama".

#### ``LLMConnection/displayName``
```swift
var displayName: String { get }
```
The name to display in user interfaces. Currently returns the same value as `name`, but provides semantic distinction for display purposes.

### Connection Configuration

#### ``LLMConnection/apiUrl``
```swift
var apiUrl: String
```
The API endpoint URL for the LLM service. Must be a valid URL with scheme and host.

**Examples:**
- `https://api.openai.com/v1/chat/completions`
- `http://localhost:11434/api/generate`

#### ``LLMConnection/apiKey``
```swift
var apiKey: String
```
The API key for authenticating with the LLM service. This field is optional to support local services that don't require authentication.

#### ``LLMConnection/selectedModel``
```swift
var selectedModel: String
```
The specific model to use with this connection. Examples include "gpt-4", "gpt-3.5-turbo", "llama2", "mistral".

#### ``LLMConnection/requestTimeoutSeconds``
```swift
var requestTimeoutSeconds: Int
```
Request timeout in seconds, automatically clamped to 60-600 seconds (1-10 minutes). The timeout value is enforced within reasonable limits to prevent excessively long waits or too-short timeouts.

### Status and Metadata

#### ``LLMConnection/isConfigured``
```swift
var isConfigured: Bool { get }
```
Indicates whether the connection has sufficient configuration to be usable. Returns `true` when the connection has:
- A valid API URL with scheme and host
- A non-empty model selection

The API key is optional to support local services.

#### ``LLMConnection/createdAt``
```swift
var createdAt: Date
```
The date and time when this connection was created. Automatically set during initialization.

#### ``LLMConnection/lastUsed``
```swift
var lastUsed: Date?
```
The date and time when this connection was last used. `nil` for newly created connections that haven't been used yet. Update using ``LLMConnection/updateLastUsed()``.

## Initializers

### Primary Initializer

#### ``LLMConnection/init(name:apiUrl:apiKey:selectedModel:requestTimeoutSeconds:isDefault:)``

```swift
init(
    name: String,
    apiUrl: String = "",
    apiKey: String = "",
    selectedModel: String = "",
    requestTimeoutSeconds: Int = 120,
    isDefault: Bool = false
)
```

Creates a new LLM connection with the specified configuration.

**Parameters:**
- `name`: A human-readable name for the connection
- `apiUrl`: The API endpoint URL (optional, defaults to empty string)
- `apiKey`: The API key for authentication (optional, defaults to empty string)
- `selectedModel`: The model to use with this connection (optional, defaults to empty string)
- `requestTimeoutSeconds`: Request timeout in seconds (optional, defaults to 120, clamped to 60-600)
- `isDefault`: Whether this should be the default connection (optional, defaults to false)

The initializer automatically generates a unique ID and sets the creation timestamp. The timeout value is automatically clamped to the valid range of 60-600 seconds (1-10 minutes).

**Example:**
```swift
let connection = LLMConnection(
    name: "My OpenAI Connection",
    apiUrl: "https://api.openai.com/v1/chat/completions",
    apiKey: "sk-...",
    selectedModel: "gpt-4",
    requestTimeoutSeconds: 180
)
```

### Copy Initializer

#### ``LLMConnection/init(copying:name:apiUrl:apiKey:selectedModel:requestTimeoutSeconds:isDefault:)``

```swift
init(
    copying original: LLMConnection,
    name: String,
    apiUrl: String,
    apiKey: String,
    selectedModel: String,
    requestTimeoutSeconds: Int,
    isDefault: Bool
)
```

Creates a new connection by copying configuration from an existing connection. This initializer preserves the original connection's identity (ID), creation date, and usage history while allowing updates to configuration parameters.

**Parameters:**
- `original`: The original connection to copy identity and timestamps from
- `name`: The new human-readable name for the connection
- `apiUrl`: The new API endpoint URL
- `apiKey`: The new API key for authentication
- `selectedModel`: The new model to use with this connection
- `requestTimeoutSeconds`: The new request timeout in seconds (clamped to 60-600)
- `isDefault`: Whether this should be the default connection

Use this initializer when updating an existing connection's configuration while maintaining its identity and history for SwiftData persistence.

**Example:**
```swift
let updatedConnection = LLMConnection(
    copying: existingConnection,
    name: "Updated Connection Name",
    apiUrl: existingConnection.apiUrl,
    apiKey: "new-api-key",
    selectedModel: "gpt-4-turbo",
    requestTimeoutSeconds: 240,
    isDefault: true
)
```

## Methods

### ``LLMConnection/updateLastUsed()``

```swift
func updateLastUsed()
```

Updates the last used timestamp to the current date and time. Call this method when the connection is successfully used to make an API request, allowing for usage tracking and analytics.

**Example:**
```swift
// After successfully using the connection
connection.updateLastUsed()
print(connection.lastUsed) // Current timestamp
```

## Validation and Error Handling

### URL Validation

Connections use internal URL validation to ensure API URLs are properly formatted. The validation requires:

- Valid URL format that can be parsed by Foundation's `URL(string:)`
- Presence of a scheme (like "https" or "http")
- Presence of a host component

**Valid URLs:**
- `https://api.openai.com/v1/chat/completions`
- `http://localhost:11434/api/generate`

**Invalid URLs:**
- `api.openai.com` (missing scheme)
- `https://` (missing host)
- `not-a-url` (invalid format)

### Configuration Validation

Use the ``LLMConnection/isConfigured`` property to validate connections before use:

```swift
if connection.isConfigured {
    // Safe to use the connection
    connection.updateLastUsed()
    // Proceed with API call
} else {
    // Handle incomplete configuration
    print("Connection needs configuration")
    // Show configuration UI
}
```

## SwiftData Integration

### Model Configuration

Include `LLMConnection` in your SwiftData schema:

```swift
let schema = Schema([
    LLMConnection.self,
    // ... other models
])
```

### Queries

Use SwiftData queries to work with connections:

```swift
// Get all connections
@Query private var connections: [LLMConnection]

// Get default connection
@Query(filter: #Predicate<LLMConnection> { $0.isDefault == true })
private var defaultConnections: [LLMConnection]

// Get recently used connections
@Query(sort: [SortDescriptor(\LLMConnection.lastUsed, order: .reverse)])
private var recentConnections: [LLMConnection]

// Get configured connections only
@Query(filter: #Predicate<LLMConnection> { $0.isConfigured == true })
private var configuredConnections: [LLMConnection]
```

## Platform Requirements

- **iOS**: 26.0 or later
- **macOS**: 26.0 or later
- **visionOS**: 26.0 or later
- **Swift**: 6.2 or later
- **Xcode**: 26.1.1 or later

## Thread Safety

`LLMConnection` is a SwiftData model and follows SwiftData's threading model:

- Access instances only from the model context's associated actor
- Use `@MainActor` when updating properties from UI code
- Ensure proper model context isolation when working across different actors

## Performance Considerations

- Use SwiftData queries with predicates for efficient filtering
- Limit query results when working with large datasets
- Consider lazy loading patterns for UI with many connections
- Use `@Query` instead of computed properties for database operations

## Migration and Compatibility

When updating the LLMmanagement package:

- SwiftData automatically handles schema migrations for new properties
- Check release notes for any breaking changes to public API
- Test thoroughly with existing connection data
- Consider backup and restore functionality for critical applications

## See Also

- <doc:Getting-Started> - Installation and basic setup
- <doc:User-Guide> - Advanced usage patterns and best practices
- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata) - Apple's official SwiftData documentation