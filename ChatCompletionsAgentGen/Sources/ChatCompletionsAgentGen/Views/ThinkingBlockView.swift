//
//  ThinkingBlockView.swift
//  ChatCompletionsAgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

#if os(macOS)
import SwiftUI

/// Collapsible panel that displays chain-of-thought reasoning blocks from thinking models.
///
/// Collapsed by default; shows a word-count summary in the header.
/// Expands to show each `<think>…</think>` block in a scrollable text box.
struct ThinkingBlockView: View {
    let blocks: [String]

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header row — always visible
            HStack(spacing: 8) {
                Image(systemName: "brain")
                    .font(.caption)
                    .foregroundStyle(.purple)

                Text("Thinking Process")
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

            // Expanded block content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { index, block in
                        VStack(alignment: .leading, spacing: 2) {
                            if blocks.count > 1 {
                                Text("Block \(index + 1)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            ScrollView {
                                Text(block)
                                    .font(.caption2)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(6)
                                    .textSelection(.enabled)
                            }
                            .frame(maxHeight: 200)
                            .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 4))
                        }
                    }
                }
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 6))
    }

    private var wordCountSummary: String {
        let totalWords = blocks
            .flatMap { $0.components(separatedBy: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .count
        let blockWord = blocks.count == 1 ? "block" : "blocks"
        return "\(blocks.count) \(blockWord), ~\(totalWords) words"
    }
}
#endif
