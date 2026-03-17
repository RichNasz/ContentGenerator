//
//  ExportableFileAttachment.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// File attachment transfer object for import/export operations.
///
/// When exporting a project whose attachments are stored inside the bundle,
/// the file bytes are base64-encoded into `fileContentBase64`.  On import,
/// the bytes are decoded and written into the destination bundle so the
/// attachment is immediately accessible — no "Locate" step required.
///
/// If `fileContentBase64` is `nil` (legacy exports or inaccessible files),
/// the attachment is imported as inaccessible and the user must re-link it
/// via the "Locate" button.
///
/// - Note: Security-scoped bookmark data is NOT exported as it is
///   app-specific and machine-specific.
public struct ExportableFileAttachment: Codable, Sendable {

    // MARK: - CodingKeys for Human-Readable JSON Ordering

    private enum CodingKeys: String, CodingKey {
        case originalFileName   // 1. Human-readable info
        case originalFilePath
        case fileExtension
        case fileSizeBytes
        case fileContentBase64  // 2. Embedded file contents (optional)
        case createdAt          // 3. Technical metadata
        case modifiedAt
    }

    // MARK: - Properties

    public let originalFileName: String
    /// Full file path resolved from bookmark at export time.
    /// May be nil if the file was inaccessible during export.
    public let originalFilePath: String?
    public let fileExtension: String?
    public let fileSizeBytes: Int64
    /// Base64-encoded raw file bytes.  Present when the file was stored inside
    /// the bundle and readable at export time.  `nil` for legacy exports.
    public let fileContentBase64: String?
    public let createdAt: Date
    public let modifiedAt: Date

    // MARK: - Initialization

    public init(
        originalFileName: String,
        originalFilePath: String?,
        fileExtension: String?,
        fileSizeBytes: Int64,
        createdAt: Date,
        modifiedAt: Date,
        fileContentBase64: String? = nil
    ) {
        self.originalFileName = originalFileName
        self.originalFilePath = originalFilePath
        self.fileExtension = fileExtension
        self.fileSizeBytes = fileSizeBytes
        self.fileContentBase64 = fileContentBase64
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Formatted file size for display
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
}
