# SwiftUI Without MVVM Specification

## Purpose and Scope

This specification defines SwiftUI development practices that eliminate the need for traditional Model-View-ViewModel (MVVM) patterns. Based on Apple's SwiftUI design philosophy and modern SwiftUI development practices, this guide demonstrates how to build robust, maintainable SwiftUI applications without ViewModels.

**Key Principle**: SwiftUI's declarative architecture and built-in state management primitives (@State, @ObservedObject, @StateObject, @Environment, etc.) provide superior alternatives to traditional ViewModels. ViewModels are unnecessary architectural baggage from UIKit that doesn't align with SwiftUI's design.

## Relationship to Other Specifications

This specification complements existing SwiftUI development guidelines:

- **SwiftUISpec.md**: Provides comprehensive SwiftUI implementation standards that this specification builds upon
- **SwiftCodeGeneration.md**: Defines Swift-specific patterns that work with SwiftUI's native state management
- **SwiftTestingSpec.md**: Testing patterns for ViewModel-free SwiftUI code

## SwiftUI's Built-in State Management Philosophy

### The MVVM Trap in SwiftUI

When SwiftUI launched in 2019, many developers brought UIKit architectural patterns that were designed to solve UIKit's problems:

- **UIKit Problems**: Massive View Controllers, imperative UI updates, weak type safety
- **UIKit Solution**: MVVM to separate concerns and enable testing

**SwiftUI is not UIKit.** SwiftUI was designed from the ground up with:

- Declarative UI programming
- Built-in state management
- Type-safe data flow
- Automatic UI updates
- Built-in testing capabilities

### Apple's SwiftUI Data Flow Philosophy

As highlighted in Apple's WWDC presentations ("Data Flow Through SwiftUI"), SwiftUI provides:

```swift
// ✅ SWIFTUI WAY: Built-in state management
struct ContentView: View {
    @State private var searchText = ""
    @State private var items: [Item] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            List(filteredItems) { item in
                ItemRow(item: item)
            }
            .searchable(text: $searchText)
            .overlay {
                if isLoading {
                    ProgressView()
                }
            }
        }
        .task {
            await loadItems()
        }
    }

    private var filteredItems: [Item] {
        if searchText.isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await apiService.fetchItems()
        } catch {
            // Handle error
        }
    }
}
```

## State Management Patterns Without ViewModels

### @State for Local View State

```swift
struct SearchView: View {
    @State private var query = ""
    @State private var results: [SearchResult] = []
    @State private var isSearching = false

    var body: some View {
        VStack {
            TextField("Search", text: $query)
                .onSubmit {
                    Task { await performSearch() }
                }

            if isSearching {
                ProgressView()
            } else {
                List(results) { result in
                    SearchResultRow(result: result)
                }
            }
        }
    }

    private func performSearch() async {
        guard !query.isEmpty else { return }

        isSearching = true
        defer { isSearching = false }

        do {
            results = try await searchService.search(query: query)
        } catch {
            // Handle error
        }
    }
}
```

### @Observable for Modern State Management (Swift 6 Preferred)

**Swift 6 Recommendation**: Use `@Observable` instead of `@ObservableObject` for new code. The Observable pattern is more efficient and works better with Swift 6 concurrency.

```swift
// ✅ MODERN: @Observable pattern (Swift 6 + Default MainActor)
@Observable
final class ItemStore {  // MainActor by default - no explicit annotation needed
    private(set) var items: [Item] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func loadItems() async {
        isLoading = true
        errorMessage = nil

        do {
            items = try await apiClient.fetchItems()
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    func addItem(_ item: Item) async throws {
        let newItem = try await apiClient.createItem(item)
        items.append(newItem)
    }

    func deleteItem(_ item: Item) async throws {
        try await apiClient.deleteItem(id: item.id)
        items.removeAll { $0.id == item.id }
    }

    func clearError() {
        errorMessage = nil
    }
}

struct ItemListView: View {
    @State private var store = ItemStore(apiClient: APIClient())

    var body: some View {
        List {
            ForEach(store.items) { item in
                ItemRow(item: item)
                    .swipeActions {
                        Button(role: .destructive) {
                            Task { try? await store.deleteItem(item) }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
            }
        }
        .overlay {
            if store.isLoading {
                ProgressView()
            }
        }
        .task {
            await store.loadItems()
        }
        .refreshable {
            await store.loadItems()
        }
        .alert("Error", isPresented: .constant(store.errorMessage != nil)) {
            Button("OK") {
                store.clearError()
            }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
```

### @StateObject for Legacy ObservableObject (Compatibility)

For compatibility with existing code or when working with third-party libraries that use `ObservableObject`:

```swift
// ⚠️ LEGACY: @ObservableObject pattern (use only for compatibility)
@MainActor
final class LegacyItemStore: ObservableObject {
    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false

    private let apiClient: APIClientProtocol

    init(apiClient: APIClientProtocol) {
        self.apiClient = apiClient
    }

    func loadItems() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await apiClient.fetchItems()
        } catch {
            // Handle error
        }
    }
}

struct LegacyItemListView: View {
    @StateObject private var store = LegacyItemStore(apiClient: APIClient())

    var body: some View {
        List {
            ForEach(store.items) { item in
                ItemRow(item: item)
            }
        }
        .task {
            await store.loadItems()
        }
    }
}
```

### Mixed UI and Background Processing with @Observable

```swift
// ✅ PATTERN: Mixed responsibilities with proper actor isolation
@Observable
final class DataProcessingStore {
    private(set) var processedItems: [ProcessedItem] = []
    private(set) var isProcessing = false
    private(set) var progress: Double = 0.0

    private let dataProcessor: DataProcessor

    init(dataProcessor: DataProcessor) {
        self.dataProcessor = dataProcessor
    }

    // UI updates (MainActor by default)
    func startProcessing() {
        isProcessing = true
        progress = 0.0

        Task {
            await performProcessing()
        }
    }

    // Background processing (explicitly nonisolated)
    nonisolated private func performProcessing() async {
        // Heavy processing off main thread
        let items = await dataProcessor.processLargeDataset()

        // Update UI on main actor
        await MainActor.run {
            self.processedItems = items
            self.isProcessing = false
            self.progress = 1.0
        }
    }
}
```

### @EnvironmentObject for Shared State

```swift
@MainActor
class UserSession: ObservableObject {
    @Published private(set) var currentUser: User?
    @Published private(set) var isAuthenticated = false

    private let authService: AuthenticationService

    init(authService: AuthenticationService) {
        self.authService = authService
    }

    func signIn(email: String, password: String) async throws {
        let user = try await authService.authenticate(email: email, password: password)
        currentUser = user
        isAuthenticated = true
    }

    func signOut() async {
        try? await authService.signOut()
        currentUser = nil
        isAuthenticated = false
    }
}

// In App struct
@main
struct MyApp: App {
    @StateObject private var session = UserSession(authService: AuthenticationService())

    var body: some Scene {
        WindowGroup {
            if session.isAuthenticated {
                MainTabView()
                    .environmentObject(session)
            } else {
                SignInView()
                    .environmentObject(session)
            }
        }
    }
}

// Usage in views
struct ProfileView: View {
    @EnvironmentObject private var session: UserSession

    var body: some View {
        if let user = session.currentUser {
            VStack {
                Text("Welcome, \(user.name)!")
                Button("Sign Out") {
                    Task { await session.signOut() }
                }
            }
        }
    }
}
```

## Complex Business Logic Without ViewModels

### Computed Properties and Business Logic

```swift
struct OrderSummaryView: View {
    @StateObject private var orderStore: OrderStore

    var body: some View {
        VStack {
            // Business logic in computed properties
            if hasDiscount {
                DiscountBanner(discount: discountAmount)
            }

            OrderItemsList(items: orderStore.items)

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Subtotal")
                    Spacer()
                    Text(subtotal, format: .currency(code: "USD"))
                }

                if hasDiscount {
                    HStack {
                        Text("Discount")
                        Spacer()
                        Text(discountAmount, format: .currency(code: "USD"))
                    }
                    .foregroundColor(.green)
                }

                HStack {
                    Text("Tax")
                    Spacer()
                    Text(taxAmount, format: .currency(code: "USD"))
                }

                HStack {
                    Text("Total")
                        .fontWeight(.bold)
                    Spacer()
                    Text(totalAmount, format: .currency(code: "USD"))
                        .fontWeight(.bold)
                }
            }
            .padding()
        }
    }

    // Business logic in computed properties
    private var subtotal: Decimal {
        orderStore.items.reduce(0) { $0 + $1.price * Decimal($1.quantity) }
    }

    private var discountAmount: Decimal {
        guard hasDiscount else { return 0 }
        return subtotal * 0.1 // 10% discount
    }

    private var taxAmount: Decimal {
        (subtotal - discountAmount) * 0.08 // 8% tax
    }

    private var totalAmount: Decimal {
        subtotal - discountAmount + taxAmount
    }

    private var hasDiscount: Bool {
        subtotal > 100 // Free shipping or discount threshold
    }
}
```

### Async Operations in Views

```swift
struct ProductCatalogView: View {
    @State private var products: [Product] = []
    @State private var searchQuery = ""
    @State private var selectedCategory: Category?
    @State private var isLoading = false
    @State private var error: Error?

    var body: some View {
        NavigationStack {
            VStack {
                SearchBar(text: $searchQuery)
                    .onSubmit {
                        Task { await performSearch() }
                    }

                CategoryFilter(selectedCategory: $selectedCategory)
                    .onChange(of: selectedCategory) {
                        Task { await loadProducts() }
                    }

                if let error = error {
                    ErrorView(error: error) {
                        Task { await loadProducts() }
                    }
                } else if isLoading {
                    ProgressView()
                } else {
                    ProductGrid(products: filteredProducts)
                }
            }
            .navigationTitle("Products")
        }
        .task {
            await loadProducts()
        }
    }

    private var filteredProducts: [Product] {
        var filtered = products

        // Apply category filter
        if let category = selectedCategory {
            filtered = filtered.filter { $0.category == category }
        }

        // Apply search filter
        if !searchQuery.isEmpty {
            filtered = filtered.filter {
                $0.name.localizedCaseInsensitiveContains(searchQuery) ||
                $0.description.localizedCaseInsensitiveContains(searchQuery)
            }
        }

        return filtered
    }

    private func loadProducts() async {
        isLoading = true
        error = nil

        do {
            products = try await productService.fetchProducts(category: selectedCategory)
        } catch {
            self.error = error
        }

        isLoading = false
    }

    private func performSearch() async {
        // Debounced search implementation
        try? await Task.sleep(nanoseconds: 300_000_000) // 300ms debounce

        guard !Task.isCancelled else { return }

        await loadProducts()
    }
}
```

## When ViewModels Might Still Be Appropriate

### Acceptable ViewModel Usage

While pure ViewModels are unnecessary, these patterns might still be useful:

1. **Heavy Computation Isolation**

```swift
@MainActor
class ComputationViewModel: ObservableObject {
    @Published private(set) var result: ComputationResult?

    // Heavy computation moved off main thread
    func performHeavyComputation(input: Data) async {
        let result = await Task.detached {
            // Heavy computation here
            return expensiveCalculation(input)
        }.value

        await MainActor.run {
            self.result = result
        }
    }
}
```

2. **Cross-Platform Logic Abstraction**

```swift
// When you need different implementations for iOS/macOS
protocol PlatformViewModel {
    func platformSpecificOperation() async
}

#if os(iOS)
class IOSViewModel: PlatformViewModel {
    func platformSpecificOperation() async {
        // iOS-specific logic
    }
}
#else
class MacOSViewModel: PlatformViewModel {
    func platformSpecificOperation() async {
        // macOS-specific logic
    }
}
#endif
```

3. **Legacy Code Integration**

```swift
// Bridging existing ViewModels during migration
class LegacyViewModelAdapter: ObservableObject {
    @Published private(set) var data: LegacyData

    private let legacyViewModel: LegacyViewModel

    init(legacyViewModel: LegacyViewModel) {
        self.legacyViewModel = legacyViewModel
        self.data = legacyViewModel.currentData

        // Bridge legacy notifications to Combine
        legacyViewModel.addObserver { [weak self] newData in
            Task { @MainActor in
                self?.data = newData
            }
        }
    }
}
```

## Testing ViewModel-Free SwiftUI Code

### Testing State and Business Logic

```swift
@Suite("Search View Tests")
struct SearchViewTests {
    @Test("Search functionality works correctly")
    @MainActor
    func searchFunctionality() async throws {
        let viewModel = SearchViewModel(searchService: MockSearchService())

        // Test initial state
        #expect(viewModel.results.isEmpty)
        #expect(!viewModel.isSearching)

        // Test search
        await viewModel.performSearch(query: "test")
        #expect(viewModel.results.count == 1)
        #expect(!viewModel.isSearching)
    }

    @Test("Search debouncing prevents excessive API calls")
    @MainActor
    func searchDebouncing() async throws {
        let mockService = MockSearchService()
        let viewModel = SearchViewModel(searchService: mockService)

        // Perform multiple rapid searches
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<5 {
                group.addTask {
                    await viewModel.performSearch(query: "query\(i)")
                }
            }
        }

        // Should only call service once due to debouncing
        #expect(mockService.callCount == 1)
    }
}
```

### UI Testing with SwiftUI

```swift
@Suite("Product Catalog UI Tests")
struct ProductCatalogUITests {
    @Test("Product catalog displays items correctly")
    func productCatalogDisplaysItems() throws {
        let app = XCUIApplication()
        app.launch()

        // Verify products are displayed
        let productList = app.collectionViews["productGrid"]
        XCTAssertTrue(productList.waitForExistence(timeout: 5))

        // Verify search functionality
        let searchField = app.textFields["searchField"]
        searchField.tap()
        searchField.typeText("iPhone")

        // Verify filtered results
        let filteredProducts = app.collectionViews["productGrid"]
        XCTAssertTrue(filteredProducts.cells.count > 0)
    }
}
```

## Migration from MVVM to ViewModel-Free SwiftUI

### Step-by-Step Migration

1. **Identify ViewModel Responsibilities**
   - Data fetching → Move to `@StateObject` or `@EnvironmentObject`
   - Business logic → Move to computed properties or view methods
   - State management → Use SwiftUI's built-in property wrappers

2. **Replace @ObservedObject ViewModels**

```swift
// BEFORE: Traditional MVVM
class ProductViewModel: ObservableObject {
    @Published var products: [Product] = []
    @Published var isLoading = false

    func loadProducts() async {
        isLoading = true
        products = await api.loadProducts()
        isLoading = false
    }
}

struct ProductView: View {
    @StateObject var viewModel = ProductViewModel()

    var body: some View {
        List(viewModel.products) { product in
            ProductRow(product: product)
        }
        .task {
            await viewModel.loadProducts()
        }
    }
}

// AFTER: ViewModel-free
struct ProductView: View {
    @State private var products: [Product] = []
    @State private var isLoading = false

    var body: some View {
        List(products) { product in
            ProductRow(product: product)
        }
        .overlay {
            if isLoading { ProgressView() }
        }
        .task {
            await loadProducts()
        }
    }

    private func loadProducts() async {
        isLoading = true
        defer { isLoading = false }
        products = await api.loadProducts()
    }
}
```

3. **Handle Complex State**
   - Break down complex ViewModels into focused `@StateObject` classes
   - Use composition over inheritance
   - Leverage SwiftUI's environment system

## Benefits of ViewModel-Free SwiftUI

### Reduced Boilerplate
- No need for ViewModel protocols
- Less ObservableObject conformance
- Fewer files and classes

### Better Type Safety
- SwiftUI's property wrappers provide compile-time guarantees
- No manual @Published declarations
- Automatic UI updates

### Easier Testing
- Test views directly with SwiftUI's testing tools
- No need to mock ViewModel protocols
- Business logic testing through computed properties

### Better Performance
- SwiftUI optimizes state updates automatically
- No unnecessary object allocations
- Direct data flow from source to UI

### Easier Debugging
- Clear data flow through SwiftUI's state system
- Xcode previews work without ViewModel setup
- Less indirection in state changes

## Summary

SwiftUI without MVVM embraces Apple's original design philosophy:

- **Built-in State Management**: @State, @StateObject, @ObservedObject, @EnvironmentObject
- **Declarative Architecture**: Views describe UI state, not imperative updates
- **Direct Data Flow**: Data flows directly from source to UI without intermediary objects
- **Type Safety**: SwiftUI's property wrappers provide compile-time guarantees
- **Automatic Updates**: UI updates automatically when state changes

Traditional ViewModels solve UIKit's problems but create unnecessary complexity in SwiftUI. By leveraging SwiftUI's built-in capabilities, you can write cleaner, more maintainable, and more performant code that aligns with Apple's intended SwiftUI architecture.

**Remember**: ViewModels are architectural debt from UIKit. SwiftUI gives you better tools. Use them.
