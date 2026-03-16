//
//  LLMConnectionListView.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData

/// A comprehensive list view for managing LLMConnection instances.
///
/// This view provides complete CRUD functionality for LLM connections following
/// Apple Human Interface Guidelines and SwiftUI without MVVM patterns. It uses
/// SwiftData's @Query for automatic data synchronization and provides search,
/// creation, editing, and deletion capabilities.
///
/// ## Features
/// - Automatic SwiftData integration with @Query
/// - Alphabetical sorting by connection name
/// - Real-time search functionality
/// - Empty state with creation guidance
/// - Swipe-to-delete functionality
/// - Pull-to-refresh capability
/// - Full accessibility support
///
/// ## Usage
/// ```swift
/// NavigationStack {
///     LLMConnectionListView(modelContext: modelContext)
/// }
/// ```
public struct LLMConnectionListView: View {
    // MARK: - SwiftData Integration

    @State private var llmConnections: [LLMConnection] = []
    private let modelContext: ModelContext
    private let embedInNavigationStack: Bool

    // MARK: - State Management (No ViewModels)

    @State private var searchText = ""
    @State private var showingCreateConnection = false
    @State private var showingDeleteAlert = false
    @State private var connectionToDelete: LLMConnection?
    @State private var errorMessage: String?
    @State private var showingError = false

    /// Creates a new LLM connection list view.
    ///
    /// The view uses the provided SwiftData model context for data operations
    /// and manages all state internally without ViewModels.
    ///
    /// - Parameters:
    ///   - modelContext: The SwiftData model context for data operations
    ///   - embedInNavigationStack: Whether to wrap the view in a NavigationStack.
    ///                             Set to false when using in NavigationSplitView detail areas.
    public init(modelContext: ModelContext, embedInNavigationStack: Bool = true) {
        self.modelContext = modelContext
        self.embedInNavigationStack = embedInNavigationStack
    }

    public var body: some View {
        if embedInNavigationStack {
            NavigationStack {
                listContent
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("LLM Connections list")
        } else {
            listContent
                .accessibilityElement(children: .contain)
                .accessibilityLabel("LLM Connections list")
        }
    }

    /// The main list content with conditional navigation modifiers
    private var listContent: some View {
        mainContent
            .conditionalNavigationModifiers(
                embedInNavigationStack: embedInNavigationStack,
                searchText: $searchText,
                addButton: addButton,
                loadConnections: loadConnections
            )
            .sheet(isPresented: $showingCreateConnection, onDismiss: {
                Task {
                    await loadConnections()
                }
            }) {
                createConnectionSheet
            }
            .alert("Delete Connection", isPresented: $showingDeleteAlert) {
                deleteAlertButtons
            } message: {
                deleteAlertMessage
            }
            .alert("Error", isPresented: $showingError) {
                errorAlertButtons
            } message: {
                errorAlertMessage
            }
            .onAppear {
                Task {
                    await loadConnections()
                }
            }
    }
}

// MARK: - Private Views

private extension LLMConnectionListView {

    @ViewBuilder
    var mainContent: some View {
        if filteredConnections.isEmpty {
            emptyStateView
        } else {
            connectionsList
        }
    }

    @ViewBuilder
    var addButton: some View {
        Button {
            showingCreateConnection = true
        } label: {
            Image(systemName: "plus")
        }
        .accessibilityLabel("Add connection")
        .accessibilityHint("Create a new LLM connection")
    }

    @ViewBuilder
    var createConnectionSheet: some View {
        NavigationStack {
            LLMConnectionEditView(modelContext: modelContext)
        }
    }

    @ViewBuilder
    var deleteAlertButtons: some View {
        Button("Cancel", role: .cancel) {
            connectionToDelete = nil
        }
        Button("Delete", role: .destructive) {
            if let connection = connectionToDelete {
                deleteConnection(connection)
            }
        }
    }

    @ViewBuilder
    var deleteAlertMessage: some View {
        if let connection = connectionToDelete {
            Text("Are you sure you want to delete \"\(connection.name)\"? This action cannot be undone.")
        }
    }

    @ViewBuilder
    var errorAlertButtons: some View {
        Button("OK") {
            errorMessage = nil
        }
    }

    @ViewBuilder
    var errorAlertMessage: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
        }
    }

    @ViewBuilder
    var emptyStateView: some View {
        if searchText.isEmpty {
            // No connections exist
            LLMEmptyConnectionsView {
                showingCreateConnection = true
            }
        } else {
            // No search results
            ContentUnavailableView.search(text: searchText)
        }
    }

    @ViewBuilder
    var connectionsList: some View {
        List {
            ForEach(filteredConnections, id: \.id) { connection in
                NavigationLink {
                    LLMConnectionEditView(connection: connection, modelContext: modelContext)
                } label: {
                    LLMConnectionRow(connection: connection)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        connectionToDelete = connection
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(connection.name)")
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.plain)
        #endif
        .accessibilityLabel("Connections list with \(filteredConnections.count) items")
    }
}

// MARK: - Computed Properties

private extension LLMConnectionListView {

    /// Filters connections based on search text.
    ///
    /// Searches both connection names and model names for matches.
    /// Returns all connections when search text is empty.
    var filteredConnections: [LLMConnection] {
        if searchText.isEmpty {
            return llmConnections
        }

        return llmConnections.filter { connection in
            connection.name.localizedCaseInsensitiveContains(searchText) ||
            connection.selectedModel.localizedCaseInsensitiveContains(searchText)
        }
    }
}

// MARK: - Private Methods

private extension LLMConnectionListView {

    /// Loads connections from SwiftData.
    func loadConnections() async {
        do {
            let request = FetchDescriptor<LLMConnection>(
                sortBy: [SortDescriptor(\LLMConnection.name)]
            )
            llmConnections = try modelContext.fetch(request)
        } catch {
            errorMessage = "Failed to load connections: \(error.localizedDescription)"
            showingError = true
        }
    }

    /// Deletes the specified connection from SwiftData.
    ///
    /// - Parameter connection: The connection to delete
    func deleteConnection(_ connection: LLMConnection) {
        do {
            modelContext.delete(connection)
            try modelContext.save()

            // Reload connections after deletion
            Task {
                await loadConnections()
            }
        } catch {
            errorMessage = "Failed to delete connection: \(error.localizedDescription)"
            showingError = true
        }

        connectionToDelete = nil
    }
}

// MARK: - Conditional Navigation Modifiers Extension

private extension View {
    @ViewBuilder
    func conditionalNavigationModifiers(
        embedInNavigationStack: Bool,
        searchText: Binding<String>,
        addButton: some View,
        loadConnections: @escaping () async -> Void
    ) -> some View {
        // Navigation modifiers work for both standalone NavigationStack
        // and NavigationSplitView detail area usage
        self
            .navigationTitle("LLM Connections")
            .searchable(text: searchText, prompt: "Search connections or models")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addButton
                }
            }
            .refreshable {
                await loadConnections()
            }
    }
}

// MARK: - Preview

#Preview("With Connections") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: LLMConnection.self, configurations: config)

        // Add sample data
        let openAI = LLMConnection(
            name: "OpenAI GPT-4",
            endpointType: .chatCompletions,
            baseUrl: "https://api.openai.com",
            apiKey: "sk-example-key",
            selectedModel: "gpt-4"
        )

        let ollama = LLMConnection(
            name: "Local Ollama",
            endpointType: .chatCompletions,
            baseUrl: "http://localhost:11434",
            selectedModel: "llama2"
        )

        let incomplete = LLMConnection(name: "Incomplete Setup")

        container.mainContext.insert(openAI)
        container.mainContext.insert(ollama)
        container.mainContext.insert(incomplete)

        return container
    }()

    LLMConnectionListView(modelContext: container.mainContext)
}

#Preview("Empty State") {
    @Previewable @State var container: ModelContainer = {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try! ModelContainer(for: LLMConnection.self, configurations: config)
    }()

    LLMConnectionListView(modelContext: container.mainContext)
}