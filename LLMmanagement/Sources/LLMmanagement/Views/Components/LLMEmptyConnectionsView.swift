//
//  LLMEmptyConnectionsView.swift
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

/// An empty state view displayed when no LLM connections exist.
///
/// This component follows Apple Human Interface Guidelines for empty states,
/// providing clear guidance and a prominent call-to-action for users to
/// create their first connection.
///
/// ## Features
/// - Helpful empty state messaging
/// - Prominent "Create Connection" button
/// - Apple HIG compliant design
/// - Full accessibility support
/// - Proper spacing and visual hierarchy
///
/// ## Usage
/// ```swift
/// if connections.isEmpty {
///     LLMEmptyConnectionsView {
///         // Action to create new connection
///         showingCreateConnection = true
///     }
/// }
/// ```
public struct LLMEmptyConnectionsView: View {
    /// The action to perform when the user taps "Create Connection".
    public let createAction: () -> Void

    /// Creates a new empty state view with the specified create action.
    ///
    /// - Parameter createAction: The closure to execute when the user taps "Create Connection"
    public init(createAction: @escaping () -> Void) {
        self.createAction = createAction
    }

    public var body: some View {
        VStack(spacing: 24) {
            // Empty state illustration
            emptyStateIcon

            // Content
            VStack(spacing: 16) {
                Text("No Connections")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Text("Create your first LLM connection to get started. You can connect to services like OpenAI, local Ollama instances, or any OpenAI-compatible API.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Call to action
            Button {
                createAction()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.headline)

                    Text("Create Your First Connection")
                        .font(.headline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Create your first connection")
            .accessibilityHint("Opens the connection creation form")
        }
        .padding(.horizontal, 32)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("No connections available")
    }
}

// MARK: - Private Views

private extension LLMEmptyConnectionsView {

    @ViewBuilder
    var emptyStateIcon: some View {
        VStack(spacing: 12) {
            // Stack of connection icons to represent multiple connections
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .frame(width: 60, height: 60)
                    .offset(x: -8, y: -8)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 60, height: 60)
                    .offset(x: -4, y: -4)

                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.accentColor.opacity(0.8))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "link")
                            .font(.title)
                            .foregroundColor(.white)
                    }
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Preview

#Preview("Empty Connections") {
    NavigationStack {
        LLMEmptyConnectionsView {
            print("Create connection tapped")
        }
        .navigationTitle("Connections")
    }
}

#Preview("Empty Connections - Dark Mode") {
    NavigationStack {
        LLMEmptyConnectionsView {
            print("Create connection tapped")
        }
        .navigationTitle("Connections")
    }
    .preferredColorScheme(.dark)
}