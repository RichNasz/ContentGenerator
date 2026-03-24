//
//  String+ThinkingBlocks.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// The result of parsing `<think>...</think>` blocks from an LLM response string.
struct ThinkingParseResult: Sendable {
    /// Text outside all `<think>` blocks, whitespace-trimmed and joined.
    let content: String
    /// Text from each `<think>...</think>` block, in document order.
    let thinkingBlocks: [String]
}

extension String {
    /// Extracts `<think>...</think>` blocks from the receiver.
    ///
    /// - Returns: A `ThinkingParseResult` with the stripped content and an array of
    ///   reasoning strings (one per block). Tag matching is case-insensitive.
    func extractingThinkingBlocks() -> ThinkingParseResult {
        let openTag = "<think>"
        let closeTag = "</think>"
        var remaining = self
        var contentParts: [String] = []
        var thinkingParts: [String] = []

        while let openRange = remaining.range(of: openTag, options: .caseInsensitive) {
            let before = String(remaining[remaining.startIndex..<openRange.lowerBound])
            if !before.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                contentParts.append(before)
            }
            let afterOpen = String(remaining[openRange.upperBound...])
            if let closeRange = afterOpen.range(of: closeTag, options: .caseInsensitive) {
                let thinking = String(afterOpen[afterOpen.startIndex..<closeRange.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinking.isEmpty { thinkingParts.append(thinking) }
                remaining = String(afterOpen[closeRange.upperBound...])
            } else {
                // Unclosed tag -- treat the rest as thinking content.
                let thinking = afterOpen.trimmingCharacters(in: .whitespacesAndNewlines)
                if !thinking.isEmpty { thinkingParts.append(thinking) }
                remaining = ""
                break
            }
        }

        let tail = remaining.trimmingCharacters(in: .whitespacesAndNewlines)
        if !tail.isEmpty { contentParts.append(tail) }

        let finalContent = contentParts
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")

        return ThinkingParseResult(content: finalContent, thinkingBlocks: thinkingParts)
    }
}
