# Functional Specifications

This document captures the "WHAT" of the LLMmanagement functionality in a language-agnostic manner. It describes what the system does, not how it's implemented.

## Overview

LLMmanagement is a library that provides connection management and configuration for Large Language Model (LLM) services.

## Core Functionality

### Connection Management

**Connection Entity**
- A connection represents a configured endpoint to an LLM service
- Each connection has a unique identifier that persists across sessions
- Connections have human-readable names for identification
- Connections track when they were created and last used

**Connection Configuration**
- Each connection specifies an OpenAI endpoint type (Chat Completions or Responses)
- Each connection has a base URL for the LLM service
- Connections may optionally specify a custom URL path (uses default for endpoint type if not provided)
- The full API URL is constructed by combining the base URL with the custom path or the endpoint type's default path
- Connections may include authentication credentials (API keys)
- Each connection specifies which model to use from the LLM service
- Connections have configurable request timeout values
- Timeout values are constrained to reasonable limits (60-600 seconds)
- Timeout values are displayed in minutes:seconds format (e.g., "2:30" for 150 seconds)

**OpenAI Endpoint Types**
- Chat Completions: Standard endpoint for conversational AI (`/v1/chat/completions`)
- Responses: Advanced endpoint with structured outputs and reasoning (`/v1/responses`)
- Chat Completions is the default endpoint type for new connections
- Users can override default paths with custom URL paths when needed

**Connection Validation**
- The system validates that URLs are properly formatted
- The system verifies that required configuration fields are populated
- API credentials are optional to support local/unauthenticated services
- A connection is considered "configured" when it has valid URL and model selection

**Connection Usage Tracking**
- The system records when each connection was last used
- Usage timestamps support analytics and connection management

**Connection Persistence**
- All connection configurations are automatically persisted
- Connections maintain their identity across application sessions
- Configuration changes are immediately saved

**Connection Updates**
- Existing connections can be updated while preserving their identity and timestamps
- Updates create a copy with the same ID and creation date, applying new configuration values

### Connection Lifecycle

**Creation**
- New connections can be created with minimal required information
- Default values are applied for optional configuration
- Unique identifiers are automatically assigned

**Modification**
- Existing connections can be updated while preserving their identity
- Changes to configuration maintain creation timestamp and usage history

**Validation**
- Connections can be checked for completeness and validity
- Invalid configurations are identified before use

### Contextual Help System

**Help Availability**
- Contextual help buttons are provided alongside every connection configuration field
- Help content is available for: connection name, base URL, custom URL path, endpoint type, API key, model selection, and request timeout

**Help Content Structure**
Each help topic provides:
- Title identifying the field
- Summary providing a brief explanation
- Detailed description explaining the field's purpose and behavior
- Examples showing typical values or usage patterns
- Tips offering best practices and common pitfalls to avoid

**Help Presentation**
- Help is displayed in a modal sheet when the help button is activated
- Help sheets show all available content sections (overview, details, examples, tips)
- A compact inline help variant is also available for space-constrained contexts

## User Interface Requirements

### Connection Management Interface

**Connection List View**
- Display all configured connections in an organized list
- Show connection status (configured/incomplete)
- Provide visual indicators for connection health and last usage
- Support filtering and searching connections by name and model
- Show an empty state view with a "Create Your First Connection" prompt when no connections exist
- Support swipe-to-delete with confirmation dialog for removing connections

**Connection Creation Interface**
- Guided form for creating new connections
- Real-time validation feedback with clear error messages
- Support for both authenticated and local service configurations
- Preview of connection settings before saving
- Contextual help buttons on every configuration field

**Connection Editing Interface**
- In-place editing of existing connection configurations
- Preservation of connection identity and history during updates
- Validation feedback during configuration changes
- Confirmation dialogs for destructive actions
- Contextual help buttons on every configuration field

**Connection Validation Feedback**
- Clear indication of configuration completeness
- Detailed error messages for invalid configurations
- Visual feedback for successful validation
- Guidance for resolving configuration issues
- Status indicators for connection availability

### User Experience Requirements

**Accessibility**
- Full VoiceOver support for all interface elements
- Keyboard navigation support
- Dynamic Type support for text scaling
- High contrast mode compatibility
- Motor accessibility considerations

**Error Handling and Recovery**
- Graceful handling of network connectivity issues
- Clear error messages with actionable guidance
- Recovery suggestions for common configuration problems
- Prevention of data loss during editing operations
- Offline capability for viewing existing connections

**Performance and Responsiveness**
- Responsive interface during connection validation
- Progressive loading for large connection lists
- Smooth animations and transitions
- Efficient memory usage for connection data
- Background processing for non-critical operations

## Design Principles

- **Flexibility**: Support both authenticated and local LLM services
- **Reliability**: Enforce reasonable timeout constraints and validation
- **Persistence**: Automatic saving of all configuration data
- **Usability**: Human-readable names and clear configuration requirements
- **Analytics**: Track usage patterns for connection management
- **Accessibility**: Universal access for all users regardless of abilities
- **Performance**: Responsive and efficient user experience
- **Discoverability**: Contextual help available for every configuration option

---

*This specification is maintained as functionality evolves and should remain language-agnostic.*
