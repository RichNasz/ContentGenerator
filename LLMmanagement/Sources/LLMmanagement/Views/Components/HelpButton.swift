//
//  HelpButton.swift
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

/// A contextual help button that follows Apple Human Interface Guidelines.
///
/// This component provides users with immediate access to relevant help content
/// without leaving their current context. The button uses standard SF Symbols
/// and presents help content in a platform-appropriate manner.
///
/// ## Usage
/// ```swift
/// HStack {
///     Text("Connection Name")
///     Spacer()
///     HelpButton(content: .connectionName)
/// }
/// ```
///
/// ## Features
/// - Platform-appropriate presentation (sheet on iOS, popover on macOS)
/// - Full accessibility support with VoiceOver
/// - Subtle, non-intrusive design
/// - Haptic feedback on iOS
public struct HelpButton: View {
    /// The help content to display when the button is tapped.
    public let content: HelpContent

    /// Controls the presentation of the help sheet.
    @State private var showingHelp = false

    /// Creates a new help button with the specified content.
    ///
    /// - Parameter content: The help content to display
    public init(content: HelpContent) {
        self.content = content
    }

    public var body: some View {
        Button {
            #if os(iOS)
            // Provide haptic feedback on iOS for better discoverability
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif

            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
                .font(.callout)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Help")
        .accessibilityHint("Show help for \(content.title)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Show Help") {
            showingHelp = true
        }
        .sheet(isPresented: $showingHelp) {
            HelpSheet(content: content)
        }
    }
}

/// A specialized help button for use in section headers.
///
/// This variant is designed to be used in section headers where space is more
/// constrained and the visual hierarchy should be preserved.
public struct SectionHelpButton: View {
    public let content: HelpContent
    @State private var showingHelp = false

    public init(content: HelpContent) {
        self.content = content
    }

    public var body: some View {
        Button {
            #if os(iOS)
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            #endif

            showingHelp = true
        } label: {
            Image(systemName: "questionmark.circle")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Section help")
        .accessibilityHint("Show help for \(content.title)")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction(named: "Show Help") {
            showingHelp = true
        }
        .sheet(isPresented: $showingHelp) {
            HelpSheet(content: content)
        }
    }
}

// MARK: - Preview

#Preview("Help Button") {
    VStack(spacing: 20) {
        HStack {
            Text("Connection Name")
                .font(.headline)
            Spacer()
            HelpButton(content: .connectionName)
        }
        .padding()

        HStack {
            Text("Endpoint Type")
                .font(.headline)
            Spacer()
            HelpButton(content: .endpointType)
        }
        .padding()

        HStack {
            Text("Section Header")
                .font(.caption)
                .foregroundColor(.secondary)
            SectionHelpButton(content: .baseUrl)
        }
        .padding()
    }
    #if os(iOS)
    .background(Color(.systemGroupedBackground))
    #else
    .background(Color(NSColor.controlBackgroundColor))
    #endif
}