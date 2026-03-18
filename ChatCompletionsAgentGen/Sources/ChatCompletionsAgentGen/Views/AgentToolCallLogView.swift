//
//  AgentToolCallLogView.swift
//  ChatCompletionsAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import SwiftChatCompletionsDSL

/// Scrollable list showing all tool calls made during an agent session.
///
/// While the agent is running, pass `inProgressTool` to show a live spinner row
/// for the currently executing tool call.
struct AgentToolCallLogView: View {
    let entries: [ToolCallLogEntry]
    var inProgressTool: String? = nil

    var body: some View {
        if entries.isEmpty && inProgressTool == nil {
            Text("No tool calls yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(entries.enumerated()), id: \.offset) { index, entry in
                        AgentToolCallLogRow(index: index + 1, entry: entry)
                    }
                    if let toolName = inProgressTool {
                        AgentToolCallInProgressRow(toolName: toolName, index: entries.count + 1)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
    }
}

// MARK: - Row View

/// A single tool call log entry showing name, duration, and expandable argument/result details.
private struct AgentToolCallLogRow: View {
    let index: Int
    let entry: ToolCallLogEntry

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // Summary row — always visible
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.caption)
                    .foregroundStyle(.blue)

                Text("\(index). \(entry.name)")
                    .font(.caption)
                    .fontWeight(.medium)

                Spacer()

                Text(formattedDuration)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Button(isExpanded ? "Hide" : "Details") {
                    isExpanded.toggle()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.blue)
            }

            // Expanded details
            if isExpanded {
                let hasArgs = !entry.arguments.isEmpty && entry.arguments != "{}"

                if hasArgs {
                    labeledBlock(label: "Arguments", content: entry.arguments)
                }

                let resultPreview = entry.result.count > 400
                    ? String(entry.result.prefix(400)) + "…"
                    : entry.result
                labeledBlock(label: "Result", content: resultPreview)
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private func labeledBlock(label: String, content: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label + ":")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(content)
                .font(.caption2)
                .padding(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
        }
    }

    /// Formats the tool call duration as milliseconds.
    private var formattedDuration: String {
        let ms = entry.duration.components.seconds * 1000
            + entry.duration.components.attoseconds / 1_000_000_000_000_000
        return "\(ms)ms"
    }
}

// MARK: - In-Progress Row

/// A spinner row shown while a tool call is actively executing.
private struct AgentToolCallInProgressRow: View {
    let toolName: String
    let index: Int

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)
            Text("\(index). \(toolName)")
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text("running…")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}
