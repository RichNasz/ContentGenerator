//
//  ReferenceFileSelectionSection.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData

/// UI component for selecting reference files to include in LLM prompts
struct ReferenceFileSelectionSection: View {
    let attachments: [FileAttachment]
    @Binding var selectedAttachmentIds: Set<UUID>
    let fileAttachmentManager: FileAttachmentManager
    @Binding var fileAccessErrors: [UUID: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header
            HStack {
                Text("Reference Files")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if !attachments.isEmpty {
                    Spacer()
                    Text("\(selectedAttachmentIds.count)/\(attachments.count) selected")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            // Content area
            if attachments.isEmpty {
                emptyStateView
            } else {
                referenceFileList
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        HStack {
            Image(systemName: "doc.text.magnifyingglass")
                .foregroundStyle(.secondary)
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text("No reference files")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text("Add reference files to the project to provide context for content generation")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(6)
    }

    // MARK: - File List

    private var referenceFileList: some View {
        VStack(spacing: 4) {
            ForEach(attachments, id: \.id) { attachment in
                ReferenceFileRow(
                    attachment: attachment,
                    isSelected: selectedAttachmentIds.contains(attachment.id),
                    hasError: fileAccessErrors[attachment.id] != nil,
                    errorMessage: fileAccessErrors[attachment.id],
                    onToggleSelection: { toggleSelection(for: attachment) }
                )
            }
        }
        .padding(.vertical, 4)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Actions

    private func toggleSelection(for attachment: FileAttachment) {
        if selectedAttachmentIds.contains(attachment.id) {
            selectedAttachmentIds.remove(attachment.id)
        } else {
            selectedAttachmentIds.insert(attachment.id)
        }
    }
}

// MARK: - Reference File Row

/// Individual row for reference file selection
struct ReferenceFileRow: View {
    let attachment: FileAttachment
    let isSelected: Bool
    let hasError: Bool
    let errorMessage: String?
    let onToggleSelection: () -> Void

    var body: some View {
        Button(action: onToggleSelection) {
            HStack(spacing: 8) {
                // Selection checkbox
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundStyle(isSelected ? .blue : .secondary)
                    .font(.system(size: 14))

                // File type icon
                Image(systemName: attachment.fileTypeIcon)
                    .foregroundStyle(attachment.fileTypeColor)
                    .font(.system(size: 12))
                    .frame(width: 16)

                // File info
                VStack(alignment: .leading, spacing: 1) {
                    HStack {
                        Text(attachment.originalFileName)
                            .font(.caption)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        if hasError {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 10))
                        } else if !attachment.isAccessible {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.system(size: 10))
                        }
                    }

                    HStack(spacing: 4) {
                        Text(attachment.formattedFileSize)
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)

                        Text(attachment.fileTypeDisplayName)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    // Error message if present
                    if let errorMessage = errorMessage {
                        Text("Error: \(errorMessage)")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                            .lineLimit(1)
                    } else if !attachment.isAccessible {
                        Text("File not accessible")
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                }

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!attachment.isAccessible)
        .background(
            isSelected ? Color.blue.opacity(0.1) : Color.clear,
            in: RoundedRectangle(cornerRadius: 4)
        )
        .opacity(attachment.isAccessible ? 1.0 : 0.5)
        .help(buildHelpText())
    }

    private func buildHelpText() -> String {
        var helpText = "Toggle selection for \(attachment.originalFileName)"

        if let errorMessage = errorMessage {
            helpText += "\nError: \(errorMessage)"
        } else if !attachment.isAccessible {
            helpText += "\nWarning: File is not accessible"
        }

        return helpText
    }
}

// MARK: - Previews

#Preview("With Files") {
    @Previewable @State var selectedIds: Set<UUID> = []
    @Previewable @State var errors: [UUID: String] = [:]

    // Create sample attachments
    let attachment1 = FileAttachment(originalFileName: "README.md", fileSizeBytes: 2048)
    attachment1.fileExtension = "md"
    attachment1.isAccessible = true

    let attachment2 = FileAttachment(originalFileName: "Requirements.txt", fileSizeBytes: 1024)
    attachment2.fileExtension = "txt"
    attachment2.isAccessible = true

    let attachment3 = FileAttachment(originalFileName: "Design.rtf", fileSizeBytes: 4096)
    attachment3.fileExtension = "rtf"
    attachment3.isAccessible = false

    return ReferenceFileSelectionSection(
        attachments: [attachment1, attachment2, attachment3],
        selectedAttachmentIds: $selectedIds,
        fileAttachmentManager: FileAttachmentManager(dataManager: try! ProjectDataManager(bundleURL: FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs"))),
        fileAccessErrors: $errors
    )
    .padding()
    .frame(width: 300)
}

#Preview("Empty State") {
    @Previewable @State var selectedIds: Set<UUID> = []
    @Previewable @State var errors: [UUID: String] = [:]

    return ReferenceFileSelectionSection(
        attachments: [],
        selectedAttachmentIds: $selectedIds,
        fileAttachmentManager: FileAttachmentManager(dataManager: try! ProjectDataManager(bundleURL: FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs"))),
        fileAccessErrors: $errors
    )
    .padding()
    .frame(width: 300)
}