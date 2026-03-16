# Getting Started

Learn how to integrate and use LLMmanagement in your Swift project.

## Overview

LLMmanagement is a Swift package that provides connection management for Large Language Model services with SwiftData persistence. This guide will walk you through installation, basic setup, and creating your first LLM connections.

## Installation

### Swift Package Manager

Add LLMmanagement to your project using Swift Package Manager:

1. In Xcode, select **File > Add Package Dependencies...**
2. Enter the package URL: `https://github.com/yourusername/LLMmanagement`
3. Select the version and add to your target

### Package.swift

If you're developing a Swift package, add LLMmanagement to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/LLMmanagement", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: ["LLMmanagement"]
    ),
]
```

## Platform Requirements

- **iOS**: 26.0 or later
- **macOS**: 26.0 or later
- **visionOS**: 26.0 or later
- **Xcode**: 26.1.1 or later
- **Swift**: 6.2 or later

## Basic Setup

### Import the Framework

```swift
import SwiftData
import LLMmanagement
```

### SwiftData Setup

LLMmanagement uses SwiftData for persistence. Configure your model container to include `LLMConnection`:

```swift
import SwiftUI
import SwiftData
import LLMmanagement

@main
struct MyApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            LLMConnection.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
```

## Creating Your First Connection

### OpenAI Connection

```swift
let openAIConnection = LLMConnection(
    name: "OpenAI GPT-4",
    apiUrl: "https://api.openai.com/v1/chat/completions",
    apiKey: "sk-your-openai-api-key-here",
    selectedModel: "gpt-4",
    requestTimeoutSeconds: 120,
    isDefault: true
)
```

### Local Ollama Connection

```swift
let ollamaConnection = LLMConnection(
    name: "Local Llama 2",
    apiUrl: "http://localhost:11434/api/generate",
    selectedModel: "llama2",
    requestTimeoutSeconds: 180
)
// Note: No API key needed for local Ollama
```

### Anthropic Claude Connection

```swift
let claudeConnection = LLMConnection(
    name: "Anthropic Claude",
    apiUrl: "https://api.anthropic.com/v1/messages",
    apiKey: "sk-ant-your-anthropic-api-key",
    selectedModel: "claude-3-sonnet-20240229",
    requestTimeoutSeconds: 150
)
```

## Using Connections in SwiftUI

### Basic Connection List

```swift
import SwiftUI
import SwiftData
import LLMmanagement

struct ConnectionListView: View {
    @Query private var connections: [LLMConnection]
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationView {
            List {
                ForEach(connections) { connection in
                    ConnectionRowView(connection: connection)
                }
                .onDelete(perform: deleteConnections)
            }
            .navigationTitle("LLM Connections")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addConnection()
                    }
                }
            }
        }
    }

    private func addConnection() {
        let newConnection = LLMConnection(name: "New Connection")
        modelContext.insert(newConnection)
    }

    private func deleteConnections(offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(connections[index])
        }
    }
}

struct ConnectionRowView: View {
    let connection: LLMConnection

    var body: some View {
        VStack(alignment: .leading) {
            Text(connection.displayName)
                .font(.headline)
            Text(connection.selectedModel)
                .font(.caption)
                .foregroundColor(.secondary)

            if connection.isConfigured {
                Label("Configured", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            } else {
                Label("Needs Configuration", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        }
    }
}
```

## Validation

Always check if a connection is properly configured before using it:

```swift
if connection.isConfigured {
    // Safe to use the connection
    connection.updateLastUsed()
    print("Using connection: \(connection.displayName)")
} else {
    // Handle incomplete configuration
    print("Connection \(connection.name) needs configuration")
}
```

## Next Steps

- Read the <doc:User-Guide> for comprehensive usage patterns
- Check the <doc:API-Reference> for detailed API documentation
- Explore connection management best practices

## Troubleshooting

### Common Issues

**SwiftData Model Container Errors**
- Ensure `LLMConnection` is included in your Schema
- Verify platform requirements are met (iOS 26.0+)

**Connection Validation Failures**
- Check that URLs include both scheme (`https://`) and host
- Ensure model names are not empty
- API keys are optional for local services

**Build Errors**
- Verify you're using Xcode 26.1.1+ with Swift 6.2+
- Check that platform deployment targets are set correctly