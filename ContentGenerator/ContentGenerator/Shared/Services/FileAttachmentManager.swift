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

/// Result returned by ``FileAttachmentManager/selectAndAttachFiles(to:)``.
struct FileSelectionResult {
    /// Attachments successfully created and ready to be added to the project.
    var attachments: [FileAttachment]
    /// Files skipped because a same-named attachment already exists.
    /// Each element pairs the source URL with the name of the conflicting existing attachment.
    var duplicates: [(url: URL, existingFileName: String)]
}

/// Service for managing reference content files stored inside the .cgspecs bundle.
///
/// New attachments are copied into `bundle/projects/<uuid>/attachments/` at attach time.
/// The single bundle-level security-scoped bookmark (held by `BundleManager`) covers
/// all files inside the bundle — no per-file bookmark is needed.
///
/// Legacy attachments (created before this change) still carry `securityScopedBookmarkData`
/// and are resolved via that bookmark as a fallback.  Users can re-link them via the
/// "Locate" button, which copies the file into the bundle and clears the old bookmark.
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

    /// Presents file picker and creates reference content attachments for selected files.
    /// Each selected file is copied into the bundle's attachments directory for the project.
    /// Duplicate file names are reported separately so the caller can offer a replace confirmation.
    @MainActor
    func selectAndAttachFiles(to project: ContentProject) async throws -> FileSelectionResult {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = true
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowedContentTypes = supportedContentTypes
        openPanel.title = "Select Reference Content Files"
        openPanel.message = "Choose text files to provide context for LLM assistance"

        let modalResult = openPanel.runModal()
        guard modalResult == .OK else {
            return FileSelectionResult(attachments: [], duplicates: [])
        }

        let selectedURLs = openPanel.urls
        var result = FileSelectionResult(attachments: [], duplicates: [])

        for url in selectedURLs {
            do {
                if let attachment = try await createAttachment(from: url, for: project) {
                    result.attachments.append(attachment)
                }
            } catch FileAttachmentError.duplicateAttachment(let fileName) {
                result.duplicates.append((url: url, existingFileName: fileName))
            } catch {
                // Log individual file errors but continue processing other files
                print("Failed to create attachment for \(url.lastPathComponent): \(error)")
            }
        }

        return result
    }

    /// Creates a `FileAttachment` by copying the file into the bundle.
    /// Suitable for both file picker and drag-and-drop flows.
    @MainActor
    func createAttachment(from url: URL, for project: ContentProject) async throws -> FileAttachment? {
        try validateFile(at: url)

        let resourceValues = try url.resourceValues(forKeys: [.fileSizeKey])
        guard let fileSize = resourceValues.fileSize else {
            throw FileAttachmentError.unableToReadFileSize
        }

        let fileName = url.lastPathComponent
        let hasDuplicate = project.attachments.contains(where: { $0.originalFileName == fileName })
        if hasDuplicate {
            throw FileAttachmentError.duplicateAttachment(fileName: fileName)
        }

        // Copy the file into the bundle's attachments directory
        let relativePath = try copyFileToBundleAttachments(
            source: url,
            projectId: project.id,
            originalFileName: fileName
        )

        let attachment = FileAttachment(
            originalFileName: fileName,
            fileSizeBytes: Int64(fileSize)
        )
        attachment.relativeBundlePath = relativePath
        attachment.isAccessible = true
        attachment.project = project

        return attachment
    }

    // MARK: - Bundle Copy Helpers

    /// Copies a file from `source` into `bundle/projects/<projectId>/attachments/`,
    /// resolving filename conflicts with a numeric suffix.
    /// - Returns: The relative path string from the bundle root.
    private func copyFileToBundleAttachments(
        source: URL,
        projectId: UUID,
        originalFileName: String
    ) throws -> String {
        let attachmentsDir = try dataManager.attachmentsDirectory(for: projectId)
        let destURL = uniqueDestinationURL(in: attachmentsDir, for: originalFileName)

        do {
            try FileManager.default.copyItem(at: source, to: destURL)
        } catch {
            throw FileAttachmentError.fileCopyFailed(error)
        }

        return "projects/\(projectId.uuidString)/attachments/\(destURL.lastPathComponent)"
    }

    /// Returns a URL in `directory` for `fileName` that does not already exist,
    /// appending `-2`, `-3`, … before the extension as needed.
    private func uniqueDestinationURL(in directory: URL, for fileName: String) -> URL {
        var candidate = directory.appendingPathComponent(fileName)
        guard FileManager.default.fileExists(atPath: candidate.path) else {
            return candidate
        }

        let fileURL = URL(fileURLWithPath: fileName)
        let nameWithoutExt = fileURL.deletingPathExtension().lastPathComponent
        let ext = fileURL.pathExtension
        var counter = 2

        repeat {
            let newName = ext.isEmpty
                ? "\(nameWithoutExt)-\(counter)"
                : "\(nameWithoutExt)-\(counter).\(ext)"
            candidate = directory.appendingPathComponent(newName)
            counter += 1
        } while FileManager.default.fileExists(atPath: candidate.path)

        return candidate
    }

    // MARK: - File Access

    /// Resolves the URL for an attachment.
    ///
    /// For bundle-based attachments (`relativeBundlePath` is set), returns the file URL
    /// directly — no `startAccessingSecurityScopedResource` call is needed.
    /// Callers may still call `stopAccessingSecurityScopedResource()` on the returned URL;
    /// that is a safe no-op for non-security-scoped URLs.
    ///
    /// For legacy bookmark-based attachments, resolves the security-scoped bookmark
    /// and calls `startAccessingSecurityScopedResource`. The caller must call
    /// `stopAccessingSecurityScopedResource()` when done.
    func accessFile(attachment: FileAttachment) async throws -> URL? {
        // New: resolve from bundle-relative path
        if let relativePath = attachment.relativeBundlePath {
            let fileURL = dataManager.bundleURL.appendingPathComponent(relativePath)
            let exists = FileManager.default.fileExists(atPath: fileURL.path)
            attachment.isAccessible = exists
            guard exists else {
                throw FileAttachmentError.fileNotFoundInBundle
            }
            return fileURL
        }

        // Legacy: resolve via security-scoped bookmark
        guard let bookmarkData = attachment.securityScopedBookmarkData else {
            attachment.isAccessible = false
            throw FileAttachmentError.noBookmarkData
        }

        var isStale = false
        let resolvedURL: URL

        do {
            resolvedURL = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )
        } catch {
            attachment.isAccessible = false
            throw FileAttachmentError.bookmarkResolutionFailed(error)
        }

        guard resolvedURL.startAccessingSecurityScopedResource() else {
            attachment.isAccessible = false
            throw FileAttachmentError.cannotAccessSecurityScopedResource
        }

        attachment.isAccessible = true
        attachment.updateModifiedDate()
        return resolvedURL
    }

    // MARK: - Batch Accessibility Validation

    /// Validates accessibility for all attachments in a project.
    /// Bundle-based attachments are checked by file existence;
    /// legacy bookmark-based attachments are resolved via their bookmark.
    @MainActor
    func validateAttachmentBookmarks(for project: ContentProject) async {
        for attachment in project.attachments {
            if let relativePath = attachment.relativeBundlePath {
                let fileURL = dataManager.bundleURL.appendingPathComponent(relativePath)
                attachment.isAccessible = FileManager.default.fileExists(atPath: fileURL.path)
            } else {
                do {
                    if let url = try await accessFile(attachment: attachment) {
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
    }

    // MARK: - Open / Read

    /// Opens the attachment in its default macOS application.
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

    /// Reads and returns the text content of an attachment.
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

    /// Relocates an inaccessible attachment by copying the user-selected file into the bundle.
    /// Clears any legacy bookmark data and sets `relativeBundlePath`.
    @MainActor
    func relocateAttachment(_ attachment: FileAttachment, to newURL: URL) async throws {
        try validateFile(at: newURL)

        guard let projectId = attachment.project?.id else {
            throw FileAttachmentError.fileCopyFailed(
                NSError(
                    domain: "FileAttachmentManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Attachment has no associated project"]
                )
            )
        }

        let relativePath = try copyFileToBundleAttachments(
            source: newURL,
            projectId: projectId,
            originalFileName: attachment.originalFileName
        )

        attachment.relativeBundlePath = relativePath
        attachment.securityScopedBookmarkData = nil
        attachment.isAccessible = true
        attachment.updateModifiedDate()

        let resourceValues = try newURL.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues.fileSize {
            attachment.fileSizeBytes = Int64(fileSize)
        }
    }

    /// Presents file picker for the user to locate a missing file, then copies it into the bundle.
    /// - Returns: `true` if the file was successfully relocated.
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

    // MARK: - Attachment Removal

    /// Removes an attachment from a project and deletes its copy from the bundle (if present).
    /// For legacy bookmark-based attachments with no bundle copy, only the record is removed.
    @MainActor
    func removeAttachment(_ attachment: FileAttachment, from project: ContentProject) {
        if let relativePath = attachment.relativeBundlePath {
            let fileURL = dataManager.bundleURL.appendingPathComponent(relativePath)
            try? FileManager.default.removeItem(at: fileURL)
        }
        project.removeAttachment(attachment)
    }

    /// Replaces an existing attachment's bundle copy with a new file, updating the record in-place.
    /// The original filename is preserved; the old bundle file is removed before copying.
    @MainActor
    func replaceAttachment(_ existing: FileAttachment, withFileAt sourceURL: URL) async throws {
        try validateFile(at: sourceURL)

        guard let projectId = existing.project?.id else {
            throw FileAttachmentError.fileCopyFailed(
                NSError(
                    domain: "FileAttachmentManager",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Attachment has no associated project"]
                )
            )
        }

        // Remove the old bundle copy (failure is non-fatal — proceed with copy regardless)
        if let oldPath = existing.relativeBundlePath {
            let oldURL = dataManager.bundleURL.appendingPathComponent(oldPath)
            try? FileManager.default.removeItem(at: oldURL)
        }

        // Copy new file using the original filename (old file is gone, no suffix needed)
        let attachmentsDir = try dataManager.attachmentsDirectory(for: projectId)
        let destURL = attachmentsDir.appendingPathComponent(existing.originalFileName)
        do {
            try FileManager.default.copyItem(at: sourceURL, to: destURL)
        } catch {
            throw FileAttachmentError.fileCopyFailed(error)
        }

        // Update the existing SwiftData record in-place (same UUID preserved)
        existing.relativeBundlePath = "projects/\(projectId.uuidString)/attachments/\(existing.originalFileName)"
        existing.isAccessible = true
        if let fileSize = try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
            existing.fileSizeBytes = Int64(fileSize)
        }
        existing.updateModifiedDate()
    }

    // MARK: - File Validation

    private func validateFile(at url: URL) throws {
        guard url.isFileURL else {
            throw FileAttachmentError.notAFileURL
        }

        let resourceValues = try url.resourceValues(forKeys: [
            .isRegularFileKey,
            .fileSizeKey
        ])

        guard resourceValues.isRegularFile == true else {
            throw FileAttachmentError.notARegularFile
        }

        guard let fileSize = resourceValues.fileSize, fileSize <= maxFileSize else {
            throw FileAttachmentError.fileTooLarge(maxSize: maxFileSize)
        }

        let fileExtension = url.pathExtension.lowercased()
        guard supportedExtensions.contains(fileExtension) else {
            throw FileAttachmentError.unsupportedFileType(
                fileExtension: fileExtension,
                supportedTypes: supportedExtensions
            )
        }
    }
}

// MARK: - Error Types

enum FileAttachmentError: LocalizedError {
    case unableToReadFileSize
    case fileCopyFailed(Error)
    case fileNotFoundInBundle
    case noBookmarkData
    case cannotAccessSecurityScopedResource
    case bookmarkResolutionFailed(Error)
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
        case .fileCopyFailed(let error):
            return "Failed to copy file into bundle: \(error.localizedDescription)"
        case .fileNotFoundInBundle:
            return "The file could not be found inside the bundle. It may have been deleted."
        case .noBookmarkData:
            return "No access information available for this file"
        case .cannotAccessSecurityScopedResource:
            return "Cannot access the file due to security restrictions"
        case .bookmarkResolutionFailed(let error):
            return "Failed to resolve file access: \(error.localizedDescription)"
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
