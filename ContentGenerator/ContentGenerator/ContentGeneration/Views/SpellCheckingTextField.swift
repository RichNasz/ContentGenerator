//
//  SpellCheckingTextField.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI
import AppKit

/// A single-line text field with continuous spell checking and grammar checking enabled by default.
/// This wraps NSTextField to provide native macOS spelling and grammar features.
struct SpellCheckingTextField: NSViewRepresentable {
    let placeholder: String
    @Binding var text: String

    func makeNSView(context: Context) -> NSTextField {
        let textField = NSTextField()

        // Configure text field appearance to match SwiftUI TextField with roundedBorder style
        textField.placeholderString = placeholder
        textField.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        textField.bezelStyle = .roundedBezel
        textField.isBordered = true
        textField.drawsBackground = true
        textField.backgroundColor = .textBackgroundColor

        // Enable spell checking - this affects the field editor used when editing
        textField.allowsEditingTextAttributes = false

        // Set delegate for text changes
        textField.delegate = context.coordinator

        return textField
    }

    func updateNSView(_ textField: NSTextField, context: Context) {
        // Only update if text has changed externally (not from user typing)
        if textField.stringValue != text {
            textField.stringValue = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: SpellCheckingTextField

        init(_ parent: SpellCheckingTextField) {
            self.parent = parent
        }

        func controlTextDidChange(_ notification: Notification) {
            guard let textField = notification.object as? NSTextField else {
                return
            }
            parent.text = textField.stringValue
        }

        func controlTextDidBeginEditing(_ notification: Notification) {
            // When editing begins, configure the field editor for spell checking
            guard let textField = notification.object as? NSTextField,
                  let fieldEditor = textField.currentEditor() as? NSTextView else {
                return
            }

            // Enable spell checking and grammar checking on the field editor
            fieldEditor.isContinuousSpellCheckingEnabled = true
            fieldEditor.isGrammarCheckingEnabled = true
        }
    }
}

#Preview {
    @Previewable @State var text = ""

    SpellCheckingTextField(placeholder: "Enter some text with spelling erors", text: $text)
        .padding()
}
