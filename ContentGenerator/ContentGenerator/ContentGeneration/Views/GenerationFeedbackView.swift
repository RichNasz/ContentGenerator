//
//  GenerationFeedbackView.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

// MARK: - Model

/// A single entry in the generation feedback log.
struct GenerationFeedbackEntry: Identifiable {
    let id = UUID()
    let kind: Kind

    enum Kind {
        case status(String)
        case thinkingSummary(String)
        case thinkingBlock(String)
        case tokenUsage(String)
        case completed
        case failed(String)
    }
}

// MARK: - Feedback View

/// Scrollable chronological log of generation events shown in the LLM controls column.
struct GenerationFeedbackView: View {
    let entries: [GenerationFeedbackEntry]

    var body: some View {
        if entries.isEmpty {
            EmptyView()
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 4) {
                        ForEach(entries) { entry in
                            GenerationFeedbackRow(entry: entry)
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

private struct GenerationFeedbackRow: View {
    let entry: GenerationFeedbackEntry

    var body: some View {
        switch entry.kind {
        case .status(let text):
            FeedbackStatusRow(text: text)
        case .thinkingSummary(let summary):
            FeedbackThinkingSummaryRow(summary: summary)
        case .thinkingBlock(let block):
            FeedbackThinkingBlockRow(block: block)
        case .tokenUsage(let summary):
            FeedbackTokenUsageRow(summary: summary)
        case .completed:
            FeedbackCompletionRow()
        case .failed(let message):
            FeedbackFailureRow(message: message)
        }
    }
}

// MARK: - Row Views

private struct FeedbackStatusRow: View {
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

private struct FeedbackThinkingSummaryRow: View {
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

private struct FeedbackThinkingBlockRow: View {
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

private struct FeedbackTokenUsageRow: View {
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

private struct FeedbackCompletionRow: View {
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

private struct FeedbackFailureRow: View {
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

// MARK: - Think Block Extraction

/// Extracts completed `<think>…</think>` blocks from content, returning the cleaned text
/// and an array of extracted block strings. Case-insensitive; handles unclosed tags.
func extractThinkingBlocks(from text: String) -> (content: String, blocks: [String]) {
    var content = text
    var blocks: [String] = []

    let openTag = "<think>"
    let closeTag = "</think>"

    // Extract completed blocks
    while let closeRange = content.range(of: closeTag, options: .caseInsensitive) {
        let prefix = String(content[content.startIndex..<closeRange.lowerBound])
        if let openRange = prefix.range(of: openTag, options: [.caseInsensitive, .backwards]) {
            let block = String(prefix[openRange.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !block.isEmpty { blocks.append(block) }
            let before = String(content[content.startIndex..<openRange.lowerBound])
            let after = String(content[closeRange.upperBound...])
            content = before + after
        } else {
            // Close tag without matching open — strip it
            content = String(content[content.startIndex..<closeRange.lowerBound])
                + String(content[closeRange.upperBound...])
        }
    }

    // Handle unclosed opening tag
    if let openRange = content.range(of: openTag, options: .caseInsensitive) {
        let block = String(content[openRange.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !block.isEmpty { blocks.append(block) }
        content = String(content[content.startIndex..<openRange.lowerBound])
    }

    return (content.trimmingCharacters(in: .whitespacesAndNewlines), blocks)
}
