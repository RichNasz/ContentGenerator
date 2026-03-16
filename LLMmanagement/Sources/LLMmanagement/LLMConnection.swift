//
//  LLMConnection.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftData

/// Specifies the type of OpenAI API endpoint to use for requests.
///
/// This enum allows connections to specify whether they should use the standard
/// Chat Completions endpoint or the newer Responses endpoint, supporting different
/// OpenAI API features and response formats.
///
/// ## Usage
/// ```swift
/// let connection = LLMConnection(
///     name: "OpenAI Chat",
///     endpointType: .chatCompletions,
///     baseUrl: "https://api.openai.com",
///     selectedModel: "gpt-4"
/// )
/// ```
public enum OpenAIEndpointType: String, CaseIterable, Codable {
    /// Use the Chat Completions endpoint (/v1/chat/completions)
    ///
    /// This is the standard endpoint for most conversational AI use cases
    /// and supports streaming, function calling, and other standard features.
    case chatCompletions = "chat_completions"

    /// Use the Responses endpoint (/v1/responses)
    ///
    /// This endpoint supports advanced features like structured outputs,
    /// reasoning modes, and other specialized response formats.
    case responses = "responses"

    /// The default URL path for this endpoint type.
    ///
    /// Returns the standard OpenAI API path for the endpoint type.
    /// - Returns: The URL path string for the endpoint
    public var defaultPath: String {
        switch self {
        case .chatCompletions:
            return "/v1/chat/completions"
        case .responses:
            return "/v1/responses"
        }
    }

    /// A human-readable display name for the endpoint type.
    ///
    /// - Returns: The display name for use in user interfaces
    public var displayName: String {
        switch self {
        case .chatCompletions:
            return "Chat Completions"
        case .responses:
            return "Responses"
        }
    }
}

/// A SwiftData model representing a configured connection to a Large Language Model service.
///
/// Use `LLMConnection` to manage persistent configuration data for LLM services,
/// including API endpoints, authentication credentials, model selection, and usage tracking.
///
/// ## Overview
/// The `LLMConnection` model provides a centralized way to store and manage
/// LLM service configurations with automatic persistence through SwiftData.
/// It supports both authenticated services (with API keys) and local services
/// (like Ollama) that don't require authentication.
///
/// ## Usage
/// ```swift
/// // Create a new connection for OpenAI
/// let openAIConnection = LLMConnection(
///     name: "OpenAI GPT-4",
///     apiUrl: "https://api.openai.com/v1/chat/completions",
///     apiKey: "your-api-key",
///     selectedModel: "gpt-4"
/// )
///
/// // Create a local Ollama connection
/// let ollamaConnection = LLMConnection(
///     name: "Local Ollama",
///     apiUrl: "http://localhost:11434/api/generate",
///     selectedModel: "llama2"
/// )
/// ```
///
/// - Note: This model requires iOS 26.0, macOS 26.0, or visionOS 26.0 or later.
/// - Important: Always validate connection configuration using `isConfigured` before creating services.
@Model
public final class LLMConnection {
	/// Unique identifier for the connection that persists across sessions.
	@Attribute(.unique) public var id: UUID

	/// Human-readable name for the connection.
	///
	/// This name is used in user interfaces to identify the connection.
	/// Choose descriptive names like "OpenAI GPT-4" or "Local Ollama".
	public var name: String

	/// The type of OpenAI endpoint to use for this connection.
	///
	/// Determines whether to use Chat Completions or Responses endpoint.
	/// Chat Completions is the default and most commonly used endpoint.
	public var endpointType: OpenAIEndpointType

	/// The base URL for the LLM service.
	///
	/// Must be a valid URL with scheme and host. This should be the base URL
	/// without the path component. Examples:
	/// - `https://api.openai.com`
	/// - `http://localhost:11434`
	public var baseUrl: String

	/// Optional custom URL path for the API endpoint.
	///
	/// When provided, this overrides the default path for the endpoint type.
	/// If nil, the default path for the endpointType will be used.
	/// Examples:
	/// - `"/v1/chat/completions"` (custom OpenAI path)
	/// - `"/api/generate"` (for Ollama)
	/// - `nil` (use default path for endpoint type)
	public var urlPath: String?

	/// The API key for authenticating with the LLM service.
	///
	/// This field is optional to support local services that don't require authentication.
	/// For services like OpenAI, this should contain your API key.
	public var apiKey: String

	/// The specific model to use with this connection.
	///
	/// Examples: "gpt-4", "gpt-3.5-turbo", "llama2", "mistral"
	public var selectedModel: String

	/// Request timeout in seconds, automatically clamped to 60-600 seconds (1-10 minutes).
	///
	/// The timeout value is enforced within reasonable limits to prevent
	/// excessively long waits or too-short timeouts that might cause failures.
	public var requestTimeoutSeconds: Int

	/// The date and time when this connection was created.
	public var createdAt: Date

	/// The date and time when this connection was last used, if any.
	///
	/// This value is `nil` for newly created connections that haven't been used yet.
	public var lastUsed: Date?

	/// Creates a new LLM connection with the specified configuration.
	///
	/// - Parameters:
	///   - name: A human-readable name for the connection
	///   - endpointType: The OpenAI endpoint type to use (optional, defaults to chatCompletions)
	///   - baseUrl: The base URL for the LLM service (optional, defaults to empty string)
	///   - urlPath: Custom URL path override (optional, defaults to nil - uses endpoint type default)
	///   - apiKey: The API key for authentication (optional, defaults to empty string)
	///   - selectedModel: The model to use with this connection (optional, defaults to empty string)
	///   - requestTimeoutSeconds: Request timeout in seconds (optional, defaults to 120, clamped to 60-600)
	///
	/// The initializer automatically generates a unique ID and sets the creation timestamp.
	/// The timeout value is automatically clamped to the valid range of 60-600 seconds (1-10 minutes).
	///
	/// ## Example
	/// ```swift
	/// let connection = LLMConnection(
	///     name: "My OpenAI Connection",
	///     endpointType: .chatCompletions,
	///     baseUrl: "https://api.openai.com",
	///     apiKey: "sk-...",
	///     selectedModel: "gpt-4",
	///     requestTimeoutSeconds: 180
	/// )
	/// ```
	public init(name: String, endpointType: OpenAIEndpointType = .chatCompletions, baseUrl: String = "", urlPath: String? = nil, apiKey: String = "", selectedModel: String = "", requestTimeoutSeconds: Int = 120) {
		self.id = UUID()
		self.name = name
		self.endpointType = endpointType
		self.baseUrl = baseUrl
		self.urlPath = urlPath
		self.apiKey = apiKey
		self.selectedModel = selectedModel
		self.requestTimeoutSeconds = max(60, min(600, requestTimeoutSeconds)) // Clamp to valid range
		self.createdAt = Date()
		self.lastUsed = nil
	}

	/// Creates a new connection by copying configuration from an existing connection.
	///
	/// This initializer preserves the original connection's identity (ID), creation date,
	/// and usage history while allowing updates to the configuration parameters.
	///
	/// - Parameters:
	///   - original: The original connection to copy identity and timestamps from
	///   - name: The new human-readable name for the connection
	///   - endpointType: The new OpenAI endpoint type to use
	///   - baseUrl: The new base URL for the LLM service
	///   - urlPath: The new custom URL path override (optional)
	///   - apiKey: The new API key for authentication
	///   - selectedModel: The new model to use with this connection
	///   - requestTimeoutSeconds: The new request timeout in seconds (clamped to 60-600)
	///
	/// Use this initializer when updating an existing connection's configuration
	/// while maintaining its identity and history for SwiftData persistence.
	///
	/// ## Example
	/// ```swift
	/// let updatedConnection = LLMConnection(
	///     copying: existingConnection,
	///     name: "Updated Connection Name",
	///     endpointType: .responses,
	///     baseUrl: "https://api.openai.com",
	///     urlPath: nil,
	///     apiKey: "new-api-key",
	///     selectedModel: "gpt-4-turbo",
	///     requestTimeoutSeconds: 240
	/// )
	/// ```
	public init(copying original: LLMConnection, name: String, endpointType: OpenAIEndpointType, baseUrl: String, urlPath: String?, apiKey: String, selectedModel: String, requestTimeoutSeconds: Int) {
		self.id = original.id
		self.name = name
		self.endpointType = endpointType
		self.baseUrl = baseUrl
		self.urlPath = urlPath
		self.apiKey = apiKey
		self.selectedModel = selectedModel
		self.requestTimeoutSeconds = max(60, min(600, requestTimeoutSeconds)) // Clamp to valid range
		self.createdAt = original.createdAt
		self.lastUsed = original.lastUsed
	}

	/// Indicates whether the connection has sufficient configuration to be usable.
	///
	/// A connection is considered configured when it has:
	/// - A valid base URL with scheme and host
	/// - A non-empty model selection
	///
	/// The API key is optional to support local services that don't require authentication.
	/// The urlPath is optional and will use the endpoint type's default path if not provided.
	///
	/// - Returns: `true` if the connection is properly configured, `false` otherwise
	///
	/// ## Example
	/// ```swift
	/// let connection = LLMConnection(name: "Test")
	/// print(connection.isConfigured) // false - missing URL and model
	///
	/// connection.baseUrl = "https://api.openai.com"
	/// connection.selectedModel = "gpt-4"
	/// print(connection.isConfigured) // true - has valid URL and model
	/// ```
	public var isConfigured: Bool {
		let hasBaseUrl = !baseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isValidURL(baseUrl)
		let hasModel = !selectedModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty

		// API key is optional (e.g., for local Ollama instances)
		return hasBaseUrl && hasModel
	}

	/// The complete API URL for making requests.
	///
	/// Combines the base URL with either the custom urlPath (if provided) or
	/// the default path for the selected endpoint type.
	///
	/// - Returns: The full API URL string, or empty string if baseUrl is empty
	///
	/// ## Examples
	/// ```swift
	/// // Using default path
	/// let connection = LLMConnection(
	///     name: "OpenAI",
	///     endpointType: .chatCompletions,
	///     baseUrl: "https://api.openai.com"
	/// )
	/// print(connection.fullApiUrl) // "https://api.openai.com/v1/chat/completions"
	///
	/// // Using custom path
	/// let customConnection = LLMConnection(
	///     name: "Custom",
	///     baseUrl: "https://api.openai.com",
	///     urlPath: "/custom/endpoint"
	/// )
	/// print(customConnection.fullApiUrl) // "https://api.openai.com/custom/endpoint"
	/// ```
	public var fullApiUrl: String {
		let trimmedBaseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
		guard !trimmedBaseUrl.isEmpty else { return "" }

		let path = urlPath ?? endpointType.defaultPath
		let baseUrlWithoutSlash = trimmedBaseUrl.hasSuffix("/") ? String(trimmedBaseUrl.dropLast()) : trimmedBaseUrl
		let pathWithSlash = path.hasPrefix("/") ? path : "/" + path

		return baseUrlWithoutSlash + pathWithSlash
	}

	/// Updates the last used timestamp to the current date and time.
	///
	/// Call this method when the connection is successfully used to make
	/// an API request, allowing for usage tracking and analytics.
	///
	/// ## Example
	/// ```swift
	/// // After successfully using the connection
	/// connection.updateLastUsed()
	/// print(connection.lastUsed) // Current timestamp
	/// ```
	public func updateLastUsed() {
		lastUsed = Date()
	}

	/// Validates that a string represents a properly formatted URL.
	///
	/// A valid URL must have both a scheme (like "https" or "http") and a host.
	/// This ensures the URL is complete enough for network requests.
	///
	/// - Parameter string: The URL string to validate
	/// - Returns: `true` if the string is a valid URL with scheme and host, `false` otherwise
	///
	/// ## Examples
	/// ```swift
	/// isValidURL("https://api.openai.com/v1/chat") // true
	/// isValidURL("http://localhost:11434/api")     // true
	/// isValidURL("api.openai.com")                 // false - no scheme
	/// isValidURL("https://")                       // false - no host
	/// isValidURL("not-a-url")                      // false - invalid format
	/// ```
	private func isValidURL(_ string: String) -> Bool {
		guard let url = URL(string: string) else { return false }
		return url.scheme != nil && url.host != nil
	}
}
