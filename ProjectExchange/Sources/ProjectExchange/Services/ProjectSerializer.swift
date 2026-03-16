//
//  ProjectSerializer.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Handles serialization and deserialization of project data to/from JSON.
///
/// Uses ISO8601 date encoding for portable date representation and
/// pretty-printed output for human readability.
public struct ProjectSerializer: Sendable {

    /// Shared JSON encoder configured for project export
    private static let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted]
        return encoder
    }()

    /// Shared JSON decoder configured for project import
    private static let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()

    public init() {}

    // MARK: - Export

    /// Export a project to JSON Data
    /// - Parameter project: The project to export
    /// - Returns: JSON-encoded data
    /// - Throws: `ProjectExchangeError.encodingFailed` if encoding fails
    public func export(_ project: ExportableProject) throws -> Data {
        do {
            return try Self.encoder.encode(project)
        } catch {
            throw ProjectExchangeError.encodingFailed(error.localizedDescription)
        }
    }

    /// Export a project to a JSON String
    /// - Parameter project: The project to export
    /// - Returns: JSON string representation
    /// - Throws: `ProjectExchangeError.encodingFailed` if encoding fails
    public func exportToString(_ project: ExportableProject) throws -> String {
        let data = try export(project)
        guard let string = String(data: data, encoding: .utf8) else {
            throw ProjectExchangeError.encodingFailed("Unable to convert data to UTF-8 string")
        }
        return string
    }

    /// Export a project to a file
    /// - Parameters:
    ///   - project: The project to export
    ///   - fileURL: The destination file URL
    /// - Throws: `ProjectExchangeError` if encoding or file writing fails
    public func export(_ project: ExportableProject, to fileURL: URL) throws {
        let data = try export(project)
        do {
            try data.write(to: fileURL, options: .atomic)
        } catch {
            throw ProjectExchangeError.fileOperationFailed(error.localizedDescription)
        }
    }

    // MARK: - Import

    /// Import a project from JSON Data
    /// - Parameter data: The JSON data to decode
    /// - Returns: The decoded project
    /// - Throws: `ProjectExchangeError.decodingFailed` if decoding fails
    public func importProject(from data: Data) throws -> ExportableProject {
        do {
            return try Self.decoder.decode(ExportableProject.self, from: data)
        } catch {
            throw ProjectExchangeError.decodingFailed(error.localizedDescription)
        }
    }

    /// Import a project from a JSON String
    /// - Parameter jsonString: The JSON string to decode
    /// - Returns: The decoded project
    /// - Throws: `ProjectExchangeError` if the string is invalid or decoding fails
    public func importProject(from jsonString: String) throws -> ExportableProject {
        guard let data = jsonString.data(using: .utf8) else {
            throw ProjectExchangeError.invalidJSONString
        }
        return try importProject(from: data)
    }

    /// Import a project from a file URL
    /// - Parameter fileURL: The source file URL
    /// - Returns: The decoded project
    /// - Throws: `ProjectExchangeError` if file reading or decoding fails
    public func importProject(from fileURL: URL) throws -> ExportableProject {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            throw ProjectExchangeError.fileOperationFailed(error.localizedDescription)
        }
        return try importProject(from: data)
    }

    // MARK: - Validation

    /// Validate that a project can be successfully round-tripped
    /// - Parameter project: The project to validate
    /// - Returns: True if the project can be encoded and decoded without data loss
    public func validateRoundTrip(_ project: ExportableProject) -> Bool {
        do {
            let data = try export(project)
            let reimported = try importProject(from: data)
            // Basic validation - check key fields match
            return project.name == reimported.name &&
                   project.schemaVersion == reimported.schemaVersion
        } catch {
            return false
        }
    }
}
