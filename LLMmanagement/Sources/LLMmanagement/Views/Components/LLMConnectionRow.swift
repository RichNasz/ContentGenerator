//
//  LLMConnectionRow.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

/// A list row component for displaying LLMConnection information in lists.
///
/// This component provides a standardized way to display connection information
/// following Apple Human Interface Guidelines for list items. It shows the
/// connection name, model, and configuration status with appropriate visual
/// indicators.
///
/// ## Features
/// - Connection name as primary text
/// - Model name as secondary text
/// - Configuration status indicator
/// - Apple HIG compliant design
/// - Full accessibility support
///
/// ## Usage
/// ```swift
/// List(connections) { connection in
///     LLMConnectionRow(connection: connection)
/// }
/// ```
public struct LLMConnectionRow: View {
    /// The LLMConnection to display information for.
    public let connection: LLMConnection

    /// Creates a new connection row for the specified connection.
    ///
    /// - Parameter connection: The LLMConnection to display
    public init(connection: LLMConnection) {
        self.connection = connection
    }

    public var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            statusIndicator

            // Connection details
            VStack(alignment: .leading, spacing: 4) {
                Text(connection.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if !connection.selectedModel.isEmpty {
                    Text(connection.selectedModel)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                } else {
                    Text("No model selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .italic()
                }
            }

            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to edit this connection")
    }
}

// MARK: - Private Views

private extension LLMConnectionRow {

    @ViewBuilder
    var statusIndicator: some View {
        Image(systemName: statusIconName)
            .foregroundColor(statusColor)
            .font(.title2)
            .accessibilityLabel(statusAccessibilityLabel)
    }

    /// The SF Symbol name for the connection status.
    var statusIconName: String {
        connection.isConfigured ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    /// The color for the connection status indicator.
    var statusColor: Color {
        connection.isConfigured ? .green : .orange
    }

    /// Accessibility label for the status indicator.
    var statusAccessibilityLabel: String {
        connection.isConfigured ? "Configured" : "Needs configuration"
    }

    /// Comprehensive accessibility label for the entire row.
    var accessibilityLabel: String {
        let status = connection.isConfigured ? "configured" : "needs configuration"
        let model = connection.selectedModel.isEmpty ? "no model selected" : "model \(connection.selectedModel)"
        return "Connection \(connection.name), \(model), \(status)"
    }
}

// MARK: - Preview

#Preview("Configured Connection") {
    List {
        LLMConnectionRow(
            connection: LLMConnection(
                name: "OpenAI GPT-4",
                endpointType: .chatCompletions,
                baseUrl: "https://api.openai.com",
                apiKey: "sk-example-key",
                selectedModel: "gpt-4",
                requestTimeoutSeconds: 180
            )
        )

        LLMConnectionRow(
            connection: LLMConnection(
                name: "Local Ollama",
                endpointType: .chatCompletions,
                baseUrl: "http://localhost:11434",
                selectedModel: "llama2"
            )
        )
    }
}

#Preview("Unconfigured Connection") {
    List {
        LLMConnectionRow(
            connection: LLMConnection(
                name: "Incomplete Setup"
            )
        )

        LLMConnectionRow(
            connection: LLMConnection(
                name: "Missing Model",
                baseUrl: "https://api.example.com"
            )
        )
    }
}