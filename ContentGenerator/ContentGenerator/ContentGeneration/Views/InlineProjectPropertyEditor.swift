//
//  InlineProjectPropertyEditor.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftData

/// Inline editor for project name and status with validation
struct InlineProjectPropertyEditor: View {
    @Bindable var project: ContentProject
    let onChanged: () -> Void

    @State private var validationError: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Name TextField with validation
            VStack(alignment: .leading, spacing: 4) {
                Text("Name")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                TextField("Project Name", text: $project.name)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: project.name) { _, newValue in
                        validateName(newValue)
                        onChanged()
                    }

                if let error = validationError {
                    Label(error, systemImage: "exclamationmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }

        }
    }

    /// Validates the project name
    private func validateName(_ name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            validationError = "Project name cannot be empty"
        } else {
            validationError = nil
        }
    }
}

#Preview("Valid Project") {
    @Previewable @State var project = ContentProject(name: "Sample Project")

    InlineProjectPropertyEditor(
        project: project,
        onChanged: { print("Project changed") }
    )
    .padding()
    .modelContainer(for: ContentProject.self, inMemory: true)
}

#Preview("Empty Name") {
    @Previewable @State var project = ContentProject(name: "")

    InlineProjectPropertyEditor(
        project: project,
        onChanged: { print("Project changed") }
    )
    .padding()
    .modelContainer(for: ContentProject.self, inMemory: true)
}
