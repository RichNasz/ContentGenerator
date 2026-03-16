//
//  HelpContent.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Represents structured help content for contextual assistance.
///
/// This structure provides a standardized way to organize help information
/// that can be presented to users through contextual help buttons and sheets.
/// The design follows Apple's Human Interface Guidelines for offering help.
///
/// ## Usage
/// ```swift
/// let helpContent = HelpContent(
///     title: "Connection Name",
///     summary: "A descriptive name for your LLM connection",
///     details: "Choose a name that helps you identify this connection...",
///     examples: ["OpenAI GPT-4", "Local Ollama", "Claude API"],
///     tips: ["Use descriptive names", "Include the service provider"]
/// )
/// ```
public struct HelpContent: Sendable {
    /// The title of the help topic, typically matching the field label.
    public let title: String

    /// A brief, one-sentence summary of what this field does.
    ///
    /// This should be concise and immediately useful, answering "what is this?"
    public let summary: String

    /// Detailed explanation providing context and guidance.
    ///
    /// This can include multiple paragraphs explaining how to use the field,
    /// what values are expected, and how it affects the overall configuration.
    public let details: String

    /// Array of concrete examples showing valid values.
    ///
    /// Examples should cover common use cases and demonstrate proper formatting.
    /// Each example should be realistic and immediately usable.
    public let examples: [String]

    /// Optional array of helpful tips and best practices.
    ///
    /// Tips should provide actionable advice beyond the basic usage,
    /// including common pitfalls to avoid and optimization suggestions.
    public let tips: [String]?

    /// Creates a new help content structure.
    ///
    /// - Parameters:
    ///   - title: The help topic title
    ///   - summary: Brief one-sentence explanation
    ///   - details: Comprehensive explanation and guidance
    ///   - examples: Array of concrete usage examples
    ///   - tips: Optional array of helpful tips and best practices
    public init(
        title: String,
        summary: String,
        details: String,
        examples: [String],
        tips: [String]? = nil
    ) {
        self.title = title
        self.summary = summary
        self.details = details
        self.examples = examples
        self.tips = tips
    }
}

// MARK: - Predefined Help Content

extension HelpContent {

    /// Help content for the connection name field.
    public static let connectionName = HelpContent(
        title: "Connection Name",
        summary: "A descriptive name to identify this LLM connection in your app.",
        details: """
        Choose a name that helps you quickly identify this connection among others. \
        The name should be descriptive and indicate the service provider, model, or purpose. \
        This name is only used for display purposes and doesn't affect the connection's functionality.
        """,
        examples: [
            "OpenAI GPT-4",
            "Local Ollama Llama2",
            "Claude API",
            "Azure OpenAI Service",
            "Custom API Server"
        ],
        tips: [
            "Include the service provider in the name",
            "Mention the specific model if relevant",
            "Use descriptive names for easier organization"
        ]
    )

    /// Help content for the endpoint type field.
    public static let endpointType = HelpContent(
        title: "Endpoint Type",
        summary: "Choose between Chat Completions or Responses endpoint for OpenAI-compatible APIs.",
        details: """
        Chat Completions is the standard endpoint used by most applications for conversational AI. \
        It supports streaming, function calling, and other common features.

        Responses is a newer endpoint that supports advanced features like structured outputs, \
        reasoning modes, and specialized response formats. Choose this if you need these advanced capabilities.

        When in doubt, use Chat Completions as it's the most widely supported option.
        """,
        examples: [
            "Chat Completions: /v1/chat/completions",
            "Responses: /v1/responses"
        ],
        tips: [
            "Use Chat Completions for standard conversational AI",
            "Use Responses for structured outputs and reasoning",
            "Check your API provider's documentation for supported endpoints"
        ]
    )

    /// Help content for the base URL field.
    public static let baseUrl = HelpContent(
        title: "Base URL",
        summary: "The base URL of your LLM service, without the specific endpoint path.",
        details: """
        Enter the base URL of your LLM service. This should include the protocol (https:// or http://) \
        and the hostname, but not the specific API endpoint path.

        For cloud services like OpenAI, use their official API base URL. \
        For local services like Ollama, use your local server address and port.

        The system will automatically append the appropriate endpoint path based on your endpoint type selection.
        """,
        examples: [
            "https://api.openai.com",
            "https://api.anthropic.com",
            "http://localhost:11434",
            "https://your-custom-api.com",
            "https://eastus.api.cognitive.microsoft.com"
        ],
        tips: [
            "Always include the protocol (https:// or http://)",
            "Don't include trailing slashes",
            "For local services, include the port number if needed",
            "Verify the URL is accessible from your app"
        ]
    )

    /// Help content for the custom path field.
    public static let customPath = HelpContent(
        title: "Custom Path",
        summary: "Optional custom API endpoint path to override the default path for your endpoint type.",
        details: """
        Leave this empty to use the standard path for your selected endpoint type. \
        Use this field only if your API provider uses non-standard endpoint paths.

        When you enter a custom path, it completely replaces the default path. \
        Make sure to include the leading slash and the complete path to your API endpoint.

        This is useful for custom API servers, proxies, or services that don't follow OpenAI's path conventions.
        """,
        examples: [
            "/v1/chat/completions (OpenAI standard)",
            "/api/generate (Ollama style)",
            "/v2/chat (custom API version)",
            "/proxy/openai/chat/completions (proxied service)"
        ],
        tips: [
            "Leave empty for standard OpenAI-compatible services",
            "Always start with a forward slash (/)",
            "Check your API provider's documentation for the correct path",
            "The path combines with the base URL to form the complete endpoint"
        ]
    )

    /// Help content for the API key field.
    public static let apiKey = HelpContent(
        title: "API Key",
        summary: "Authentication key for your LLM service (optional for local services).",
        details: """
        Enter your API key if your LLM service requires authentication. This is typically required \
        for cloud services like OpenAI, Anthropic, or Azure, but not needed for local services like Ollama.

        API keys are sensitive information that should be kept secure. They provide access to your \
        account and may incur charges based on usage.

        If you're using a local service that doesn't require authentication, you can leave this field empty.
        """,
        examples: [
            "sk-1234567890abcdef... (OpenAI format)",
            "Bearer token123... (Bearer token format)",
            "your-api-key-here (generic format)"
        ],
        tips: [
            "Keep your API keys secure and private",
            "Check your service provider's dashboard for API keys",
            "Some services use bearer tokens instead of API keys",
            "Local services typically don't require API keys"
        ]
    )

    /// Help content for the model name field.
    public static let modelName = HelpContent(
        title: "Model Name",
        summary: "The specific AI model to use with this connection.",
        details: """
        Specify the exact model name as provided by your LLM service. Different models have \
        different capabilities, costs, and performance characteristics.

        Model names are case-sensitive and must match exactly what the API expects. \
        Check your service provider's documentation for available models and their names.

        Popular models include GPT-4, GPT-3.5-turbo for OpenAI, and various models for other providers.
        """,
        examples: [
            "gpt-4",
            "gpt-3.5-turbo",
            "claude-3-sonnet",
            "llama2",
            "mistral"
        ],
        tips: [
            "Model names are case-sensitive",
            "Check your provider's documentation for available models",
            "Different models have different capabilities and costs",
            "Some models may not be available in all regions"
        ]
    )

    /// Help content for the request timeout field.
    public static let requestTimeout = HelpContent(
        title: "Request Timeout",
        summary: "Maximum time to wait for API responses, from 1 to 10 minutes.",
        details: """
        Set how long your app should wait for a response from the LLM service before timing out. \
        Longer timeouts allow for more complex requests but may make your app feel unresponsive.

        For most use cases, 2-3 minutes is sufficient. Increase the timeout for complex requests \
        or slower services. Decrease it for simple requests where you want faster feedback.

        The timeout is automatically constrained between 1 and 10 minutes for practical usage.
        """,
        examples: [
            "2:00 (2 minutes) - Good for most requests",
            "5:00 (5 minutes) - Complex reasoning tasks",
            "1:00 (1 minute) - Simple, quick responses",
            "10:00 (10 minutes) - Maximum for very complex tasks"
        ],
        tips: [
            "2-3 minutes works well for most use cases",
            "Longer timeouts for complex reasoning tasks",
            "Shorter timeouts for simple requests",
            "Consider your user experience when setting timeouts"
        ]
    )
}