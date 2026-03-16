//
//  ProjectExchangeError.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Errors that can occur during project import/export operations.
public enum ProjectExchangeError: LocalizedError, Sendable {
    /// Failed to encode project to JSON
    case encodingFailed(String)

    /// Failed to decode JSON to project
    case decodingFailed(String)

    /// The provided string is not valid JSON
    case invalidJSONString

    /// Schema version mismatch between import file and current version
    case schemaVersionMismatch(expected: String, found: String)

    /// Validation of project data failed
    case validationFailed(String)

    /// File operation failed
    case fileOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed(let message):
            return "Failed to encode project: \(message)"
        case .decodingFailed(let message):
            return "Failed to decode project: \(message)"
        case .invalidJSONString:
            return "The provided string is not valid JSON"
        case .schemaVersionMismatch(let expected, let found):
            return "Schema version mismatch. Expected \(expected), found \(found)"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        case .fileOperationFailed(let message):
            return "File operation failed: \(message)"
        }
    }
}
