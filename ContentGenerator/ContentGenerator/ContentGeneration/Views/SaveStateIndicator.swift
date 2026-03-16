//
//  SaveStateIndicator.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

/// Represents the current save state for auto-save functionality
enum SaveState: Equatable {
    case saved
    case saving
    case error(String)
}

/// Visual indicator showing the current save state
struct SaveStateIndicator: View {
    let state: SaveState

    var body: some View {
        Group {
            switch state {
            case .saved:
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.caption)
                    .symbolRenderingMode(.multicolor)

            case .saving:
                HStack(spacing: 4) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Saving...")
                }
                .foregroundStyle(.secondary)
                .font(.caption)

            case .error(let message):
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .symbolRenderingMode(.multicolor)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: state)
    }
}

#Preview("Saved State") {
    SaveStateIndicator(state: .saved)
        .padding()
}

#Preview("Saving State") {
    SaveStateIndicator(state: .saving)
        .padding()
}

#Preview("Error State") {
    SaveStateIndicator(state: .error("Failed to save"))
        .padding()
}
