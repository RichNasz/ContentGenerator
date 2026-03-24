//
//  ActivityLogView.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import SwiftUI

// MARK: - Model

/// A single entry in the unified activity log.
struct ActivityLogEntry: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case status(String)
        case thinkingSummary(String)
        case thinkingBlock(String)
        case toolCallStarted(callId: String, name: String, arguments: String)
        case toolCallCompleted(callId: String, name: String, arguments: String, result: String, duration: Duration)
        case tokenUsage(String)
        case completed
        case failed(String)
    }
}

// MARK: - Activity Log View

/// Scrollable chronological log of all agent events during a session.
struct ActivityLogView: View {
    let entries: [ActivityLogEntry]

    var body: some View {
        if entries.isEmpty {
            Text("No activity yet.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding()
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(entries) { entry in
                            ActivityLogRow(entry: entry)
                                .id(entry.id)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .onChange(of: entries.count) {
                    if let last = entries.last {
                        withAnimation(.easeOut(duration: 0.15)) {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Row Dispatcher

private struct ActivityLogRow: View {
    let entry: ActivityLogEntry

    var body: some View {
        switch entry.kind {
        case .status(let text):
            StatusRow(text: text)
        case .thinkingSummary(let summary):
            ThinkingSummaryRow(summary: summary)
        case .thinkingBlock(let block):
            ThinkingBlockRow(block: block)
        case .toolCallStarted(_, let name, _):
            ToolCallInProgressRow(toolName: name)
        case .toolCallCompleted(_, let name, let args, let result, let duration):
            ToolCallCompletedRow(name: name, arguments: args, result: result, duration: duration)
        case .tokenUsage(let summary):
            TokenUsageRow(summary: summary)
        case .completed:
            CompletionRow()
        case .failed(let message):
            FailureRow(message: message)
        }
    }
}

// MARK: - Row Views

private struct StatusRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "info.circle")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct ThinkingSummaryRow: View {
    let summary: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "brain")
                .font(.caption)
                .foregroundStyle(.purple)
            Text(summary)
                .font(.caption2)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct ThinkingBlockRow: View {
    let block: String
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundStyle(.purple)
                Text("Thinking Block")
                    .font(.caption)
                    .fontWeight(.medium)
                Spacer()
                Text(wordCountSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Button(isExpanded ? "Hide" : "Show") {
                    isExpanded.toggle()
                }
                .font(.caption2)
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
            }

            if isExpanded {
                Text(block)
                    .font(.caption2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(6)
                    .textSelection(.enabled)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private var wordCountSummary: String {
        let words = block.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .count
        return "~\(words) words"
    }
}

private struct ToolCallInProgressRow: View {
    let toolName: String

    var body: some View {
        HStack(spacing: 8) {
            ProgressView()
                .scaleEffect(0.6)
                .frame(width: 12, height: 12)
            Text(toolName)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text("running...")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .italic()
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct ToolCallCompletedRow: View {
    let name: String
    let arguments: String
    let result: String
    let duration: Duration

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Image(systemName: "function")
                    .font(.caption)
                    .foregroundStyle(.blue)
                Text(name)
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

            if isExpanded {
                let hasArgs = !arguments.isEmpty && arguments != "{}"
                if hasArgs {
                    labeledBlock(label: "Arguments", content: arguments)
                }
                let resultPreview = result.count > 400
                    ? String(result.prefix(400)) + "..."
                    : result
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

    private var formattedDuration: String {
        let ms = duration.components.seconds * 1000
            + duration.components.attoseconds / 1_000_000_000_000_000
        return "\(ms)ms"
    }
}

private struct TokenUsageRow: View {
    let summary: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "gauge.with.dots.needle.33percent")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(summary)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct CompletionRow: View {
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
            Text("Generation complete")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}

private struct FailureRow: View {
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "xmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.red)
            Text(message)
                .font(.caption2)
                .foregroundStyle(.red)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }
}
#endif
