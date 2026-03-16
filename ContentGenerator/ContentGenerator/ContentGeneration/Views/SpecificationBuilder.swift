//
//  SpecificationBuilder.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//
//  DEPRECATED: This component used sheet-based editing.
//  ProjectDetailView now uses inline expandable sections instead.
//  Kept for reference or potential standalone use.
//

import SwiftUI
import UniformTypeIdentifiers

/// Dynamic specification builder for creating flexible content specifications
/// DEPRECATED: Use inline ExpandableSpecificationSection components instead
struct SpecificationBuilder: View {
    @Binding var sections: [SpecificationSectionData]
    @State private var showingAddSection = false
    @State private var newSectionName = ""
    @State private var newSectionContent = ""

    var body: some View {
        VStack(spacing: 16) {
            // Header with Add Section button
            HStack {
                Text("Content Specification")
                    .font(.headline)

                Spacer()

                Button(action: { showingAddSection = true }) {
                    Label("Add Section", systemImage: "plus.circle")
                }
                .buttonStyle(.bordered)
            }

            if sections.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.below.ecg")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)

                    Text("No specification sections yet")
                        .font(.title2)
                        .foregroundStyle(.secondary)

                    Text("Add sections to define what content you want to generate")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 32)
            } else {
                // Section list
                ForEach(sections.indices, id: \.self) { index in
                    SpecificationSectionRow(
                        section: $sections[index],
                        onDelete: { deleteSectionAtIndex(index) },
                        onMoveUp: index > 0 ? { moveSectionUp(index) } : nil,
                        onMoveDown: index < sections.count - 1 ? { moveSectionDown(index) } : nil
                    )
                }
            }
        }
        // DEPRECATED: Sheet-based adding removed
        // .sheet(isPresented: $showingAddSection) {
        //     AddSectionSheet(...)
        // }
    }

    // MARK: - Actions

    private func addNewSection() {
        let newSection = SpecificationSectionData(
            name: newSectionName,
            content: newSectionContent,
            orderIndex: sections.count
        )
        sections.append(newSection)
        cancelAddSection()
    }

    private func cancelAddSection() {
        newSectionName = ""
        newSectionContent = ""
        showingAddSection = false
    }

    private func deleteSectionAtIndex(_ index: Int) {
        sections.remove(at: index)
        // Reorder remaining sections
        for i in index..<sections.count {
            sections[i].orderIndex = i
        }
    }

    private func moveSectionUp(_ index: Int) {
        guard index > 0 else { return }
        sections.swapAt(index, index - 1)
        sections[index].orderIndex = index
        sections[index - 1].orderIndex = index - 1
    }

    private func moveSectionDown(_ index: Int) {
        guard index < sections.count - 1 else { return }
        sections.swapAt(index, index + 1)
        sections[index].orderIndex = index
        sections[index + 1].orderIndex = index + 1
    }
}

/// Individual specification section row
struct SpecificationSectionRow: View {
    @Binding var section: SpecificationSectionData
    let onDelete: () -> Void
    let onMoveUp: (() -> Void)?
    let onMoveDown: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Section header with controls
            HStack {
                Text(section.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                // Move buttons
                HStack(spacing: 4) {
                    if let onMoveUp = onMoveUp {
                        Button(action: onMoveUp) {
                            Image(systemName: "chevron.up")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    if let onMoveDown = onMoveDown {
                        Button(action: onMoveDown) {
                            Image(systemName: "chevron.down")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }

                    // DEPRECATED: Edit button removed (was sheet-based)
                    // Use ExpandableSpecificationSection for inline editing instead
                    // Button(action: { isEditing = true }) {
                    //     Image(systemName: "pencil")
                    // }
                    // .buttonStyle(.plain)
                    // .foregroundStyle(.secondary)

                    Button(action: onDelete) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.red)
                }
            }

            // Section content
            Text(section.content)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
        }
        .padding()
    }
}

/// Data model for specification sections in the UI
struct SpecificationSectionData: Identifiable, Codable, Transferable {
    var id: UUID
    var name: String
    var content: String
    var orderIndex: Int
    var isEnabled: Bool

    // LLM Prompts for AI-assisted content generation
    /// Prompt used when asking AI to help generate content FOR this section
    var contentGenerationPrompt: String?
    /// Prompt describing how to USE this section's content when generating project content
    var contentUsagePrompt: String?

    init(name: String, content: String, orderIndex: Int, isEnabled: Bool = true, contentGenerationPrompt: String? = nil, contentUsagePrompt: String? = nil) {
        self.id = UUID()
        self.name = name
        self.content = content
        self.orderIndex = orderIndex
        self.isEnabled = isEnabled
        self.contentGenerationPrompt = contentGenerationPrompt
        self.contentUsagePrompt = contentUsagePrompt
    }

    // MARK: - Transferable

    static var transferRepresentation: some TransferRepresentation {
        CodableRepresentation(contentType: .specificationSection)
    }
}

// MARK: - UTType Extension for Drag and Drop

extension UTType {
    nonisolated static var specificationSection: UTType {
        UTType(exportedAs: "com.contentgenerator.specification-section")
    }
}

#Preview {
    @Previewable @State var sections: [SpecificationSectionData] = [
        SpecificationSectionData(name: "Target Audience", content: "Young professionals aged 25-35", orderIndex: 0),
        SpecificationSectionData(name: "Tone", content: "Professional but approachable", orderIndex: 1)
    ]

    return SpecificationBuilder(sections: $sections)
        .padding()
}
