//
//  SectionReadTracker.swift
//  AgentGen
//
//  Created by Richard Naszcyniec with AI-assisted code generation.
//
//  This source code is open source under the terms of the license.txt
//  file located in the root directory of this project.
//

import Foundation

/// Tracks which specification section names have been successfully read by the agent during a session.
///
/// Used by `ReadSectionTool` to record reads and by `GetUnreadSectionsTool` to query remaining
/// unread enabled sections. Thread-safe via actor isolation.
public actor SectionReadTracker {
    private var readNames: Set<String> = []

    public init() {}

    func markRead(_ name: String) {
        readNames.insert(name)
    }

    func unreadSections(from sections: [AgentSection]) -> [AgentSection] {
        sections.filter { $0.isEnabled && !readNames.contains($0.name) }
    }
}
