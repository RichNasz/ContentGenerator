//
//  LLMmanagement.swift
//  LLMmanagement
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation
import SwiftUI
import SwiftData

/// LLMmanagement Package
///
/// A comprehensive SwiftUI package for managing Large Language Model connections
/// with automatic persistence through SwiftData. This package provides a complete
/// set of views and components for creating, editing, listing, and managing
/// LLM service configurations.
///
/// ## Core Components
///
/// ### Models
/// - `LLMConnection`: SwiftData model for LLM service configurations
/// - `OpenAIEndpointType`: Enum for specifying API endpoint types
///
/// ### Views
/// - `LLMConnectionListView`: Main list view for managing connections
/// - `LLMConnectionEditView`: Form view for creating/editing connections
/// - `LLMConnectionRow`: List row component for displaying connections
/// - `LLMEmptyConnectionsView`: Empty state view for connection lists
///
/// ### Help System
/// - `HelpContent`: Structured help content data
/// - `HelpButton`: Contextual help button component
/// - `HelpSheet`: Modal help presentation view
///
/// ## Usage
///
/// Add the package to your SwiftData schema and use the views in your app:
///
/// ```swift
/// import LLMmanagement
///
/// // In your app's model container setup
/// let schema = Schema([
///     LLMConnection.self,
///     // ... other models
/// ])
///
/// // In your SwiftUI views
/// NavigationStack {
///     LLMConnectionListView()
///         .modelContainer(for: LLMConnection.self)
/// }
/// ```
public struct LLMmanagement {
    /// Package version information
    public static let version = "1.0.0"

    /// Package identifier
    public static let identifier = "com.anthropic.llmmanagement"
}