//
//  ExpandableSpecificationSection.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

/// Expandable section for specification editing with inline controls
struct ExpandableSpecificationSection: View {
    @Binding var section: SpecificationSectionData
    @Binding var isExpanded: Bool
    let projectLLMConnectionId: UUID?
    let onChanged: () -> Void
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    @State private var showingDeleteConfirmation = false
    @State private var isHoveringHeader = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(isExpanded: $isExpanded) {
                // Expanded: Editable fields
                VStack(spacing: 12) {
                    // Section name editor
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Section Name")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        SpellCheckingTextField(placeholder: "Section Name", text: $section.name)
                            .onChange(of: section.name) { _, _ in
                                onChanged()
                            }
                    }

                    // Section content editor
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Content")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        ExpandableTextEditorWrapper(
                            text: $section.content,
                            title: "Content - \(section.name)",
                            placeholder: "Enter section content..."
                        )
                        .onChange(of: section.content) { _, _ in
                            onChanged()
                        }
                    }

                    // Content Usage Prompt editor
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Content Usage Prompt")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text("(Optional)")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }

                        ExpandableTextEditorWrapper(
                            text: Binding(
                                get: { section.contentUsagePrompt ?? "" },
                                set: { section.contentUsagePrompt = $0.isEmpty ? nil : $0 }
                            ),
                            title: "Content Usage Prompt - \(section.name)",
                            placeholder: "Describes how to use this section's content...",
                            minHeight: 80,
                            maxHeight: 150
                        )
                        .onChange(of: section.contentUsagePrompt) { _, _ in
                            onChanged()
                        }

                        Text("Describes how to use this section's content when generating project content")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.top, -2)
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 4)
            } label: {
                // Header with section name and controls
                HStack(spacing: 8) {
                    // Enable/disable checkbox
                    Toggle("", isOn: Binding(
                        get: { section.isEnabled },
                        set: { newValue in
                            section.isEnabled = newValue
                            onChanged()
                        }
                    ))
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    .help(section.isEnabled ? "Disable section" : "Enable section")

                    // Section name with conditional styling
                    Text(section.name)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .lineLimit(1)
                        .foregroundStyle(section.isEnabled ? .primary : .secondary)
                        .strikethrough(!section.isEnabled, color: .secondary)

                    Spacer()

                    // Control buttons
                    HStack(spacing: 4) {
                        // Move buttons - shown on hover
                        HStack(spacing: 4) {
                            // Move up button
                            if let onMoveUp = onMoveUp {
                                Button(action: onMoveUp) {
                                    Image(systemName: "chevron.up")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Move up")
                            }

                            // Move down button
                            if let onMoveDown = onMoveDown {
                                Button(action: onMoveDown) {
                                    Image(systemName: "chevron.down")
                                        .font(.caption)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(.secondary)
                                .help("Move down")
                            }
                        }
                        .opacity(isHoveringHeader ? 1 : 0)
                        .animation(.easeInOut(duration: 0.15), value: isHoveringHeader)

                        // Delete button - always visible
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .help("Delete section")
                    }
                }
                .onHover { hovering in
                    isHoveringHeader = hovering
                }
            }

            // Preview of content when collapsed
            if !isExpanded && !section.content.isEmpty {
                Text(section.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .padding(.top, 4)
                    .padding(.leading, 20)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color(nsColor: .controlBackgroundColor).opacity(section.isEnabled ? 0.3 : 0.15))
        .cornerRadius(8)
        .overlay(
            // Optional gray overlay for disabled sections
            section.isEnabled ? nil : Color.gray.opacity(0.2)
                .cornerRadius(8)
                .allowsHitTesting(false)
        )
        .confirmationDialog(
            "Delete '\(section.name)'?",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive, action: onDelete)
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    // MARK: - Content Generation

    private func handleContentGenerated(_ content: String, _ mode: ContentInsertMode, _ updatedPrompt: String?) {
        // Update content based on mode
        switch mode {
        case .replace:
            section.content = content
        case .append:
            if section.content.isEmpty {
                section.content = content
            } else {
                section.content += "\n\n" + content
            }
        }

        // Save the updated user prompt
        section.contentGenerationPrompt = updatedPrompt

        onChanged()
    }
}

#Preview("Collapsed Section") {
    @Previewable @State var section = SpecificationSectionData(
        name: "Target Audience",
        content: "Young professionals aged 25-35 interested in technology and innovation",
        orderIndex: 0
    )
    @Previewable @State var isExpanded = false

    ExpandableSpecificationSection(
        section: $section,
        isExpanded: $isExpanded,
        projectLLMConnectionId: nil,
        onChanged: { print("Changed") },
        onDelete: { print("Delete") },
        onMoveUp: { print("Move up") },
        onMoveDown: { print("Move down") }
    )
    .padding()
}

#Preview("Expanded Section") {
    @Previewable @State var section = SpecificationSectionData(
        name: "Target Audience",
        content: "Young professionals aged 25-35 interested in technology and innovation",
        orderIndex: 0
    )
    @Previewable @State var isExpanded = true

    ExpandableSpecificationSection(
        section: $section,
        isExpanded: $isExpanded,
        projectLLMConnectionId: nil,
        onChanged: { print("Changed") },
        onDelete: { print("Delete") },
        onMoveUp: { print("Move up") },
        onMoveDown: { print("Move down") }
    )
    .padding()
}

#Preview("No Move Buttons") {
    @Previewable @State var section = SpecificationSectionData(
        name: "Only Section",
        content: "This is the only section, so no move buttons are shown",
        orderIndex: 0
    )
    @Previewable @State var isExpanded = false

    ExpandableSpecificationSection(
        section: $section,
        isExpanded: $isExpanded,
        projectLLMConnectionId: nil,
        onChanged: { print("Changed") },
        onDelete: { print("Delete") },
        onMoveUp: nil,
        onMoveDown: nil
    )
    .padding()
}
