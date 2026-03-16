//
//  LLMConnectionEditView.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftData
import SwiftUI

/// A SwiftUI view for editing LLM connection configurations.
///
/// This view supports both creating new connections and editing existing ones,
/// following Apple Human Interface Guidelines and SwiftUI best practices.
/// The view uses SwiftUI's native state management without ViewModels.
///
/// ## Usage
/// ```swift
/// // For editing an existing connection
/// LLMConnectionEditView(connection: existingConnection, modelContext: modelContext)
///
/// // For creating a new connection
/// LLMConnectionEditView(modelContext: modelContext)
/// ```
///
/// ## Features
/// - Real-time validation with visual feedback
/// - Support for both authenticated and local services
/// - Dynamic resizing and accessibility support
/// - Apple HIG compliant form design
public struct LLMConnectionEditView: View {
	// MARK: - State Management
	
	@State private var name: String
	@State private var endpointType: OpenAIEndpointType
	@State private var baseUrl: String
	@State private var urlPath: String
	@State private var apiKey: String
	@State private var selectedModel: String
	@State private var requestTimeoutSeconds: Int
	
	// View state
	@State private var isSaving: Bool = false
	@State private var showingError: Bool = false
	@State private var errorMessage: String = ""
	
	// Environment
	@Environment(\.dismiss) private var dismiss
	
	// Configuration
	private let originalConnection: LLMConnection?
	private let isEditing: Bool
	private let modelContext: ModelContext
	
	// MARK: - Initializers
	
	/// Creates a view for editing an existing LLM connection.
	/// - Parameters:
	///   - connection: The connection to edit
	///   - modelContext: The SwiftData model context for persistence
	public init(connection: LLMConnection, modelContext: ModelContext) {
		self.originalConnection = connection
		self.isEditing = true
		self.modelContext = modelContext
		
		// Initialize state from existing connection
		self._name = State(initialValue: connection.name)
		self._endpointType = State(initialValue: connection.endpointType)
		self._baseUrl = State(initialValue: connection.baseUrl)
		self._urlPath = State(initialValue: connection.urlPath ?? "")
		self._apiKey = State(initialValue: connection.apiKey)
		self._selectedModel = State(initialValue: connection.selectedModel)
		self._requestTimeoutSeconds = State(
			initialValue: connection.requestTimeoutSeconds
		)
	}
	
	/// Creates a view for creating a new LLM connection.
	/// - Parameter modelContext: The SwiftData model context for persistence
	public init(modelContext: ModelContext) {
		self.originalConnection = nil
		self.isEditing = false
		self.modelContext = modelContext
		
		// Initialize state with default values
		self._name = State(initialValue: "")
		self._endpointType = State(initialValue: .chatCompletions)
		self._baseUrl = State(initialValue: "")
		self._urlPath = State(initialValue: "")
		self._apiKey = State(initialValue: "")
		self._selectedModel = State(initialValue: "")
		self._requestTimeoutSeconds = State(initialValue: 120)
	}
	
	// MARK: - Body
	
	public var body: some View {
		NavigationStack {
			Form {
				basicInformationSection
				modelConfigurationSection
				configurationStatusSection
			}
#if os(macOS)
			.formStyle(.grouped)
			.listStyle(.inset)
#else
			.listStyle(.insetGrouped)
#endif
			.navigationTitle(isEditing ? "Edit Connection" : "New Connection")
#if os(iOS)
			.navigationBarTitleDisplayMode(.inline)
#endif
			.toolbar {
				ToolbarItem(placement: .cancellationAction) {
					Button("Cancel") {
						dismiss()
					}
				}
				
				ToolbarItem(placement: .confirmationAction) {
					Button("Save") {
						Task {
							await saveConnection()
						}
					}
					.disabled(!isValidConfiguration || isSaving)
				}
			}
			.alert("Error", isPresented: $showingError) {
				Button("OK") {}
			} message: {
				Text(errorMessage)
			}
		}
	}
}

// MARK: - Form Sections

extension LLMConnectionEditView {
	
	@ViewBuilder
	var basicInformationSection: some View {
		Section(
			content: {
			// Connection Name
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .connectionName)
					TextField("Enter connection name", text: $name)
						.autocorrectionDisabled()
#if os(iOS)
						.autocapitalization(.none)
#endif
				}
				if !isNameValid {
					validationMessage("Connection name is required")
				}
			}
			
			// Endpoint Type
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .endpointType)
					Picker("Endpoint Type", selection: $endpointType) {
						ForEach(OpenAIEndpointType.allCases, id: \.self) { type in
							Text(type.displayName).tag(type)
						}
					}
					//				.labelsHidden()
					.pickerStyle(.menu)
					Spacer()
				}
			}
			
			// Base URL
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .baseUrl)
					
					
					TextField("Enter base URL", text: $baseUrl)
						.autocorrectionDisabled()
#if os(iOS)
						.keyboardType(.URL)
						.autocapitalization(.none)
#endif
				}
				if !isUrlValid {
					validationMessage("Enter a valid URL with http:// or https://")
				}
			}
			
			// Custom Path (Optional)
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .customPath)
					TextField("Optional Custom Path", text: $urlPath)
						.autocorrectionDisabled()
#if os(iOS)
						.autocapitalization(.none)
#endif
				}
			}
			
			// API Key (Optional)
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .apiKey)
					
					SecureField("Optional API Key", text: $apiKey)
						.autocorrectionDisabled()
#if os(iOS)
						.autocapitalization(.none)
#endif
				}
			}
			},
			header: {
				Text("Connection Details")
			},
			footer: {
				Text("Configure the basic connection information for your LLM service.")
			}
		)
		.headerProminence(.increased)
#if os(macOS)
		.listRowBackground(Color(NSColor.controlBackgroundColor))
#endif
	}
	
	@ViewBuilder
	var modelConfigurationSection: some View {
		Section(
			content: {
			// Model Name
			VStack(alignment: .leading, spacing: 4) {
				HStack {
					HelpButton(content: .modelName)
					TextField("Enter model name (required)", text: $selectedModel)
						.autocorrectionDisabled()
#if os(iOS)
						.autocapitalization(.none)
#endif
				}
				if !isModelValid {
					validationMessage("Model name is required")
				}
			}
			
			// Request Timeout
			VStack(alignment: .leading, spacing: 4) {
				HStack {
//					Text("Request Timeout")
//						.font(.callout)
//					Spacer()
//					Text(formattedTimeout)
//						.foregroundColor(.secondary)
					HelpButton(content: .requestTimeout)
				
				
				Slider(
					value: Binding(
						get: { Double(requestTimeoutSeconds) },
						set: { requestTimeoutSeconds = Int($0) }
					),
					in: 60...600,
					step: 30
				) {
					Text("Request Timeout")
				} minimumValueLabel: {
					Text("1:00")
						.font(.caption2)
						.foregroundColor(.secondary)
				} maximumValueLabel: {
					Text("10:00")
						.font(.caption2)
						.foregroundColor(.secondary)
				}
			}
				HStack{
					Spacer()
					Text(formattedTimeout)
						.foregroundColor(.secondary)
					Spacer()
					Spacer()
					Spacer()
					Spacer()
				}
			}
			},
			header: {
				Text("Model & Authentication")
			},
			footer: {
				Text("Specify the model name, API key (if required), and request timeout settings.")
			}
		)
		.headerProminence(.increased)
#if os(macOS)
		.listRowBackground(Color(NSColor.controlBackgroundColor))
#endif
	}
	
	@ViewBuilder
	var configurationStatusSection: some View {
		Section(
			content: {
			HStack {
				Label(
					configurationStatusText,
					systemImage: configurationStatusIcon
				)
				.foregroundColor(configurationStatusColor)
				
				Spacer()
				
				if isSaving {
					ProgressView()
						.scaleEffect(0.8)
				}
			}
			.accessibilityElement(children: .combine)
			.accessibilityLabel("Configuration status: \(configurationStatusText)")
			
			if !isValidConfiguration {
				Text(configurationRequirements)
					.font(.caption)
					.foregroundColor(.secondary)
					.accessibilityLabel("Requirements: \(configurationRequirements)")
			}
			},
			header: {
				Text("Configuration Status")
			},
			footer: {
				Text("Current validation status of your connection configuration.")
			}
		)
		.headerProminence(.increased)
#if os(macOS)
		.listRowBackground(Color(NSColor.controlBackgroundColor))
#endif
	}
	
	@ViewBuilder
	func validationMessage(_ message: String) -> some View {
		Label {
			Text(message)
				.font(.caption)
				.foregroundColor(.red)
		} icon: {
			Image(systemName: "exclamationmark.triangle.fill")
				.foregroundColor(.red)
				.font(.caption)
		}
	}
}

// MARK: - Computed Properties

extension LLMConnectionEditView {
	
	/// Validates the complete connection configuration
	var isValidConfiguration: Bool {
		isNameValid && isUrlValid && isModelValid
	}
	
	/// Validates the connection name
	var isNameValid: Bool {
		!name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	
	/// Validates the base URL
	var isUrlValid: Bool {
		let trimmed = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmed.isEmpty,
				let url = URL(string: trimmed)
		else {
			return false
		}
		return url.scheme != nil && url.host != nil
	}
	
	/// Validates the model name
	var isModelValid: Bool {
		!selectedModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
	}
	
	/// Configuration status text for display
	var configurationStatusText: String {
		isValidConfiguration ? "Ready to Save" : "Incomplete Configuration"
	}
	
	/// Configuration status icon
	var configurationStatusIcon: String {
		isValidConfiguration
		? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
	}
	
	/// Configuration status color
	var configurationStatusColor: Color {
		isValidConfiguration ? .green : .orange
	}
	
	/// Requirements text for incomplete configurations
	var configurationRequirements: String {
		var missing: [String] = []
		
		if !isNameValid {
			missing.append("connection name")
		}
		if !isUrlValid {
			missing.append("valid base URL")
		}
		if !isModelValid {
			missing.append("model name")
		}
		
		return "Required: " + missing.joined(separator: ", ")
	}
	
	/// Formats timeout seconds as minutes:seconds (e.g., "2:30" for 150 seconds)
	var formattedTimeout: String {
		let minutes = requestTimeoutSeconds / 60
		let seconds = requestTimeoutSeconds % 60
		return String(format: "%d:%02d", minutes, seconds)
	}
}

// MARK: - Private Methods

extension LLMConnectionEditView {
	
	/// Saves the connection configuration
	@MainActor
	func saveConnection() async {
		guard isValidConfiguration else { return }
		
		isSaving = true
		
		do {
			if isEditing, let original = originalConnection {
				// Update existing connection using copy initializer
				let updatedConnection = LLMConnection(
					copying: original,
					name: name.trimmingCharacters(in: .whitespacesAndNewlines),
					endpointType: endpointType,
					baseUrl: baseUrl.trimmingCharacters(in: .whitespacesAndNewlines),
					urlPath: urlPath.trimmingCharacters(in: .whitespacesAndNewlines)
						.isEmpty
					? nil
					: urlPath.trimmingCharacters(in: .whitespacesAndNewlines),
					apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
					selectedModel: selectedModel.trimmingCharacters(
						in: .whitespacesAndNewlines
					),
					requestTimeoutSeconds: requestTimeoutSeconds
				)
				
				// Replace the original in the model context
				modelContext.delete(original)
				modelContext.insert(updatedConnection)
				
			} else {
				// Create new connection
				let newConnection = LLMConnection(
					name: name.trimmingCharacters(in: .whitespacesAndNewlines),
					endpointType: endpointType,
					baseUrl: baseUrl.trimmingCharacters(in: .whitespacesAndNewlines),
					urlPath: urlPath.trimmingCharacters(in: .whitespacesAndNewlines)
						.isEmpty
					? nil
					: urlPath.trimmingCharacters(in: .whitespacesAndNewlines),
					apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines),
					selectedModel: selectedModel.trimmingCharacters(
						in: .whitespacesAndNewlines
					),
					requestTimeoutSeconds: requestTimeoutSeconds
				)
				
				modelContext.insert(newConnection)
			}
			
			try modelContext.save()
			dismiss()
			
		} catch {
			errorMessage =
			"Failed to save connection: \(error.localizedDescription)"
			showingError = true
		}
		
		isSaving = false
	}
}

// MARK: - Preview

#Preview("New Connection") {
	do {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let container = try ModelContainer(
			for: LLMConnection.self,
			configurations: config
		)
		
		return NavigationStack {
			LLMConnectionEditView(modelContext: container.mainContext)
		}
	} catch {
		return Text("Preview Error: \(error.localizedDescription)")
			.foregroundColor(.red)
	}
}

#Preview("Edit Connection") {
	do {
		let config = ModelConfiguration(isStoredInMemoryOnly: true)
		let container = try ModelContainer(
			for: LLMConnection.self,
			configurations: config
		)
		
		return NavigationStack {
			LLMConnectionEditView(
				connection: LLMConnection(
					name: "OpenAI GPT-4",
					endpointType: .chatCompletions,
					baseUrl: "https://api.openai.com",
					urlPath: nil,
					apiKey: "sk-example-key",
					selectedModel: "gpt-4",
					requestTimeoutSeconds: 180
				),
				modelContext: container.mainContext
			)
		}
	} catch {
		return Text("Preview Error: \(error.localizedDescription)")
			.foregroundColor(.red)
	}
}

// MARK: - Individual Section Previews (Using Real Implementation)

/// Preview helper that creates actual LLMConnectionEditView instances for section previews.
/// This ensures previews show exactly the same code that runs at runtime.
@MainActor
private struct PreviewHelper {
	/// Creates a real LLMConnectionEditView instance for "new connection" previews
	static func createNewConnectionView() -> LLMConnectionEditView {
		do {
			let config = ModelConfiguration(isStoredInMemoryOnly: true)
			let container = try ModelContainer(
				for: LLMConnection.self,
				configurations: config
			)
			return LLMConnectionEditView(modelContext: container.mainContext)
		} catch {
			// Fallback to minimal setup if ModelContainer fails
			fatalError("Failed to create ModelContainer for preview: \(error)")
		}
	}
	
	/// Creates a real LLMConnectionEditView instance for "edit connection" previews
	static func createEditConnectionView() -> LLMConnectionEditView {
		do {
			let config = ModelConfiguration(isStoredInMemoryOnly: true)
			let container = try ModelContainer(
				for: LLMConnection.self,
				configurations: config
			)
			
			let sampleConnection = LLMConnection(
				name: "OpenAI GPT-4",
				endpointType: .chatCompletions,
				baseUrl: "https://api.openai.com",
				urlPath: nil,
				apiKey: "sk-example-key",
				selectedModel: "gpt-4",
				requestTimeoutSeconds: 180
			)
			
			return LLMConnectionEditView(
				connection: sampleConnection,
				modelContext: container.mainContext
			)
		} catch {
			fatalError("Failed to create ModelContainer for preview: \(error)")
		}
	}
}

#Preview("Basic Information Section") {
	Form {
		PreviewHelper.createNewConnectionView().basicInformationSection
	}
}

#Preview("Model Configuration Section") {
	Form {
		PreviewHelper.createEditConnectionView().modelConfigurationSection
	}
}

#Preview("Configuration Status Section") {
	Form {
		PreviewHelper.createNewConnectionView().configurationStatusSection
	}
}
