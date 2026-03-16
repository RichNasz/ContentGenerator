//
//  FileAttachmentManager.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

/// Service for managing reference content files with security-scoped bookmarks for LLM assistance
@Observable
final class FileAttachmentManager {
    private let dataManager: ProjectDataManager

    // File validation constants
    private let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let supportedExtensions = ["txt", "md", "rtf"]

    private var supportedContentTypes: [UTType] {
        var types: [UTType] = [.plainText, .rtf]
        if let markdownType = UTType(filenameExtension: "md") {
            types.append(markdownType)
        }
        return types
    }

    init(dataManager: ProjectDataManager) {
        self.dataManager = dataManager
    }

    // MARK: - File Selection and Attachment Creation

    /// Presents file picker and creates reference content attachments for selected files
    @MainActor
    func selectAndAttachFiles(to project: ContentProject) async throws -> [FileAttachment] {
        // Ensure we're on the main actor for UI operations
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = supportedContentTypes
        openPanel.title = "Select Reference Content Files"
        openPanel.message = "Choose text files to provide context for LLM assistance"

        // Run the modal on the main actor
        let modalResult = openPanel.runModal()
        guard modalResult == .OK else {
            return []
        }

        let selectedURLs = openPanel.urls
        var attachments: [FileAttachment] = []

        // Process files sequentially on main actor to avoid Sendable issues with SwiftData
        for url in selectedURLs {
            do {
                if let attachment = try await createAttachment(from: url, for: project) {
                    attachments.append(attachment)
                }
            } catch {
                // Log individual file errors but continue processing other files
                print("Failed to create attachment for \(url.lastPathComponent): \(error)")
            }
        }

        return attachments
    }

    /// Creates a reference content FileAttachment from a URL for drag & drop operations
    @MainActor
    func createAttachment(from url: URL, for project: ContentProject) async throws -> FileAttachment? {
        // Validate file before processing
        try validateFile(at: url)

        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey, .contentTypeKey])

        guard let fileSize = resourceValues.fileSize else {
            throw FileAttachmentError.unableToReadFileSize
        }

        // Check for duplicate attachments
        let fileName = url.lastPathComponent
        let hasDuplicate = project.attachments.contains(where: { $0.originalFileName == fileName })

        if hasDuplicate {
            throw FileAttachmentError.duplicateAttachment(fileName: fileName)
        }

        // Create security-scoped bookmark
        let bookmarkData = try createSecurityScopedBookmark(for: url)

        // Create attachment and set properties
        let attachment = FileAttachment(
            originalFileName: fileName,
            fileSizeBytes: Int64(fileSize)
        )

        attachment.securityScopedBookmarkData = bookmarkData
        attachment.project = project

        return attachment
    }

    // MARK: - Security-Scoped Bookmark Management

    private func createSecurityScopedBookmark(for url: URL) throws -> Data {
        do {
            return try url.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )
        } catch {
            throw FileAttachmentError.bookmarkCreationFailed(error)
        }
    }

    /// Resolves security-scoped bookmark and provides access to the file
    func accessFile(attachment: FileAttachment) async throws -> URL? {
        // Get bookmark data on main actor
        let bookmarkData = await MainActor.run {
            attachment.securityScopedBookmarkData
        }

        guard let bookmarkData = bookmarkData else {
            throw FileAttachmentError.noBookmarkData
        }

        var isStale = false
        let url: URL

        do {
            url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            await MainActor.run {
                attachment.isAccessible = false
            }
            throw FileAttachmentError.bookmarkResolutionFailed(error)
        }

        // Refresh bookmark if it's stale
        if isStale {
            do {
                try await refreshBookmark(for: attachment, newURL: url)
            } catch {
                await MainActor.run {
                    attachment.isAccessible = false
                }
                throw FileAttachmentError.bookmarkRefreshFailed(error)
            }
        }

        // Start accessing security-scoped resource
        guard url.startAccessingSecurityScopedResource() else {
            await MainActor.run {
                attachment.isAccessible = false
            }
            throw FileAttachmentError.cannotAccessSecurityScopedResource
        }

        // Mark as accessible and update timestamp on main actor
        await MainActor.run {
            attachment.isAccessible = true
            attachment.updateModifiedDate()
        }

        // Note: Caller is responsible for calling url.stopAccessingSecurityScopedResource()
        return url
    }

    @MainActor
    private func refreshBookmark(for attachment: FileAttachment, newURL: URL) async throws {
        let newBookmarkData = try createSecurityScopedBookmark(for: newURL)
        attachment.securityScopedBookmarkData = newBookmarkData
        attachment.updateModifiedDate()
    }

    // MARK: - File Validation

    private func validateFile(at url: URL) throws {
        // Check if file exists and is accessible
        guard url.isFileURL else {
            throw FileAttachmentError.notAFileURL
        }

        let resourceValues = try url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey,
            .contentTypeKey
        ])

        // Ensure it's a regular file (not a directory or special file)
        guard resourceValues.isRegularFile == true else {
            throw FileAttachmentError.notARegularFile
        }

        // Check file size
        guard let fileSize = resourceValues.fileSize, fileSize <= maxFileSize else {
            throw FileAttachmentError.fileTooLarge(maxSize: maxFileSize)
        }

        // Validate file extension
        let fileExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw FileAttachmentError.unsupportedFileType(
                fileExtension: fileExtension,
                supportedTypes: supportedExtensions
            )
        }
    }

    // MARK: - Batch Operations

    /// Validates attachment accessibility for all files in a project
    @MainActor
    func validateAttachmentBookmarks(for project: ContentProject) async {
        for attachment in project.attachments {
            do {
                if let url = try await accessFile(attachment: attachment) {
                    // Successfully accessed, mark as accessible
                    url.stopAccessingSecurityScopedResource()
                } else {
                    attachment.isAccessible = false
                }
            } catch {
                attachment.isAccessible = false
                print("Attachment \(attachment.originalFileName) is no longer accessible: \(error)")
            }
        }
    }

    /// Opens a file using the default system application
    @MainActor
    func openFileInDefaultApplication(attachment: FileAttachment) async throws {
        guard let url = try await accessFile(attachment: attachment) else {
            throw FileAttachmentError.cannotAccessSecurityScopedResource
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        NSWorkspace.shared.open(url)
    }

    /// Reads the content of a text file attachment
    @MainActor
    func readFileContent(attachment: FileAttachment) async throws -> String {
        guard let url = try await accessFile(attachment: attachment) else {
            throw FileAttachmentError.cannotAccessSecurityScopedResource
        }

        defer {
            url.stopAccessingSecurityScopedResource()
        }

        do {
            return try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw FileAttachmentError.fileReadFailed(error)
        }
    }

    // MARK: - File Relocation

    /// Relocates an inaccessible attachment by creating a new security-scoped bookmark
    /// - Parameters:
    ///   - attachment: The attachment to relocate
    ///   - newURL: The new file URL (from file picker)
    /// - Throws: FileAttachmentError if validation fails or bookmark creation fails
    @MainActor
    func relocateAttachment(_ attachment: FileAttachment, to newURL: URL) async throws {
        // Validate file matches expected type and size limits
        try validateFile(at: newURL)

        // Create new security-scoped bookmark
        let bookmarkData = try createSecurityScopedBookmark(for: newURL)

        // Update attachment
        attachment.securityScopedBookmarkData = bookmarkData
        attachment.isAccessible = true
        attachment.updateModifiedDate()

        // Update file size if it changed
        let resourceValues = try newURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues.fileSize {
            attachment.fileSizeBytes = Int64(fileSize)
        }
    }

    /// Presents file picker for user to locate a missing file
    /// - Parameter attachment: The inaccessible attachment to relocate
    /// - Returns: True if file was successfully relocated
    @MainActor
    func selectAndRelocateFile(for attachment: FileAttachment) async throws -> Bool {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = supportedContentTypes
        openPanel.title = "Locate '\(attachment.originalFileName)'"
        openPanel.message = "Select the file to re-establish the link"

        let modalResult = openPanel.runModal()
        guard modalResult == .OK, let url = openPanel.url else {
            return false
        }

        try await relocateAttachment(attachment, to: url)
        return true
    }
}

// MARK: - Error Types

enum FileAttachmentError: LocalizedError {
    case unableToReadFileSize
    case noBookmarkData
    case cannotAccessSecurityScopedResource
    case bookmarkResolutionFailed(Error)
    case bookmarkCreationFailed(Error)
    case bookmarkRefreshFailed(Error)
    case notAFileURL
    case notARegularFile
    case fileTooLarge(maxSize: Int64)
    case unsupportedFileType(fileExtension: String, supportedTypes: [String])
    case duplicateAttachment(fileName: String)
    case fileReadFailed(Error)

    var errorDescription: String? {
        switch self {
        case .unableToReadFileSize:
            return "Unable to read file size"
        case .noBookmarkData:
            return "No security bookmark data available"
        case .cannotAccessSecurityScopedResource:
            return "Cannot access the file due to security restrictions"
        case .bookmarkResolutionFailed(let error):
            return "Failed to resolve file bookmark: \(error.localizedDescription)"
        case .bookmarkCreationFailed(let error):
            return "Failed to create security bookmark: \(error.localizedDescription)"
        case .bookmarkRefreshFailed(let error):
            return "Failed to refresh security bookmark: \(error.localizedDescription)"
        case .notAFileURL:
            return "The provided URL is not a file URL"
        case .notARegularFile:
            return "The selected item is not a regular file"
        case .fileTooLarge(let maxSize):
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return "File is too large. Maximum size allowed is \(formatter.string(fromByteCount: maxSize))"
        case .unsupportedFileType(let fileExtension, let supportedTypes):
            return "File type '.\(fileExtension)' is not supported. Supported types: \(supportedTypes.joined(separator: ", "))"
        case .duplicateAttachment(let fileName):
            return "A reference content file named '\(fileName)' is already attached to this project"
        case .fileReadFailed(let error):
            return "Failed to read file content: \(error.localizedDescription)"
        }
    }
}

// MARK: - File Type Utilities

extension FileAttachment {
    /// Returns an appropriate SF Symbol for the file type
    var fileTypeIcon: String {
        switch fileExtension {
        case "txt":
            return "doc.text"
        case "md":
            return "text.aligncenter"
        case "rtf":
            return "text.richtext"
        default:
            return "doc"
        }
    }

    /// Returns a color associated with the file type
    var fileTypeColor: Color {
        switch fileExtension {
        case "txt":
            return .blue
        case "md":
            return .green
        case "rtf":
            return .orange
        default:
            return .gray
        }
    }
}