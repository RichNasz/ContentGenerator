//
//  ExpandableTextEditorWrapper.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

/// A button that expands the associated text editor into a larger modal sheet.
///
/// Follows Apple HIG for contextual action buttons with subtle visual presence.
struct TextEditorExpandButton: View {
    /// Controls the presentation of the expanded sheet
    @Binding var isExpanded: Bool

    var body: some View {
        Button {
            isExpanded = true
        } label: {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Expand editor")
        .accessibilityHint("Opens a larger text editing window")
        .accessibilityAddTraits(.isButton)
        .help("Expand to full editor")
    }
}

/// A modal sheet providing an expanded text editing experience.
///
/// Follows Apple HIG for modal presentation with proper navigation and dismissal.
struct ExpandedTextEditorSheet: View {
    /// The text being edited - two-way binding to parent
    @Binding var text: String

    /// Title for the header
    let title: String

    /// Placeholder text when empty
    let placeholder: String?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            SpellCheckingTextEditor(text: $text)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
                .overlay(placeholderOverlay)
                .navigationTitle(title)
                .navigationSubtitle("\(text.count) characters")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .keyboardShortcut(.return, modifiers: .command)
                        .accessibilityLabel("Done")
                        .accessibilityHint("Close editor and save changes")
                    }
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Expanded text editor")
    }

    @ViewBuilder
    private var placeholderOverlay: some View {
        if text.isEmpty, let placeholder = placeholder {
            VStack {
                HStack {
                    Text(placeholder)
                        .foregroundStyle(.secondary)
                        .padding(.leading, 20)
                        .padding(.top, 24)
                    Spacer()
                }
                Spacer()
            }
            .allowsHitTesting(false)
        }
    }
}

/// A text editor wrapper that adds expand-to-modal functionality.
///
/// Wraps SpellCheckingTextEditor with an expand button in the top-right corner.
/// When expanded, presents a large modal sheet for comfortable editing.
///
/// ## Usage
/// ```swift
/// ExpandableTextEditorWrapper(
///     text: $content,
///     title: "Content",
///     placeholder: "Enter your content here..."
/// )
/// .frame(minHeight: 100, maxHeight: 200)
/// ```
struct ExpandableTextEditorWrapper: View {
    /// The text being edited
    @Binding var text: String

    /// Title displayed in the expanded sheet header
    let title: String

    /// Placeholder text when empty
    let placeholder: String?

    /// Minimum height constraint for the collapsed editor
    let minHeight: CGFloat

    /// Maximum height constraint for the collapsed editor
    let maxHeight: CGFloat

    /// Controls sheet presentation
    @State private var isExpanded = false

    init(
        text: Binding<String>,
        title: String = "Edit Text",
        placeholder: String? = nil,
        minHeight: CGFloat = 100,
        maxHeight: CGFloat = 200
    ) {
        self._text = text
        self.title = title
        self.placeholder = placeholder
        self.minHeight = minHeight
        self.maxHeight = maxHeight
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            SpellCheckingTextEditor(text: $text)
                .frame(minHeight: minHeight, maxHeight: maxHeight)
                .padding(8)
                .background(Color(nsColor: .controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            TextEditorExpandButton(isExpanded: $isExpanded)
                .padding(8)
        }
        .sheet(isPresented: $isExpanded) {
            ExpandedTextEditorSheet(
                text: $text,
                title: title,
                placeholder: placeholder
            )
            .frame(minWidth: 600, idealWidth: 800, minHeight: 500, idealHeight: 600)
        }
        .accessibilityElement(children: .contain)
    }
}

// MARK: - Previews

#Preview("Collapsed State") {
    @Previewable @State var text = "Sample content for the text editor."

    ExpandableTextEditorWrapper(
        text: $text,
        title: "Test Section",
        placeholder: "Enter text..."
    )
    .padding()
}

#Preview("Empty State") {
    @Previewable @State var text = ""

    ExpandableTextEditorWrapper(
        text: $text,
        title: "Empty Section",
        placeholder: "Start typing here..."
    )
    .padding()
}

#Preview("Long Content") {
    @Previewable @State var text = String(repeating: "Lorem ipsum dolor sit amet. ", count: 50)

    ExpandableTextEditorWrapper(
        text: $text,
        title: "Long Content Section"
    )
    .padding()
}
