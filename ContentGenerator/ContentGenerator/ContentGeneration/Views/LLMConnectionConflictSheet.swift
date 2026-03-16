//
//  LLMConnectionConflictSheet.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//
//  Side-by-side comparison UI for LLM connection conflicts during project import.
//

import SwiftUI
import ProjectExchange

/// Sheet for resolving LLM connection conflicts during project import.
/// Shows a side-by-side comparison of existing and importing configurations.
struct LLMConnectionConflictSheet: View {
    let conflict: LLMConnectionConflict
    let onResolution: (LLMConflictResolution) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header

            Divider()

            // Comparison table
            ScrollView {
                comparisonContent
            }

            Divider()

            // Action buttons
            actionButtons
        }
        .frame(width: 600, height: 450)
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(.orange)

            Text("LLM Connection Conflict")
                .font(.headline)

            Text("A connection named \"\(conflict.existingConnection.name)\" already exists")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
    }

    // MARK: - Comparison Content

    private var comparisonContent: some View {
        VStack(spacing: 0) {
            // Column headers
            HStack(spacing: 0) {
                Text("Property")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Existing")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("Importing")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            // Property rows
            comparisonRow(
                property: "Name",
                existing: conflict.existingConnection.name,
                importing: conflict.importingConfig.name
            )

            comparisonRow(
                property: "Model",
                existing: conflict.existingConnection.selectedModel,
                importing: conflict.importingConfig.selectedModel
            )

            comparisonRow(
                property: "Base URL",
                existing: conflict.existingConnection.baseUrl,
                importing: conflict.importingConfig.baseUrl
            )

            comparisonRow(
                property: "Endpoint Type",
                existing: conflict.existingConnection.endpointType,
                importing: conflict.importingConfig.endpointType.displayName
            )

            comparisonRow(
                property: "URL Path",
                existing: conflict.existingConnection.urlPath ?? "(default)",
                importing: conflict.importingConfig.urlPath ?? "(default)"
            )

            comparisonRow(
                property: "Timeout",
                existing: "\(conflict.existingConnection.requestTimeoutSeconds)s",
                importing: "\(conflict.importingConfig.requestTimeoutSeconds)s"
            )
        }
        .padding()
    }

    private func comparisonRow(property: String, existing: String, importing: String) -> some View {
        let isDifferent = existing != importing

        return HStack(spacing: 0) {
            Text(property)
                .font(.subheadline)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(existing)
                .font(.subheadline)
                .foregroundStyle(isDifferent ? .primary : .secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 4) {
                Text(importing)
                    .font(.subheadline)
                    .foregroundStyle(isDifferent ? .primary : .secondary)

                if isDifferent {
                    Image(systemName: "arrow.left")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(isDifferent ? Color.orange.opacity(0.1) : Color.clear)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Text("How would you like to proceed?")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 12) {
                Button("Skip Import") {
                    onResolution(.skip)
                    dismiss()
                }
                .buttonStyle(.bordered)
                .help("Use the existing connection, ignore imported configuration")

                Button("Use Existing") {
                    onResolution(.useExisting(connectionId: conflict.existingConnection.id))
                    dismiss()
                }
                .buttonStyle(.bordered)
                .help("Link project to existing connection without changes")

                Button("Overwrite") {
                    onResolution(.overwriteExisting(connectionId: conflict.existingConnection.id))
                    dismiss()
                }
                .buttonStyle(.bordered)
                .tint(.orange)
                .help("Update existing connection with imported values (API key preserved)")

                Button("Create New") {
                    onResolution(.createNew)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .help("Create a new connection with imported values")
            }
        }
        .padding()
    }
}

#Preview {
    let conflict = LLMConnectionConflict(
        existingConnection: LLMConnectionConflict.LLMConnectionInfo(
            id: UUID(),
            name: "OpenAI GPT-4",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com",
            endpointType: "Chat Completions",
            urlPath: nil,
            requestTimeoutSeconds: 120
        ),
        importingConfig: ExportableLLMConfiguration(
            id: UUID(),
            name: "OpenAI GPT-4",
            selectedModel: "gpt-4-turbo",
            baseUrl: "https://api.openai.com",
            endpointType: .responses,
            urlPath: "/v1/responses",
            requestTimeoutSeconds: 180
        )
    )

    LLMConnectionConflictSheet(conflict: conflict) { resolution in
        print("Resolution: \(resolution)")
    }
}
