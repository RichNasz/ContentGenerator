//
//  ContentGeneratorError.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

// MARK: - ContentGenerator Error Types

enum ContentGeneratorError: LocalizedError, Sendable {
    case aiServiceUnavailable
    case invalidContentRequest(String)
    case contentGenerationFailed(String)
    case projectIsolationViolation
    case projectNotFound(UUID)
    case specificationRequired(String)
    case settingsAccessError
    case llmConnectionFailed(String)
    case llmConfigurationInvalid(String)
    case noLLMConnectionsAvailable
    case chatCompletionsAPIError(String)
    case chatCompletionsConfigurationMissing
    case swiftChatCompletionsDSLError(String)

    var errorDescription: String? {
        switch self {
        case .aiServiceUnavailable:
            return "AI service is currently unavailable"
        case .invalidContentRequest(let details):
            return "Invalid content request: \(details)"
        case .contentGenerationFailed(let reason):
            return "Content generation failed: \(reason)"
        case .projectIsolationViolation:
            return "Attempted to access data from another project"
        case .projectNotFound(let projectId):
            return "Project not found: \(projectId)"
        case .specificationRequired(let details):
            return "Specification required: \(details)"
        case .settingsAccessError:
            return "Unable to access application settings"
        case .llmConnectionFailed(let details):
            return "LLM connection failed: \(details)"
        case .llmConfigurationInvalid(let details):
            return "LLM configuration invalid: \(details)"
        case .noLLMConnectionsAvailable:
            return "No LLM connections are available"
        case .chatCompletionsAPIError(let details):
            return "Chat Completions API error: \(details)"
        case .chatCompletionsConfigurationMissing:
            return "Chat Completions configuration is missing for this connection"
        case .swiftChatCompletionsDSLError(let details):
            return "SwiftChatCompletionsDSL error: \(details)"
        }
    }

    var failureReason: String? {
        switch self {
        case .aiServiceUnavailable:
            return "The AI service may be temporarily down or experiencing issues"
        case .invalidContentRequest:
            return "The content request contains invalid or missing information"
        case .contentGenerationFailed:
            return "The AI service was unable to generate content for this request"
        case .projectIsolationViolation:
            return "Data isolation prevents cross-project access"
        case .projectNotFound:
            return "The specified project could not be found in the database"
        case .specificationRequired:
            return "A content specification is required to generate content"
        case .settingsAccessError:
            return "Application settings could not be accessed or modified"
        case .llmConnectionFailed:
            return "Unable to establish connection to the LLM service"
        case .llmConfigurationInvalid:
            return "The LLM connection configuration is incomplete or invalid"
        case .noLLMConnectionsAvailable:
            return "No LLM connections have been configured or all are unavailable"
        case .chatCompletionsAPIError:
            return "The Chat Completions API returned an error"
        case .chatCompletionsConfigurationMissing:
            return "Chat Completions parameters are required but not configured"
        case .swiftChatCompletionsDSLError:
            return "The SwiftChatCompletionsDSL package encountered an error"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .aiServiceUnavailable:
            return "Check your internet connection and try again later"
        case .invalidContentRequest:
            return "Review the content request parameters and try again"
        case .contentGenerationFailed:
            return "Try adjusting your request or using a different LLM connection"
        case .projectIsolationViolation:
            return "Ensure you're working within the correct project context"
        case .projectNotFound:
            return "Verify the project exists and try refreshing the project list"
        case .specificationRequired:
            return "Create a specification for the project before generating content"
        case .settingsAccessError:
            return "Check application permissions and try restarting the app"
        case .llmConnectionFailed:
            return "Verify your API keys and connection settings"
        case .llmConfigurationInvalid:
            return "Check the LLM connection configuration in settings"
        case .noLLMConnectionsAvailable:
            return "Configure at least one LLM connection in settings"
        case .chatCompletionsAPIError:
            return "Check your API key and rate limits"
        case .chatCompletionsConfigurationMissing:
            return "Configure Chat Completions parameters for this connection"
        case .swiftChatCompletionsDSLError:
            return "Check the network connection and API configuration"
        }
    }
}