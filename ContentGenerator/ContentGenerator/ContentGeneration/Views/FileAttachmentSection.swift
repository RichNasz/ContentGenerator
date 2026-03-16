//
//  FileAttachmentSection.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData
import UniformTypeIdentifiers

/// File attachment section for project detail view
struct FileAttachmentSection: View {
    @Bindable var project: ContentProject
    @Environment(FileAttachmentManager.self) private var attachmentManager
    @State private var isLoading = false
    @State private var showingError = false
    @State private var errorMessage = ""
    @State private var dragIsTargeted = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Add Reference Content button
            HStack {
                Label("Reference Content", systemImage: "doc.text.magnifyingglass")
                    .font(.headline)

                Spacer()

                Button(action: addAttachments) {
                    Label("Add Reference Content", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
                .disabled(isLoading)
                .help("Select text files to provide context for LLM assistance")
            }

            // Content area - empty state or file list
            if project.attachments.isEmpty && !isLoading {
                emptyStateView
            } else {
                fileListView
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            // Drag and drop visual feedback
            RoundedRectangle(cornerRadius: 12)
                .stroke(dragIsTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
                .animation(.easeInOut(duration: 0.2), value: dragIsTargeted)
        )
        .onDrop(of: [.fileURL], isTargeted: $dragIsTargeted) { providers in
            handleDrop(providers: providers)
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        ContentUnavailableView(
            "No Reference Content",
            systemImage: "doc.text.magnifyingglass",
            description: Text("Click 'Add Reference Content' or drag text files here to provide context for LLM assistance within specification sections")
        )
        .frame(minHeight: 100)
    }

    // MARK: - File List View

    private var fileListView: some View {
        VStack(spacing: 0) {
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Adding reference content...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
            }

            LazyVStack(spacing: 8) {
                ForEach(project.sortedAttachments) { attachment in
                    FileAttachmentRow(
                        attachment: attachment,
                        onRemove: { removeAttachment(attachment) },
                        onOpen: { openAttachment(attachment) },
                        onLocate: { locateAttachment(attachment) }
                    )
                }
            }
        }
    }

    // MARK: - Actions

    private func addAttachments() {
        isLoading = true

        Task {
            do {
                let newAttachments = try await attachmentManager.selectAndAttachFiles(to: project)

                await MainActor.run {
                    for attachment in newAttachments {
                        project.addAttachment(attachment)
                    }
                    isLoading = false

                    if newAttachments.isEmpty {
                        // User cancelled selection
                    } else {
                        print("Added \(newAttachments.count) reference content file(s)")
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showingError = true
                    isLoading = false
                }
            }
        }
    }

    private func removeAttachment(_ attachment: FileAttachment) {
        withAnimation(.easeOut(duration: 0.2)) {
            project.removeAttachment(attachment)
        }
    }

    private func openAttachment(_ attachment: FileAttachment) {
        Task {
            do {
                try await attachmentManager.openFileInDefaultApplication(attachment: attachment)
            } catch {
                await MainActor.run {
                    errorMessage = "Could not open file: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    private func locateAttachment(_ attachment: FileAttachment) {
        Task {
            do {
                let success = try await attachmentManager.selectAndRelocateFile(for: attachment)
                if success {
                    print("Successfully relocated '\(attachment.originalFileName)'")
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Could not locate file: \(error.localizedDescription)"
                    showingError = true
                }
            }
        }
    }

    // MARK: - Drag and Drop

    private func handleDrop(providers: [NSItemProvider]) -> Bool {
        guard !isLoading else { return false }

        isLoading = true

        for provider in providers {
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier) { item, error in
                    if let error = error {
                        Task { @MainActor in
                            self.errorMessage = "Drop failed: \(error.localizedDescription)"
                            self.showingError = true
                            self.isLoading = false
                        }
                        return
                    }

                    if let data = item as? Data,
                       let url = URL(dataRepresentation: data, relativeTo: nil) {
                        Task {
                            await processDraggedFile(url: url)
                        }
                    }
                }
            }
        }

        return true
    }

    private func processDraggedFile(url: URL) async {
        do {
            if let attachment = try await attachmentManager.createAttachment(from: url, for: project) {
                await MainActor.run {
                    withAnimation(.easeIn(duration: 0.3)) {
                        project.addAttachment(attachment)
                    }
                    isLoading = false
                }
            }
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showingError = true
                isLoading = false
            }
        }
    }
}

// MARK: - File Attachment Row

/// Individual file attachment row component
struct FileAttachmentRow: View {
    let attachment: FileAttachment
    let onRemove: () -> Void
    let onOpen: () -> Void
    let onLocate: () -> Void
    @State private var showingDeleteConfirmation = false

    var body: some View {
        HStack(spacing: 12) {
            // File type icon
            Image(systemName: attachment.fileTypeIcon)
                .foregroundStyle(attachment.fileTypeColor)
                .frame(width: 20, height: 20)

            // File information
            VStack(alignment: .leading, spacing: 2) {
                Text(attachment.originalFileName)
                    .font(.body)
                    .lineLimit(1)
                    .truncationMode(.middle)

                HStack(spacing: 8) {
                    Text(attachment.formattedFileSize)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundStyle(.tertiary)

                    Text(attachment.fileTypeDisplayName)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !attachment.isAccessible {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.tertiary)

                        Label("Inaccessible", systemImage: "exclamationmark.triangle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                            .help("This file cannot be accessed. It may have been moved or deleted.")
                    }
                }
            }

            Spacer()

            // Action buttons
            HStack(spacing: 8) {
                if attachment.isAccessible {
                    Button("Open") {
                        onOpen()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.blue)
                    .help("Open file in default application")
                } else {
                    Button("Locate") {
                        onLocate()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.orange)
                    .help("Browse to locate the missing file")
                }

                Button(action: { showingDeleteConfirmation = true }) {
                    Image(systemName: "trash")
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .help("Remove reference content from project")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Color(nsColor: .controlBackgroundColor)
                .opacity(attachment.isAccessible ? 1.0 : 0.6),
            in: RoundedRectangle(cornerRadius: 6)
        )
        .confirmationDialog(
            "Remove Reference Content",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                onRemove()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to remove '\(attachment.originalFileName)' from this project's reference content? This action cannot be undone.")
        }
    }
}

// MARK: - Previews

#Preview("Empty State") {
    let project = ContentProject(name: "Sample Project")

    return FileAttachmentSection(project: project)
        .environment(FileAttachmentManager(dataManager: try! ProjectDataManager(bundleURL: FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs"))))
        .padding()
}

#Preview("With Attachments") {
    let project = ContentProject(name: "Sample Project")

    // Create sample attachments for preview
    let attachment1 = FileAttachment(originalFileName: "README.md", fileSizeBytes: 2048)
    attachment1.fileExtension = "md"
    attachment1.isAccessible = true

    let attachment2 = FileAttachment(originalFileName: "Notes.txt", fileSizeBytes: 1024)
    attachment2.fileExtension = "txt"
    attachment2.isAccessible = true

    let attachment3 = FileAttachment(originalFileName: "Document.rtf", fileSizeBytes: 4096)
    attachment3.fileExtension = "rtf"
    attachment3.isAccessible = false

    project.attachments = [attachment1, attachment2, attachment3]

    return FileAttachmentSection(project: project)
        .environment(FileAttachmentManager(dataManager: try! ProjectDataManager(bundleURL: FileManager.default.temporaryDirectory.appendingPathComponent("Preview.cgspecs"))))
        .padding()
}

#Preview("Individual Row") {
    let attachment = FileAttachment(originalFileName: "Sample Document.txt", fileSizeBytes: 2048)
    attachment.fileExtension = "txt"
    attachment.isAccessible = true

    return FileAttachmentRow(
        attachment: attachment,
        onRemove: { print("Remove") },
        onOpen: { print("Open") },
        onLocate: { print("Locate") }
    )
    .padding()
}