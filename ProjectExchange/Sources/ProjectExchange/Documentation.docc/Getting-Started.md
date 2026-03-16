# Getting Started with ProjectExchange

Learn how to integrate ProjectExchange into your Swift project and perform basic import/export operations.

## Overview

This guide walks you through adding ProjectExchange to your project and performing your first export and import operations.

## Adding the Package

### Swift Package Manager

Add ProjectExchange as a local package dependency in your `Package.swift`:

```swift
let package = Package(
    name: "YourApp",
    dependencies: [
        .package(path: "../ProjectExchange")
    ],
    targets: [
        .target(
            name: "YourApp",
            dependencies: ["ProjectExchange"]
        )
    ]
)
```

### Xcode Integration

1. Open your project in Xcode
2. Select File > Add Package Dependencies
3. Click "Add Local..." and navigate to the ProjectExchange directory
4. Add the package to your target

## Your First Export

Create an exportable project and serialize it to JSON:

```swift
import ProjectExchange

// Create project data
let section = ExportableSection(
    name: "Introduction",
    sectionDescription: "Project overview",
    content: "This is the introduction section.",
    orderIndex: 0,
    contentGenerationPrompt: "Write an engaging introduction",
    contentUsagePrompt: nil,
    isEnabled: true,
    llmConnectionId: nil,
    createdAt: Date(),
    modifiedAt: Date()
)

let specification = ExportableSpecification(
    createdAt: Date(),
    modifiedAt: Date(),
    sections: [section]
)

let project = ExportableProject(
    name: "My First Project",
    projectDescription: "A sample project for testing export",
    status: .active,
    systemPrompt: "You are a helpful assistant.",
    createdAt: Date(),
    modifiedAt: Date(),
    specification: specification,
    attachmentMetadata: [],
    llmConnectionId: nil,
    llmConfigurations: []
)

// Export to JSON
let serializer = ProjectSerializer()
let jsonString = try serializer.exportToString(project)
print(jsonString)
```

## Your First Import

Import a project from JSON data:

```swift
import ProjectExchange

let jsonString = """
{
    "schemaVersion": "1.0.0",
    "name": "Imported Project",
    "status": "active",
    "createdAt": "2026-01-05T12:00:00Z",
    "modifiedAt": "2026-01-05T12:00:00Z",
    "attachmentMetadata": [],
    "llmConfigurations": []
}
"""

let serializer = ProjectSerializer()
let project = try serializer.importProject(from: jsonString)
print("Imported: \(project.name)")
```

## Exporting to a File

Save a project directly to a file:

```swift
let fileURL = FileManager.default
    .urls(for: .documentDirectory, in: .userDomainMask)[0]
    .appendingPathComponent("project-backup.json")

try serializer.export(project, to: fileURL)
```

## Importing from a File

Load a project from a file:

```swift
let project = try serializer.importProject(from: fileURL)
```

## Validating Round-Trip Integrity

Verify that a project can be exported and re-imported without data loss:

```swift
let isValid = serializer.validateRoundTrip(project)
if isValid {
    print("Project passes round-trip validation")
} else {
    print("Warning: Data may be lost during export/import")
}
```

## Error Handling

Handle common errors during import/export:

```swift
do {
    let project = try serializer.importProject(from: invalidData)
} catch ProjectExchangeError.decodingFailed(let message) {
    print("Failed to decode: \(message)")
} catch ProjectExchangeError.invalidJSONString {
    print("The provided string is not valid JSON")
} catch ProjectExchangeError.fileOperationFailed(let message) {
    print("File operation failed: \(message)")
} catch {
    print("Unexpected error: \(error)")
}
```

## Next Steps

- Read the <doc:User-Guide> for comprehensive usage patterns
- Explore the <doc:API-Reference> for complete API documentation
- Review the security considerations for production use
