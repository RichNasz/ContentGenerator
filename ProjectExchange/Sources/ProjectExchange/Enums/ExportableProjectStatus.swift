//
//  ExportableProjectStatus.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Project status for import/export operations.
/// Mirrors the ContentGenerator ProjectStatus enum for portability.
public enum ExportableProjectStatus: String, Codable, Sendable, CaseIterable {
    case draft
    case active
    case generating
    case completed
}
