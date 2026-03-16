//
//  ExportableSpecification.swift
//  ProjectExchange
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// A content specification for import/export operations.
/// Contains ordered sections that define content generation requirements.
public struct ExportableSpecification: Codable, Sendable {

    // MARK: - CodingKeys for Human-Readable JSON Ordering

    private enum CodingKeys: String, CodingKey {
        case sections           // 1. Main content first
        case createdAt          // 2. Technical metadata
        case modifiedAt
    }

    // MARK: - Properties

    public let createdAt: Date
    public let modifiedAt: Date
    public let sections: [ExportableSection]

    // MARK: - Initialization

    public init(
        createdAt: Date,
        modifiedAt: Date,
        sections: [ExportableSection]
    ) {
        self.createdAt = createdAt
        self.modifiedAt = modifiedAt
        self.sections = sections
    }

    // MARK: - Computed Properties

    /// Sections sorted by orderIndex
    public var sortedSections: [ExportableSection] {
        sections.sorted { $0.orderIndex < $1.orderIndex }
    }
}
