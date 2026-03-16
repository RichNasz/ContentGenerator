//
//  SpellCheckingTextEditor.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import AppKit

/// A multi-line text editor with spell checking that only accepts plain text.
struct SpellCheckingTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        // Use scrollableTextView() for proper text system setup
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else {
            return scrollView
        }

        // Plain text only - prevents rich text issues
        textView.isRichText = false
        textView.importsGraphics = false
        textView.allowsUndo = true

        // Enable spell/grammar checking (red underlines, right-click suggestions)
        textView.isContinuousSpellCheckingEnabled = true
        textView.isGrammarCheckingEnabled = true

        // CRITICAL: Disable automatic text completion to prevent crashes
        textView.isAutomaticTextCompletionEnabled = false

        // Appearance
        textView.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = .clear
        textView.drawsBackground = false

        // Layout
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.containerSize = NSSize(
            width: scrollView.contentSize.width,
            height: CGFloat.greatestFiniteMagnitude
        )

        // Delegate
        textView.delegate = context.coordinator
        context.coordinator.textView = textView

        // Scroll view config
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        guard !context.coordinator.isUpdating else { return }

        // If the spell checker has active marked text (inline prediction), skip
        // this update entirely and defer it. Editing text storage while marked
        // text is active triggers _NSClearMarkedRange → insertText → undo
        // coalescing → NSRangeException. See ERR-RUNTIME-001.
        if textView.hasMarkedText() {
            context.coordinator.scheduleDeferredTextUpdate(text)
            return
        }

        if textView.string != text {
            context.coordinator.performDirectUpdate(text, on: textView)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: SpellCheckingTextEditor
        var isUpdating = false
        weak var textView: NSTextView?

        private var pendingText: String?
        private var retryCount = 0
        private let maxRetries = 5

        init(_ parent: SpellCheckingTextEditor) {
            self.parent = parent
        }

        /// Schedule a deferred text update when the text view has active marked text.
        /// The update will retry until marked text clears or maxRetries is reached.
        func scheduleDeferredTextUpdate(_ text: String) {
            pendingText = text
            retryCount = 0
            attemptDeferredUpdate()
        }

        private func attemptDeferredUpdate() {
            guard let text = pendingText, let textView = textView else {
                pendingText = nil
                retryCount = 0
                return
            }

            // If marked text cleared, apply the update now
            if !textView.hasMarkedText() {
                pendingText = nil
                retryCount = 0
                if textView.string != text {
                    performDirectUpdate(text, on: textView)
                }
                return
            }

            // Safety valve: stop retrying after maxRetries
            retryCount += 1
            if retryCount > maxRetries {
                pendingText = nil
                retryCount = 0
                return
            }

            // Retry after 50ms
            Task { @MainActor [weak self] in
                try? await Task.sleep(for: .milliseconds(50))
                self?.attemptDeferredUpdate()
            }
        }

        /// Apply text directly to the text view's storage, bypassing the text input
        /// system entirely. Uses `allowsUndo = false` to prevent NSUndoTyping creation
        /// during `shouldChangeText` callbacks triggered by `endEditing`. See ERR-RUNTIME-001.
        func performDirectUpdate(_ text: String, on textView: NSTextView) {
            isUpdating = true

            // Save the current selection before replacing text.
            // selectedRange() can return NSNotFound for location in edge cases
            // (e.g., text view not yet laid out, or during teardown).
            let previousSelection = textView.selectedRange()

            let storage = textView.textStorage!
            textView.allowsUndo = false
            storage.beginEditing()
            let attributes = textView.typingAttributes
            storage.replaceCharacters(
                in: NSRange(location: 0, length: storage.length),
                with: NSAttributedString(string: text, attributes: attributes)
            )
            storage.endEditing()
            textView.allowsUndo = true

            // Restore cursor position with safety checks to prevent NSRangeException.
            let utf16Length = (textView.string as NSString).length

            let previousLocation = previousSelection.location
            if previousLocation == NSNotFound || previousLocation < 0 {
                // Fallback: place cursor at end if previous location was invalid
                textView.setSelectedRange(NSRange(location: utf16Length, length: 0))
            } else {
                // Clamp location to [0, utf16Length]
                let clampedLocation = min(previousLocation, utf16Length)
                // Clamp selection length so location + length <= utf16Length
                let maxLength = utf16Length - clampedLocation
                let clampedLength = min(max(previousSelection.length, 0), maxLength)
                textView.setSelectedRange(NSRange(location: clampedLocation, length: clampedLength))
            }

            isUpdating = false
        }

        func textDidChange(_ notification: Notification) {
            guard !isUpdating else { return }
            guard let textView = notification.object as? NSTextView else { return }

            let newText = textView.string
            guard newText != parent.text else { return }

            // Defer binding update to next run loop to avoid reentrancy
            Task { @MainActor [weak self] in
                guard let self else { return }
                guard !self.isUpdating else { return }
                // Verify text view still has same content
                if self.textView?.string == newText {
                    self.parent.text = newText
                }
            }
        }

        // Intercept paste to ensure plain text
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            if commandSelector == #selector(NSText.paste(_:)) {
                textView.pasteAsPlainText(nil)
                return true
            }
            return false
        }
    }
}

#Preview {
    @Previewable @State var text = "This is some sampel text with spelling erors."

    SpellCheckingTextEditor(text: $text)
        .frame(minHeight: 100, maxHeight: 200)
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
        )
        .padding()
}
