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

/// File attachment metadata for import/export operations.
///
/// Contains only metadata about attached files, not the file contents.
/// The `originalFilePath` is resolved from the security-scoped bookmark
/// at export time and is informational only - files must be re-attached
/// after import.
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
        case createdAt          // 2. Technical metadata
        case modifiedAt
    }

    // MARK: - Properties

    public let originalFileName: String
    /// Full file path resolved from bookmark at export time.
    /// May be nil if the file was inaccessible during export.
    public let originalFilePath: String?
    public let fileExtension: String?
    public let fileSizeBytes: Int64
    public let createdAt: Date
    public let modifiedAt: Date

    // MARK: - Initialization

    public init(
        originalFileName: String,
        originalFilePath: String?,
        fileExtension: String?,
        fileSizeBytes: Int64,
        createdAt: Date,
        modifiedAt: Date
    ) {
        self.originalFileName = originalFileName
        self.originalFilePath = originalFilePath
        self.fileExtension = fileExtension
        self.fileSizeBytes = fileSizeBytes
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
    }

    // MARK: - Computed Properties

    /// Formatted file size for display
    public var formattedFileSize: String {
        ByteCountFormatter.string(fromByteCount: fileSizeBytes, countStyle: .file)
    }
}
