//
//  BundleManager.swift
//  ContentGenerator
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import Observation
import UniformTypeIdentifiers

#if os(macOS)
import AppKit
#endif

// MARK: - Bundle State

enum BundleState: Sendable {
    case noBundleSelected
    case loading
    case ready(URL)
    case error(String)
}

enum BundleManagerError: LocalizedError {
    case noBundleSelected

    var errorDescription: String? {
        switch self {
        case .noBundleSelected:
            return "No bundle is currently open. Please create or open a bundle first."
        }
    }
}

// MARK: - Bundle Manager

@MainActor
@Observable
final class BundleManager {
    private(set) var bundleURL: URL?
    var bundleState: BundleState = .noBundleSelected

    private static let bookmarkKey = "cgspecsBundleBookmark"

    // MARK: - Create New Bundle

    #if os(macOS)
    func createNewBundle() async -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [.cgspecs]
        savePanel.nameFieldStringValue = "My Projects"
        savePanel.title = "Create New Bundle"
        savePanel.prompt = "Create"

        let response = await savePanel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow())

        guard response == .OK, let url = savePanel.url else {
            return nil
        }

        do {
            // Create the package directory
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

            // Create bundle subdirectories
            try FileManager.default.createDirectory(
                at: url.appendingPathComponent("swiftdata"),
                withIntermediateDirectories: true
            )
            try FileManager.default.createDirectory(
                at: url.appendingPathComponent("projects"),
                withIntermediateDirectories: true
            )

            // Store security-scoped bookmark
            try saveBookmark(for: url)

            bundleURL = url
            bundleState = .ready(url)
            return url
        } catch {
            bundleState = .error("Failed to create bundle: \(error.localizedDescription)")
            return nil
        }
    }
    #endif

    // MARK: - Open Existing Bundle

    #if os(macOS)
    func openExistingBundle() async -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.cgspecs]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.title = "Open Bundle"
        openPanel.prompt = "Open"

        let response = await openPanel.beginSheetModal(for: NSApp.keyWindow ?? NSApp.mainWindow ?? NSWindow())

        guard response == .OK, let url = openPanel.url else {
            return nil
        }

        do {
            // Validate the bundle structure
            guard FileManager.default.fileExists(atPath: url.path) else {
                bundleState = .error("Bundle not found at selected location.")
                return nil
            }

            // Store security-scoped bookmark
            try saveBookmark(for: url)

            bundleURL = url
            bundleState = .ready(url)
            return url
        } catch {
            bundleState = .error("Failed to open bundle: \(error.localizedDescription)")
            return nil
        }
    }
    #endif

    // MARK: - Restore Saved Bundle

    func restoreSavedBundle() -> URL? {
        guard let bookmarkData = UserDefaults.standard.data(forKey: Self.bookmarkKey) else {
            return nil
        }

        do {
            var isStale = false
            let url = try URL(
                resolvingBookmarkData: bookmarkData,
                options: .withSecurityScope,
                relativeTo: nil,
                bookmarkDataIsStale: &isStale
            )

            guard url.startAccessingSecurityScopedResource() else {
                bundleState = .error("Could not access saved bundle. Please open it again.")
                return nil
            }

            // Refresh stale bookmark
            if isStale {
                try saveBookmark(for: url)
            }

            bundleURL = url
            bundleState = .ready(url)
            return url
        } catch {
            bundleState = .error("Could not restore saved bundle: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Attachments Directory Helper

    /// Returns the `projects/<uuid>/attachments/` directory within the bundle, creating it if needed.
    /// - Throws: `BundleManagerError.noBundleSelected` if no bundle is open.
    func attachmentsDirectory(for projectId: UUID) throws -> URL {
        guard let bundleURL else {
            throw BundleManagerError.noBundleSelected
        }
        let dir = bundleURL
            .appendingPathComponent("projects")
            .appendingPathComponent(projectId.uuidString)
            .appendingPathComponent("attachments")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Bookmark Persistence

    private func saveBookmark(for url: URL) throws {
        let bookmarkData = try url.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )
        UserDefaults.standard.set(bookmarkData, forKey: Self.bookmarkKey)
    }
}
