# Navigation Patterns for SwiftUI Applications

## Purpose and Scope

This specification defines reusable navigation patterns for SwiftUI applications. It provides universal navigation architectures, state management patterns, and implementation guidelines that can be applied across multiple Swift projects.

**Target Projects**: Any SwiftUI application requiring structured navigation
**Platform Compatibility**: iOS 26.0+, macOS 26.0+, watchOS 11.0+, tvOS 18.0+
**Swift Version**: 6.2+ with strict concurrency checking

## Relationship to Other Specifications

This specification complements:
- **SwiftUISpec.md**: SwiftUI implementation standards for UI components
- **SwiftCodeGeneration.md**: Swift 6 concurrency patterns for navigation state
- **SwiftUIWithoutMVVM.md**: State management without traditional ViewModels

## NavigationSplitView Architectures

### Two-Column Split View Pattern

#### **Basic Two-Column Layout**
```swift
// Universal pattern for sidebar + content navigation
struct TwoColumnNavigationView<SidebarContent: View, MainContent: View>: View {
    @Binding var sidebarVisibility: NavigationSplitViewVisibility
    let sidebar: () -> SidebarContent
    let content: () -> MainContent

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            sidebar()
        } content: {
            content()
        }
    }
}
```

#### **Implementation Example**
```swift
struct AppNavigationView: View {
    @State private var selectedItem: SidebarItem?
    @State private var sidebarVisibility: NavigationSplitViewVisibility = .automatic

    var body: some View {
        TwoColumnNavigationView(sidebarVisibility: $sidebarVisibility) {
            AppSidebar(selection: $selectedItem)
        } content: {
            if let item = selectedItem {
                ContentDetailView(item: item)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "sidebar.left"
                )
            }
        }
    }
}
```

### Three-Column Split View Pattern

#### **Advanced Three-Column Layout**
```swift
// Universal pattern for sidebar + content + detail navigation
struct ThreeColumnNavigationView<SidebarContent: View, ContentView: View, DetailView: View>: View {
    @Binding var columnVisibility: NavigationSplitViewVisibility
    let sidebar: () -> SidebarContent
    let content: () -> ContentView
    let detail: () -> DetailView

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            sidebar()
        } content: {
            content()
        } detail: {
            detail()
        }
    }
}
```

## Universal Sidebar Patterns

### Sidebar Item Protocol

#### **Generic Sidebar Item Interface**
```swift
// Universal protocol for sidebar navigation items
protocol SidebarItemProtocol: Identifiable, Hashable, Sendable {
    var displayName: String { get }
    var systemImage: String { get }
    var description: String { get }
    var isSelectable: Bool { get }
}

// Default implementation
extension SidebarItemProtocol {
    var isSelectable: Bool { true }
}
```

### Multi-Section Sidebar Pattern

#### **Sectioned Sidebar Implementation**
```swift
// Universal sectioned sidebar with collapsible groups
struct SectionedSidebar<Item: SidebarItemProtocol>: View {
    let sections: [SidebarSection<Item>]
    @Binding var selection: Item?
    @Binding var expandedSections: Set<String>

    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                if section.isCollapsible {
                    Section(
                        section.title,
                        isExpanded: Binding(
                            get: { expandedSections.contains(section.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert(section.id)
                                } else {
                                    expandedSections.remove(section.id)
                                }
                            }
                        )
                    ) {
                        sectionContent(for: section)
                    }
                } else {
                    Section(section.title) {
                        sectionContent(for: section)
                    }
                }
            }
        }
        .navigationTitle("Navigation")
    }

    @ViewBuilder
    private func sectionContent(for section: SidebarSection<Item>) -> some View {
        ForEach(section.items) { item in
            SidebarItemRow(item: item)
                .tag(item)
        }

        if let actionButton = section.actionButton {
            actionButton
        }
    }
}

// Supporting structures
struct SidebarSection<Item: SidebarItemProtocol>: Identifiable {
    let id: String
    let title: String
    let items: [Item]
    let isCollapsible: Bool
    let actionButton: AnyView?

    init(
        id: String,
        title: String,
        items: [Item],
        isCollapsible: Bool = false,
        actionButton: AnyView? = nil
    ) {
        self.id = id
        self.title = title
        self.items = items
        self.isCollapsible = isCollapsible
        self.actionButton = actionButton
    }
}

struct SidebarItemRow<Item: SidebarItemProtocol>: View {
    let item: Item

    var body: some View {
        Label(item.displayName, systemImage: item.systemImage)
            .help(item.description)
    }
}
```

## Navigation State Management

### Observable Navigation State Pattern

#### **Universal Navigation State**
```swift
// Observable navigation state for SwiftUI apps
@Observable
final class NavigationState<Item: SidebarItemProtocol> {
    var selectedItem: Item?
    var expandedSections: Set<String> = []
    var sidebarVisibility: NavigationSplitViewVisibility = .automatic
    var navigationPath: NavigationPath = NavigationPath()

    // Selection management
    func selectItem(_ item: Item) {
        selectedItem = item
        // Clear any nested navigation when switching top-level items
        navigationPath = NavigationPath()
    }

    func clearSelection() {
        selectedItem = nil
        navigationPath = NavigationPath()
    }

    // Section management
    func toggleSection(_ sectionId: String) {
        if expandedSections.contains(sectionId) {
            expandedSections.remove(sectionId)
        } else {
            expandedSections.insert(sectionId)
        }
    }

    func expandSection(_ sectionId: String) {
        expandedSections.insert(sectionId)
    }

    func collapseSection(_ sectionId: String) {
        expandedSections.remove(sectionId)
    }

    // Deep navigation support
    func pushToPath<T: Hashable>(_ item: T) {
        navigationPath.append(item)
    }

    func popFromPath() {
        navigationPath.removeLast()
    }

    func popToRoot() {
        navigationPath = NavigationPath()
    }
}
```

### State Persistence Pattern

#### **Navigation State Persistence**
```swift
// Universal pattern for persisting navigation state
@Observable
final class PersistentNavigationState<Item: SidebarItemProtocol & Codable>: NavigationState<Item> {
    private let userDefaults = UserDefaults.standard
    private let selectedItemKey: String
    private let expandedSectionsKey: String

    init(selectedItemKey: String, expandedSectionsKey: String) {
        self.selectedItemKey = selectedItemKey
        self.expandedSectionsKey = expandedSectionsKey
        super.init()
        loadState()
    }

    override func selectItem(_ item: Item) {
        super.selectItem(item)
        saveSelectedItem()
    }

    override func toggleSection(_ sectionId: String) {
        super.toggleSection(sectionId)
        saveExpandedSections()
    }

    private func loadState() {
        // Load selected item
        if let data = userDefaults.data(forKey: selectedItemKey),
           let item = try? JSONDecoder().decode(Item.self, from: data) {
            selectedItem = item
        }

        // Load expanded sections
        let sections = userDefaults.stringArray(forKey: expandedSectionsKey) ?? []
        expandedSections = Set(sections)
    }

    private func saveSelectedItem() {
        if let item = selectedItem,
           let data = try? JSONEncoder().encode(item) {
            userDefaults.set(data, forKey: selectedItemKey)
        } else {
            userDefaults.removeObject(forKey: selectedItemKey)
        }
    }

    private func saveExpandedSections() {
        userDefaults.set(Array(expandedSections), forKey: expandedSectionsKey)
    }
}
```

## Deep Navigation Patterns

### NavigationStack Integration

#### **Nested Navigation Pattern**
```swift
// Universal pattern for nested navigation within split view content
struct NestedNavigationContent<Item: SidebarItemProtocol, RootView: View>: View {
    let item: Item
    @Binding var navigationPath: NavigationPath
    let rootView: (Item) -> RootView

    var body: some View {
        NavigationStack(path: $navigationPath) {
            rootView(item)
                .navigationTitle(item.displayName)
                .navigationDestination(for: DetailItem.self) { detailItem in
                    DetailView(item: detailItem)
                }
                .navigationDestination(for: EditItem.self) { editItem in
                    EditView(item: editItem)
                }
        }
    }
}

// Supporting types for navigation destinations
struct DetailItem: Hashable, Identifiable {
    let id: UUID
    let title: String
    let content: String
}

struct EditItem: Hashable, Identifiable {
    let id: UUID
    let title: String
    var content: String
}
```

### Deep Linking Support

#### **URL-Based Navigation**
```swift
// Universal deep linking support
struct DeepLinkHandler<Item: SidebarItemProtocol> {
    private let navigationState: NavigationState<Item>

    init(navigationState: NavigationState<Item>) {
        self.navigationState = navigationState
    }

    func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let path = components.path.split(separator: "/").first else {
            return
        }

        // Parse the URL and navigate accordingly
        if let item = findItem(matching: String(path)) {
            navigationState.selectItem(item)

            // Handle nested navigation if present
            let remainingPath = components.path.split(separator: "/").dropFirst()
            for pathComponent in remainingPath {
                if let detailId = UUID(uuidString: String(pathComponent)) {
                    let detailItem = DetailItem(id: detailId, title: "Detail", content: "Content")
                    navigationState.pushToPath(detailItem)
                }
            }
        }
    }

    private func findItem(matching identifier: String) -> Item? {
        // Implementation depends on specific Item type
        // This would be implemented in the specific project
        return nil
    }
}
```

## Platform-Specific Adaptations

### iOS Navigation Patterns

#### **Tab-Based Navigation for iOS**
```swift
// Universal tab-based navigation for iOS
struct iOSTabNavigation<Item: SidebarItemProtocol>: View {
    let items: [Item]
    @Binding var selection: Item?

    var body: some View {
        TabView(selection: $selection) {
            ForEach(items) { item in
                NavigationStack {
                    ContentView(for: item)
                        .navigationTitle(item.displayName)
                }
                .tabItem {
                    Label(item.displayName, systemImage: item.systemImage)
                }
                .tag(item)
            }
        }
    }
}
```

### macOS Navigation Patterns

#### **macOS-Optimized Split View**
```swift
// macOS-specific navigation optimizations
struct macOSNavigationView<Item: SidebarItemProtocol>: View {
    @Binding var selection: Item?
    @Binding var sidebarVisibility: NavigationSplitViewVisibility
    let items: [Item]

    var body: some View {
        NavigationSplitView(columnVisibility: $sidebarVisibility) {
            Sidebar(items: items, selection: $selection)
                .navigationSplitViewColumnWidth(
                    min: 200,
                    ideal: 250,
                    max: 300
                )
        } content: {
            if let selectedItem = selection {
                ContentView(for: selectedItem)
            } else {
                ContentUnavailableView(
                    "Select an Item",
                    systemImage: "sidebar.left",
                    description: Text("Choose an item from the sidebar to view its details")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}
```

## Accessibility Support

### Navigation Accessibility

#### **Accessible Navigation Implementation**
```swift
extension SidebarItemRow {
    var body: some View {
        Label(item.displayName, systemImage: item.systemImage)
            .help(item.description)
            .accessibilityLabel(item.displayName)
            .accessibilityHint(item.description)
            .accessibilityAddTraits(item.isSelectable ? .isButton : [])
    }
}

extension SectionedSidebar {
    var body: some View {
        List(selection: $selection) {
            ForEach(sections) { section in
                if section.isCollapsible {
                    Section(
                        section.title,
                        isExpanded: Binding(
                            get: { expandedSections.contains(section.id) },
                            set: { isExpanded in
                                if isExpanded {
                                    expandedSections.insert(section.id)
                                } else {
                                    expandedSections.remove(section.id)
                                }
                            }
                        )
                    ) {
                        sectionContent(for: section)
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel(section.title)
                    .accessibilityHint("Expandable section")
                } else {
                    Section(section.title) {
                        sectionContent(for: section)
                    }
                }
            }
        }
        .navigationTitle("Navigation")
        .accessibilityLabel("Main navigation")
    }
}
```

## Performance Considerations

### Lazy Loading Navigation

#### **Efficient Content Loading**
```swift
// Universal pattern for lazy-loading navigation content
struct LazyNavigationContent<Item: SidebarItemProtocol>: View {
    let item: Item
    @State private var isLoaded = false

    var body: some View {
        Group {
            if isLoaded {
                LoadedContentView(item: item)
            } else {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task {
            if !isLoaded {
                // Simulate async loading
                try? await Task.sleep(for: .milliseconds(100))
                isLoaded = true
            }
        }
    }
}
```

### Memory Management

#### **Efficient State Management**
```swift
// Memory-efficient navigation state
@Observable
final class MemoryEfficientNavigationState<Item: SidebarItemProtocol> {
    private(set) var selectedItem: Item?
    private var itemCache: [String: Any] = [:]
    private let maxCacheSize = 10

    func selectItem(_ item: Item) {
        selectedItem = item
        pruneCache()
    }

    func cacheData<T>(for itemId: String, data: T) {
        itemCache[itemId] = data
        pruneCache()
    }

    func getCachedData<T>(for itemId: String, as type: T.Type) -> T? {
        return itemCache[itemId] as? T
    }

    private func pruneCache() {
        if itemCache.count > maxCacheSize {
            let keysToRemove = Array(itemCache.keys.prefix(itemCache.count - maxCacheSize))
            for key in keysToRemove {
                itemCache.removeValue(forKey: key)
            }
        }
    }
}
```

## Testing Patterns

### Navigation Testing

#### **Mock Navigation State**
```swift
// Mock implementation for testing navigation
final class MockNavigationState<Item: SidebarItemProtocol>: NavigationState<Item> {
    var selectionHistory: [Item] = []

    override func selectItem(_ item: Item) {
        super.selectItem(item)
        selectionHistory.append(item)
    }

    func clearHistory() {
        selectionHistory.removeAll()
    }
}
```

---

**Last Updated**: 2025-10-24
**Version**: 1.0.0
**Swift Version**: 6.2+ with Default MainActor Isolation

This specification provides reusable navigation patterns that can be adapted for various SwiftUI applications while maintaining consistency, accessibility, and performance optimization.