# SwiftData Implementation Patterns

## Purpose and Scope

This specification defines universal SwiftData patterns that can be applied across multiple Swift projects. It provides reusable protocols, data isolation techniques, and best practices for implementing robust, scalable data layers using SwiftData.

**Target Projects**: Any Swift project using SwiftData for data persistence
**Swift Version**: 6.2+ with strict concurrency checking
**Platform Compatibility**: iOS 26.0+, macOS 26.0+, watchOS 11.0+, tvOS 18.0+

## Relationship to Other Specifications

This specification complements:
- **SwiftCodeGeneration.md**: Swift 6 concurrency patterns that apply to SwiftData usage
- **SwiftUIWithoutMVVM.md**: State management patterns that integrate with SwiftData
- **Project-specific specs**: Implementation details for specific data models

## Universal SwiftData Protocols

### Core Model Protocols

#### **PersistentModel Protocol**
```swift
// Protocol for all SwiftData models across projects
protocol PersistentModel: Sendable {
    var id: UUID { get }
    var createdAt: Date { get }
    var modifiedAt: Date { get set }

    /// Update the modification timestamp
    mutating func updateModifiedDate()
}

// Default implementation
extension PersistentModel {
    mutating func updateModifiedDate() {
        modifiedAt = Date()
    }
}
```

#### **Relationship Management Protocol**
```swift
// Protocol for managing SwiftData relationships
protocol RelationshipManaging {
    associatedtype RelatedType: PersistentModel
    var relatedItems: [RelatedType] { get set }

    /// Add a related item with proper relationship setup
    mutating func addRelatedItem(_ item: RelatedType)

    /// Remove a related item and handle cleanup
    mutating func removeRelatedItem(_ item: RelatedType)
}

// Default implementation
extension RelationshipManaging where RelatedType: Equatable {
    mutating func addRelatedItem(_ item: RelatedType) {
        if !relatedItems.contains(item) {
            relatedItems.append(item)
        }
    }

    mutating func removeRelatedItem(_ item: RelatedType) {
        relatedItems.removeAll { $0 == item }
    }
}
```

### Model Definition Best Practices

#### **Standard Model Template**
```swift
// Template for SwiftData models
@Model
final class ExampleModel: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Model-specific properties
    var name: String
    var status: ExampleStatus

    // Relationships with proper syntax (prevents ERR-DATA-001)
    @Relationship(deleteRule: .cascade, inverse: \RelatedModel.parentExample)
    var relatedItems: [RelatedModel]

    init(name: String, status: ExampleStatus = .active) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.status = status
        self.relatedItems = []
    }

    /// Update timestamp on changes
    func updateModifiedDate() {
        modifiedAt = Date()
    }
}
```

#### **Enum Support (String-Backed for SwiftData)**
```swift
// SwiftData-compatible enum pattern
enum ExampleStatus: String, CaseIterable, Codable, Sendable {
    case draft = "draft"
    case active = "active"
    case archived = "archived"

    var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .active: return "Active"
        case .archived: return "Archived"
        }
    }

    var isEditable: Bool {
        switch self {
        case .draft, .active: return true
        case .archived: return false
        }
    }
}
```

## Data Isolation Patterns

### Project-Specific Data Isolation

#### **Single-Container Data Manager**
```swift
// Universal pattern for unified data storage with relationship-based isolation
@MainActor
@Observable
final class DataManager: Sendable {
    private let container: ModelContainer

    init(models: [any PersistentModel.Type]) throws {
        // Single container for all application data
        container = try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(
                url: applicationDataURL(),
                allowsSave: true
            )
        )
    }

    /// Get the unified application container
    func getContainer() -> ModelContainer {
        return container
    }

    /// Create a context for data operations
    func createContext() -> ModelContext {
        return ModelContext(container)
    }

    private func applicationDataURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory,
                                                    in: .userDomainMask).first!
        return documentsPath
            .appendingPathComponent("AppData")
            .appendingPathComponent("Application.sqlite")
    }
}
```

#### **Context-Scoped Data Service**
```swift
// Service layer that enforces data isolation through relationships and queries
nonisolated final class ContextDataService<T: PersistentModel>: Sendable {
    private let contextId: String
    private let dataManager: DataManager
    private let modelType: T.Type

    init(contextId: String, dataManager: DataManager, modelType: T.Type) {
        self.contextId = contextId
        self.dataManager = dataManager
        self.modelType = modelType
    }

    /// Fetch all items in this context using query-based isolation
    func fetchItems() async throws -> [T] {
        await MainActor.run {
            let context = dataManager.createContext()

            // Use predicate to filter by context (e.g., projectId)
            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate { item in
                    // This assumes T has a contextId property - adapt to your model
                    item.contextId == contextId
                },
                sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
            )

            do {
                return try context.fetch(descriptor)
            } catch {
                return []
            }
        }
    }

    /// Save item to this context
    func saveItem(_ item: T) async throws {
        await MainActor.run {
            let context = dataManager.createContext()

            context.insert(item)
            try? context.save()
        }
    }

    /// Delete item from this context
    func deleteItem(_ item: T) async throws {
        await MainActor.run {
            let context = dataManager.createContext()

            context.delete(item)
            try? context.save()
        }
    }

    /// Update existing item
    func updateItem(_ item: T) async throws {
        await MainActor.run {
            var mutableItem = item
            mutableItem.updateModifiedDate()

            let context = dataManager.createContext()
            try? context.save()
        }
    }
}
```

### Global Settings Pattern

#### **App Settings Model**
```swift
@Model
final class AppSettings: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date

    // Global settings properties
    var theme: AppTheme
    var autoSaveEnabled: Bool
    var dataBackupLocation: String?
    var lastBackupDate: Date?

    init(
        theme: AppTheme = .system,
        autoSaveEnabled: Bool = true,
        dataBackupLocation: String? = nil
    ) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.theme = theme
        self.autoSaveEnabled = autoSaveEnabled
        self.dataBackupLocation = dataBackupLocation
        self.lastBackupDate = nil
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }

    static func defaultSettings() -> AppSettings {
        return AppSettings()
    }
}

enum AppTheme: String, CaseIterable, Codable, Sendable {
    case light = "light"
    case dark = "dark"
    case system = "system"

    var displayName: String {
        switch self {
        case .light: return "Light"
        case .dark: return "Dark"
        case .system: return "System"
        }
    }
}
```

#### **Global Settings Service**
```swift
// Service for managing app-wide settings
nonisolated final class GlobalSettingsService: Sendable {
    private let dataManager: DataManager

    init(dataManager: DataManager) {
        self.dataManager = dataManager
    }

    func getSettings() async throws -> AppSettings {
        await MainActor.run {
            let context = dataManager.createContext()

            let descriptor = FetchDescriptor<AppSettings>()

            do {
                let settings = try context.fetch(descriptor)
                return settings.first ?? AppSettings.defaultSettings()
            } catch {
                return AppSettings.defaultSettings()
            }
        }
    }

    func updateSettings(_ settings: AppSettings) async throws {
        await MainActor.run {
            let context = dataManager.createContext()

            var mutableSettings = settings
            mutableSettings.updateModifiedDate()

            // Insert or update
            let existingDescriptor = FetchDescriptor<AppSettings>()

            do {
                let existing = try context.fetch(existingDescriptor)

                if existing.isEmpty {
                    context.insert(mutableSettings)
                }

                try context.save()
            } catch {
                // Handle error appropriately
            }
        }
        }

        try context.save()
    }
}
```

## Relationship Patterns

### One-to-Many Relationships

#### **Parent-Child Pattern**
```swift
@Model
final class ParentModel: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var name: String

    // One-to-many relationship
    @Relationship(deleteRule: .cascade)
    var children: [ChildModel]

    init(name: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.children = []
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class ChildModel: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var title: String

    // Many-to-one relationship (inverse)
    var parent: ParentModel?

    init(title: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.title = title
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}
```

### Many-to-Many Relationships

#### **Tagged Items Pattern**
```swift
@Model
final class TaggedItem: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var content: String

    // Many-to-many relationship
    @Relationship(inverse: \Tag.items)
    var tags: [Tag]

    init(content: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.content = content
        self.tags = []
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}

@Model
final class Tag: PersistentModel {
    var id: UUID
    var createdAt: Date
    var modifiedAt: Date
    var name: String

    // Many-to-many relationship (inverse)
    var items: [TaggedItem]

    init(name: String) {
        self.id = UUID()
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.name = name
        self.items = []
    }

    func updateModifiedDate() {
        modifiedAt = Date()
    }
}
```

## Error Handling for SwiftData

### Common SwiftData Errors

```swift
enum SwiftDataError: LocalizedError, Sendable {
    case containerCreationFailed(String)
    case modelNotFound(UUID)
    case relationshipViolation(String)
    case persistenceError(String)
    case contextIsolationViolation

    var errorDescription: String? {
        switch self {
        case .containerCreationFailed(let details):
            return "Failed to create data container: \(details)"
        case .modelNotFound(let id):
            return "Model not found with ID: \(id)"
        case .relationshipViolation(let details):
            return "Relationship constraint violation: \(details)"
        case .persistenceError(let details):
            return "Data persistence error: \(details)"
        case .contextIsolationViolation:
            return "Attempted to access data from wrong context"
        }
    }
}
```

## Performance Optimization

### Efficient Queries

#### **Predicate Patterns**
```swift
// Efficient predicate usage
extension ContextDataService {
    func fetchItemsByStatus(_ status: ExampleStatus) async throws -> [T] where T == ExampleModel {
        await MainActor.run {
            let context = dataManager.createContext()

            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate { item in
                    item.status == status && item.contextId == contextId
                },
                sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
            )

            do {
                return try context.fetch(descriptor)
            } catch {
                return []
            }
        }
    }

    func fetchRecentItems(limit: Int = 10) async throws -> [T] {
        await MainActor.run {
            let context = dataManager.createContext()

            let descriptor = FetchDescriptor<T>(
                predicate: #Predicate { item in
                    item.contextId == contextId
                },
                sortBy: [SortDescriptor(\.modifiedAt, order: .reverse)]
            )
            descriptor.fetchLimit = limit

            do {
                return try context.fetch(descriptor)
            } catch {
                return []
            }
        }
    }
}
```

### Batch Operations

#### **Efficient Bulk Updates**
```swift
extension ContextDataService {
    func batchUpdateItems(_ updates: [(T, (inout T) -> Void)]) async throws {
        await MainActor.run {
            let context = dataManager.createContext()

            for (item, updateBlock) in updates {
                var mutableItem = item
                updateBlock(&mutableItem)
                mutableItem.updateModifiedDate()
            }

            try? context.save()
        }
    }
}
```

## Testing Patterns

### Mock Data Manager

```swift
// Mock implementation for testing
@MainActor
@Observable
final class MockDataManager: Sendable {
    private let container: ModelContainer

    init(models: [any PersistentModel.Type]) throws {
        // Create in-memory container for testing
        container = try ModelContainer(
            for: Schema(models),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    /// Get the unified application container (same interface as DataManager)
    func getContainer() -> ModelContainer {
        return container
    }

    /// Create a context for data operations (same interface as DataManager)
    func createContext() -> ModelContext {
        return ModelContext(container)
    }
}
```

---

**Last Updated**: 2025-10-24
**Version**: 1.0.0
**Swift Version**: 6.2+ with Default MainActor Isolation

This specification provides reusable SwiftData patterns that can be applied across multiple projects while maintaining data isolation, type safety, and performance optimization.