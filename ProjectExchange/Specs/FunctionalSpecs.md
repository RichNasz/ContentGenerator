# Functional Specifications

This document captures the "WHAT" of the ProjectExchange functionality in a language-agnostic manner. It describes what the system does, not how it's implemented.

## Overview

ProjectExchange is a library that provides portable transfer objects for importing and exporting ContentGenerator projects. It enables project data to be serialized to JSON format for backup, sharing, or use in other applications.

## Core Functionality

### Transfer Objects

**Purpose**
- Provide portable representations of project data independent of the persistence layer
- Enable cross-application data exchange without SwiftData dependencies
- Support schema versioning for forward and backward compatibility

**Characteristics**
- All transfer objects are value types (immutable after creation)
- Each object type mirrors a corresponding application model
- Objects contain only data, no business logic or side effects
- LLM configuration objects include unique identifiers for reference mapping during import

### Serialization

**JSON Format**
- All project data serialized to JSON for cross-application compatibility
- ISO8601 date encoding for portable, unambiguous timestamps
- Pretty-printed output for human readability
- UTF-8 encoding for text content
- Note: Key order is not guaranteed (Swift's JSONEncoder limitation)

**Serialization Service**
- Encode projects to JSON data or string format
- Decode projects from JSON data, string, or file URL
- Validate round-trip integrity (encode then decode produces equivalent data)

### Export Data Scope

**What IS Included**
- Project metadata: name, description, status, system prompt, timestamps
- Project-level LLM connection reference (for content generation)
- Specification sections: name, content, prompts, ordering, enabled state
- Section-level LLM connection references (for assistant functionality)
- File attachment metadata: original filename, file path, extension, size
- LLM configurations: array of all unique LLM connections used (project + sections, deduplicated)
  - Each configuration includes: id, name, model, base URL, endpoint type, timeout

**What is NOT Included**
- API keys: Excluded for security (never exported)
- Security-scoped bookmark data: Platform-specific, not portable
- File contents: Only metadata exported, not actual file data
  - Metadata includes: filename, extension, size, timestamps
  - Files appear as "inaccessible" after import until user re-links them via "Locate" button
- Generated content: Users regenerate after import
- Internal identifiers: Project, specification, section, and attachment IDs are not exported; fresh UUIDs generated on import
  - Exception: LLM configuration IDs are exported to maintain references between llmConnectionId fields and configurations

### Schema Versioning

**Version Tracking**
- Every export includes a schema version identifier
- Current schema version is embedded in each exported project
- Version format follows semantic versioning (e.g., "1.0.0")

**Compatibility**
- Schema version enables detection of older or newer export formats
- Applications can implement migration logic for version differences
- Unknown future versions can be detected and handled gracefully

### Project Status

**Status Values**
- Draft: Project in initial creation phase
- Active: Project actively being worked on
- Generating: Content generation in progress
- Completed: Project finished

### LLM Endpoint Types

**Supported Types**
- Chat Completions: Standard OpenAI chat completions endpoint
- Responses: OpenAI responses endpoint for structured outputs

## Error Handling

**Error Categories**
- Encoding failures: Issues converting data to JSON
- Decoding failures: Issues parsing JSON to objects
- Invalid JSON: Malformed JSON input
- Schema version mismatch: Incompatible export format versions
- Validation failures: Data integrity issues
- File operation failures: Issues reading/writing files

**Error Presentation**
- All errors provide human-readable descriptions
- Errors include specific details about the failure
- Errors are suitable for display in user interfaces

## Design Principles

- **Portability**: No platform-specific dependencies beyond Foundation
- **Security**: Sensitive data (API keys) explicitly and permanently excluded
- **Simplicity**: Straightforward value types with Codable conformance
- **Reusability**: Can be imported into other Swift projects as a dependency
- **Readability**: Pretty-printed JSON for human inspection
- **Multi-LLM Support**: Projects can use different LLM connections for content generation and section assistants

---

*This specification is maintained as functionality evolves and should remain language-agnostic.*
