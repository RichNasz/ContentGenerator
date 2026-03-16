//
//  BundleWelcomeView.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import SwiftUI

struct BundleWelcomeView: View {
    @Environment(BundleManager.self) private var bundleManager

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "doc.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)

            Text("Content Generator")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create a new bundle or open an existing one to get started.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                #if os(macOS)
                Button("Create New Bundle") {
                    Task {
                        _ = await bundleManager.createNewBundle()
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button("Open Existing Bundle") {
                    Task {
                        _ = await bundleManager.openExistingBundle()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                #endif
            }

            if case .error(let message) = bundleManager.bundleState {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .padding(.top, 8)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
