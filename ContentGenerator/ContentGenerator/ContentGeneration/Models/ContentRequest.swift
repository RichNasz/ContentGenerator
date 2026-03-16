//
//  ContentRequest.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

// MARK: - Content Request Types

struct ContentRequest: Sendable {
    let id: UUID
    let specificationId: UUID
    let projectId: UUID
    let modelName: String?
    let additionalInstructions: String?
    let createdAt: Date

    init(
        specificationId: UUID,
        projectId: UUID,
        modelName: String? = nil,
        additionalInstructions: String? = nil
    ) {
        self.id = UUID()
        self.specificationId = specificationId
        self.projectId = projectId
        self.modelName = modelName
        self.additionalInstructions = additionalInstructions
        self.createdAt = Date()
    }
}

// MARK: - Project Status

/// Project status enum - UI components removed but preserved for future functionality
enum ProjectStatus: String, CaseIterable, Codable, Sendable {
    case draft = "draft"
    case active = "active"
    case generating = "generating"
    case completed = "completed"
}
