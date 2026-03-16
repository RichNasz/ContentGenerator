# User Guide

Comprehensive guide for managing LLM connections with advanced patterns and best practices.

## Overview

This guide covers advanced usage patterns, connection management strategies, and integration techniques for LLMmanagement. Whether you're building a simple chat interface or a complex multi-model application, this guide provides the patterns you need.

## Connection Management Patterns

### Default Connection Handling

Manage default connections to simplify your application logic:

```swift
// Find the current default connection
@Query(filter: #Predicate<LLMConnection> { $0.isDefault == true })
private var defaultConnections: [LLMConnection]

var defaultConnection: LLMConnection? {
    defaultConnections.first
}

// Set a new default connection
func setAsDefault(_ connection: LLMConnection) {
    // First, clear existing defaults
    for conn in connections where conn.isDefault {
        conn.isDefault = false
    }

    // Set the new default
    connection.isDefault = true

    try? modelContext.save()
}
```

### Connection Categories and Filtering

Organize connections by service type or purpose:

```swift
extension LLMConnection {
    var serviceType: ServiceType {
        if apiUrl.contains("openai.com") {
            return .openAI
        } else if apiUrl.contains("anthropic.com") {
            return .anthropic
        } else if apiUrl.contains("localhost") || apiUrl.contains("127.0.0.1") {
            return .local
        } else {
            return .other
        }
    }

    enum ServiceType: String, CaseIterable {
        case openAI = "OpenAI"
        case anthropic = "Anthropic"
        case local = "Local"
        case other = "Other"
    }
}

// Filter connections by service type
struct ServiceConnectionsView: View {
    let serviceType: LLMConnection.ServiceType

    @Query private var allConnections: [LLMConnection]

    private var filteredConnections: [LLMConnection] {
        allConnections.filter { $0.serviceType == serviceType }
    }

    var body: some View {
        List(filteredConnections) { connection in
            ConnectionRowView(connection: connection)
        }
        .navigationTitle(serviceType.rawValue)
    }
}
```

### Connection Health Monitoring

Track connection status and usage patterns:

```swift
extension LLMConnection {
    var healthStatus: HealthStatus {
        guard isConfigured else { return .notConfigured }

        if let lastUsed = lastUsed {
            let daysSinceLastUse = Calendar.current.dateComponents([.day], from: lastUsed, to: Date()).day ?? 0
            if daysSinceLastUse > 30 {
                return .stale
            } else if daysSinceLastUse > 7 {
                return .inactive
            } else {
                return .active
            }
        } else {
            return .unused
        }
    }

    enum HealthStatus: String, CaseIterable {
        case active = "Active"
        case inactive = "Inactive"
        case stale = "Stale"
        case unused = "Unused"
        case notConfigured = "Not Configured"

        var color: Color {
            switch self {
            case .active: return .green
            case .inactive: return .yellow
            case .stale: return .orange
            case .unused: return .blue
            case .notConfigured: return .red
            }
        }

        var icon: String {
            switch self {
            case .active: return "checkmark.circle.fill"
            case .inactive: return "clock.fill"
            case .stale: return "exclamationmark.triangle.fill"
            case .unused: return "circle.fill"
            case .notConfigured: return "xmark.circle.fill"
            }
        }
    }
}
```

## SwiftUI Integration Patterns

### Connection Selection View

Create a comprehensive connection selection interface:

```swift
struct ConnectionSelectionView: View {
    @Query(sort: [SortDescriptor(\LLMConnection.name)])
    private var connections: [LLMConnection]

    @Binding var selectedConnection: LLMConnection?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            List {
                if connections.isEmpty {
                    ContentUnavailableView(
                        "No Connections",
                        systemImage: "network.slash",
                        description: Text("Create a connection to get started")
                    )
                } else {
                    ForEach(connections) { connection in
                        ConnectionSelectionRow(
                            connection: connection,
                            isSelected: selectedConnection?.id == connection.id
                        ) {
                            selectedConnection = connection
                            dismiss()
                        }
                    }
                }
            }
            .navigationTitle("Select Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink("New", destination: ConnectionEditView())
                }
            }
        }
    }
}

struct ConnectionSelectionRow: View {
    let connection: LLMConnection
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(connection.displayName)
                        .font(.headline)

                    Text(connection.selectedModel)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        Label(connection.healthStatus.rawValue,
                              systemImage: connection.healthStatus.icon)
                            .font(.caption2)
                            .foregroundColor(connection.healthStatus.color)

                        if connection.isDefault {
                            Label("Default", systemImage: "star.fill")
                                .font(.caption2)
                                .foregroundColor(.yellow)
                        }
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.blue)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
```

### Connection Configuration Form

Build a comprehensive configuration interface:

```swift
struct ConnectionEditView: View {
    @State private var connection: LLMConnection
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    private let isEditing: Bool

    init(connection: LLMConnection? = nil) {
        if let connection = connection {
            self._connection = State(initialValue: connection)
            self.isEditing = true
        } else {
            self._connection = State(initialValue: LLMConnection(name: ""))
            self.isEditing = false
        }
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Connection Name", text: $connection.name)
                    TextField("API URL", text: $connection.apiUrl)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    SecureField("API Key (Optional)", text: $connection.apiKey)
                }

                Section("Model Configuration") {
                    TextField("Model Name", text: $connection.selectedModel)
                        .autocapitalization(.none)

                    HStack {
                        Text("Timeout")
                        Spacer()
                        Text("\(connection.requestTimeoutSeconds)s")
                            .foregroundColor(.secondary)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(connection.requestTimeoutSeconds) },
                            set: { connection.requestTimeoutSeconds = Int($0) }
                        ),
                        in: 60...420,
                        step: 30
                    )
                }

                Section("Options") {
                    Toggle("Set as Default", isOn: $connection.isDefault)
                }

                Section("Status") {
                    HStack {
                        Text("Configuration Status")
                        Spacer()
                        Label(
                            connection.isConfigured ? "Complete" : "Incomplete",
                            systemImage: connection.isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                        )
                        .foregroundColor(connection.isConfigured ? .green : .orange)
                    }

                    if !connection.isConfigured {
                        Text("URL and Model are required")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Connection" : "New Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveConnection()
                    }
                    .disabled(!connection.isConfigured)
                }
            }
        }
    }

    private func saveConnection() {
        if !isEditing {
            modelContext.insert(connection)
        }

        // Handle default connection logic
        if connection.isDefault {
            // Clear other defaults
            let request = FetchDescriptor<LLMConnection>(
                predicate: #Predicate { $0.isDefault == true && $0.id != connection.id }
            )

            if let existingDefaults = try? modelContext.fetch(request) {
                for existing in existingDefaults {
                    existing.isDefault = false
                }
            }
        }

        try? modelContext.save()
        dismiss()
    }
}
```

## Advanced Usage Patterns

### Connection Backup and Restore

Implement connection data portability:

```swift
struct ConnectionBackup: Codable {
    let name: String
    let apiUrl: String
    let selectedModel: String
    let requestTimeoutSeconds: Int
    let isDefault: Bool
    let createdAt: Date

    init(from connection: LLMConnection) {
        self.name = connection.name
        self.apiUrl = connection.apiUrl
        self.selectedModel = connection.selectedModel
        self.requestTimeoutSeconds = connection.requestTimeoutSeconds
        self.isDefault = connection.isDefault
        self.createdAt = connection.createdAt
        // Note: API keys are intentionally excluded for security
    }

    func toLLMConnection() -> LLMConnection {
        let connection = LLMConnection(
            name: name,
            apiUrl: apiUrl,
            selectedModel: selectedModel,
            requestTimeoutSeconds: requestTimeoutSeconds,
            isDefault: isDefault
        )
        // Preserve original creation date
        connection.createdAt = createdAt
        return connection
    }
}

class ConnectionManager: ObservableObject {
    func exportConnections(_ connections: [LLMConnection]) -> Data? {
        let backups = connections.map { ConnectionBackup(from: $0) }
        return try? JSONEncoder().encode(backups)
    }

    func importConnections(from data: Data, modelContext: ModelContext) throws {
        let backups = try JSONDecoder().decode([ConnectionBackup].self, from: data)

        for backup in backups {
            let connection = backup.toLLMConnection()
            modelContext.insert(connection)
        }

        try modelContext.save()
    }
}
```

### Connection Templates

Create reusable connection templates:

```swift
struct ConnectionTemplate {
    let name: String
    let baseApiUrl: String
    let commonModels: [String]
    let defaultTimeout: Int
    let requiresApiKey: Bool

    static let templates: [ConnectionTemplate] = [
        ConnectionTemplate(
            name: "OpenAI",
            baseApiUrl: "https://api.openai.com/v1/chat/completions",
            commonModels: ["gpt-4", "gpt-4-turbo", "gpt-3.5-turbo"],
            defaultTimeout: 120,
            requiresApiKey: true
        ),
        ConnectionTemplate(
            name: "Anthropic Claude",
            baseApiUrl: "https://api.anthropic.com/v1/messages",
            commonModels: ["claude-3-opus-20240229", "claude-3-sonnet-20240229", "claude-3-haiku-20240307"],
            defaultTimeout: 150,
            requiresApiKey: true
        ),
        ConnectionTemplate(
            name: "Local Ollama",
            baseApiUrl: "http://localhost:11434/api/generate",
            commonModels: ["llama2", "mistral", "codellama"],
            defaultTimeout: 180,
            requiresApiKey: false
        )
    ]

    func createConnection(customName: String? = nil, model: String, apiKey: String = "") -> LLMConnection {
        return LLMConnection(
            name: customName ?? "\(name) - \(model)",
            apiUrl: baseApiUrl,
            apiKey: apiKey,
            selectedModel: model,
            requestTimeoutSeconds: defaultTimeout
        )
    }
}
```

## Performance Considerations

### Efficient Queries

Use optimized SwiftData queries for better performance:

```swift
// Good: Specific filtering at the database level
@Query(filter: #Predicate<LLMConnection> { $0.isDefault == true })
private var defaultConnections: [LLMConnection]

// Good: Sorting at the database level
@Query(sort: [SortDescriptor(\LLMConnection.lastUsed, order: .reverse)])
private var recentConnections: [LLMConnection]

// Good: Limit results when appropriate
@Query(sort: [SortDescriptor(\LLMConnection.lastUsed, order: .reverse)])
private var allConnections: [LLMConnection]

private var recentConnections: [LLMConnection] {
    Array(allConnections.prefix(5))
}
```

### Memory Management

Handle large numbers of connections efficiently:

```swift
struct ConnectionListView: View {
    @Query private var connections: [LLMConnection]

    var body: some View {
        List {
            // Use LazyVStack for large lists
            LazyVStack {
                ForEach(connections) { connection in
                    ConnectionRowView(connection: connection)
                        .id(connection.id)
                }
            }
        }
    }
}
```

## Troubleshooting

### Common Issues and Solutions

**Validation Failures**
- Ensure URLs include scheme and host
- Check that model names are not empty strings
- Remember API keys are optional for local services

**SwiftData Issues**
- Verify LLMConnection is in your Schema
- Check that model context is properly injected
- Ensure proper error handling around save operations

**Performance Issues**
- Use @Query filtering instead of computed properties
- Implement lazy loading for large datasets
- Consider pagination for very large connection lists

## Best Practices

1. **Always validate connections** before using them in production
2. **Use default connections** to simplify user experience
3. **Implement proper error handling** around network operations
4. **Track usage patterns** with updateLastUsed() calls
5. **Provide clear user feedback** for configuration states
6. **Consider security** when handling API keys
7. **Test with various connection types** including local services

## Next Steps

- Explore the <doc:API-Reference> for detailed method documentation
- Check out the inline documentation in ``LLMConnection`` for parameter details
- Consider implementing custom validation rules for your specific use case