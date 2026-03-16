//
//  ExportableLLMConfiguration.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// LLM connection configuration for import/export operations.
///
/// Contains connection settings for reference and potential recreation
/// during import. API keys are intentionally excluded for security.
///
/// ## Identification
/// The `id` property allows sections to reference specific LLM connections.
/// When multiple sections use the same LLM, only one configuration appears
/// in the project's `llmConfigurations` array, referenced by id.
///
/// - Important: The `apiKey` is NEVER included in exports for security reasons.
///   Users must provide API keys after importing a project.
public struct ExportableLLMConfiguration: Codable, Sendable, Identifiable {

    // MARK: - CodingKeys for Human-Readable JSON Ordering

    private enum CodingKeys: String, CodingKey {
        case name               // 1. Human-readable info
        case selectedModel
        case baseUrl
        case endpointType
        case urlPath
        case requestTimeoutSeconds
        case id                 // 2. Technical metadata (for referencing)
    }

    // MARK: - Properties

    public let id: UUID
    public let name: String
    public let selectedModel: String
    public let baseUrl: String
    public let endpointType: ExportableEndpointType
    public let urlPath: String?
    public let requestTimeoutSeconds: Int

    // MARK: - Initialization

    public init(
        id: UUID,
        name: String,
        selectedModel: String,
        baseUrl: String,
        endpointType: ExportableEndpointType,
        urlPath: String?,
        requestTimeoutSeconds: Int
    ) {
        self.id = id
        self.name = name
        self.selectedModel = selectedModel
        self.baseUrl = baseUrl
        self.endpointType = endpointType
        self.urlPath = urlPath
        self.requestTimeoutSeconds = requestTimeoutSeconds
    }

    // MARK: - Computed Properties

    /// The full API URL constructed from baseUrl and urlPath or endpoint default
    public var fullApiUrl: String {
        let trimmedBaseUrl = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBaseUrl.isEmpty else { return "" }

        let path = urlPath ?? endpointType.defaultPath
        let baseUrlWithoutSlash = trimmedBaseUrl.hasSuffix("/") ? String(trimmedBaseUrl.dropLast()) : trimmedBaseUrl
        let pathWithSlash = path.hasPrefix("/") ? path : "/" + path

        return baseUrlWithoutSlash + pathWithSlash
    }
}

extension ExportableEndpointType {
    /// Default URL path for this endpoint type
    public var defaultPath: String {
        switch self {
        case .chatCompletions:
            return "/v1/chat/completions"
        case .responses:
            return "/v1/responses"
        }
    }
}
