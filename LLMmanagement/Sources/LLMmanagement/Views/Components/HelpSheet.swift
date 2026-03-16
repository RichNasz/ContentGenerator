//
//  HelpSheet.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
#if os(macOS)
import AppKit
#endif

/// A modal presentation for contextual help content.
///
/// This component presents help content in a platform-appropriate modal view
/// that follows Apple's Human Interface Guidelines for help presentation.
/// The sheet provides a structured layout for help information with proper
/// accessibility support and navigation.
///
/// ## Features
/// - Platform-appropriate modal presentation
/// - Structured content layout with clear hierarchy
/// - Comprehensive accessibility support
/// - Support for Dynamic Type scaling
/// - Dismissal gestures and keyboard shortcuts
public struct HelpSheet: View {
    /// The help content to display.
    public let content: HelpContent

    /// Environment value for dismissing the sheet.
    @Environment(\.dismiss) private var dismiss

    /// Creates a new help sheet with the specified content.
    ///
    /// - Parameter content: The help content to display
    public init(content: HelpContent) {
        self.content = content
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Summary section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Overview")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .accessibilityAddTraits(.isHeader)

                        Text(content.summary)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // Detailed explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Details")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .accessibilityAddTraits(.isHeader)

                        Text(content.details)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // Examples section
                    if !content.examples.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Examples")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .accessibilityAddTraits(.isHeader)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(content.examples.enumerated()), id: \.offset) { index, example in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "lightbulb")
                                            .foregroundColor(.secondary)
                                            .font(.callout)
                                            .accessibilityHidden(true)

                                        Text(example)
                                            .font(.callout)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 4)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Example \(index + 1): \(example)")
                                }
                            }
                        }
                    }

                    // Tips section (if available)
                    if let tips = content.tips, !tips.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Tips")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .accessibilityAddTraits(.isHeader)

                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(tips.enumerated()), id: \.offset) { index, tip in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "star")
                                            .foregroundColor(.secondary)
                                            .font(.callout)
                                            .accessibilityHidden(true)

                                        Text(tip)
                                            .font(.callout)
                                            .foregroundColor(.primary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(.vertical, 4)
                                    .accessibilityElement(children: .combine)
                                    .accessibilityLabel("Tip \(index + 1): \(tip)")
                                }
                            }
                        }
                    }

                    // Bottom spacing for better scrolling experience
                    Spacer(minLength: 20)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle(content.title)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .accessibilityLabel("Done")
                    .accessibilityHint("Close help and return to form")
                    .accessibilityAddTraits(.isButton)
                }
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Help content for \(content.title)")
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}

// MARK: - Compact Help View

/// A compact version of help content for inline display.
///
/// This view is designed for cases where a full sheet might be too intrusive,
/// such as in popovers or small spaces.
public struct CompactHelpView: View {
    public let content: HelpContent

    public init(content: HelpContent) {
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(content.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(content.summary)
                .font(.body)
                .foregroundColor(.primary)

            if !content.examples.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Examples:")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ForEach(content.examples.prefix(3), id: \.self) { example in
                        Text("• \(example)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        #if os(iOS)
        .background(Color(.systemGroupedBackground))
        #else
        .background(Color(NSColor.controlBackgroundColor))
        #endif
        .cornerRadius(8)
        .frame(maxWidth: 300)
    }
}

// MARK: - Preview

#Preview("Help Sheet") {
    Text("Tap to show help")
        .sheet(isPresented: .constant(true)) {
            HelpSheet(content: .connectionName)
        }
}

#Preview("Compact Help") {
    VStack {
        CompactHelpView(content: .endpointType)
        CompactHelpView(content: .baseUrl)
    }
    .padding()
}