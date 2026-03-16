# ContentGenerator Application Reference

This document provides a comprehensive reference of all functionality in the ContentGenerator application. It describes what features exist and their capabilities, intended for use as context when generating content with the LLM assistant.

---

## 1. Application Overview

**Application Name:** ContentGenerator

**Target Users:** creators of text based content such as product marketers, corporate marketers, corporate communications professionals, blog authors, and really anyone business professional creating text based content.

**Core Purpose:** AI-infused content generation application that leverages large language models to create, refine, and manage structured content.

### Design Philosophy

- **AI-First:** Every feature is designed around AI capabilities
- **AI-Always:** Continuous AI integration throughout all user workflows
- **Ease of use:** Written to run on macOS following Apple Human Interface Guidelines
- **Single Primary Window:** All non-AI assisted functionality is contained within one main window
- **Dedicated AI Assistance Windows:** Whenever the user is interacting with AI, that interaction is performed in a separate window. This helps the user understand when they are interacting with AI, and when they are not.
- **Project-Based:** User-defined projects with isolated data and functionality

---

## 1.5 Bundle Management

### Bundle System

ContentGenerator uses a `.cgspecs` bundle format to store all project data and settings. A bundle must be created or opened before any application functionality is available.

### First Launch / No Bundle Selected

- A welcome screen is displayed prompting the user to either create a new bundle or open an existing one
- No other application functionality is accessible until a bundle is selected

### Bundle Operations

- **Create New Bundle:** Creates a fresh `.cgspecs` bundle at a user-chosen location
- **Open Existing Bundle:** Opens a previously created bundle to resume work
- **Automatic Restoration:** The last-used bundle is remembered and automatically restored on relaunch

### Bundle Contents

- The SwiftData store containing all projects, settings, and LLM connections
- Project-related files organized within the bundle directory structure

---

## 2. Project Management

### Creating Projects

- **New Project Button:** Located in the sidebar Projects section header (plus icon)
- **Auto-Generated Names:** New projects receive intelligent names ("Project 1", "Project 2", etc.) that automatically avoid conflicts with existing project names
- **Immediate Availability:** Projects are ready for use immediately after creation

### Editing Projects

- **Inline Editing:** Project names can be edited directly in the sidebar interface
- **Project Properties:** Additional project properties (system prompt, LLM connection) editable in the main content area

### Deleting Projects

- **Swipe-to-Delete:** Swipe gesture on project rows (macOS)
- **Context Menu:** Right-click (macOS) reveals Delete option
- **Confirmation Required:** Destructive actions require user confirmation to prevent accidental deletion
- **Selection Handling:** If the selected project is deleted, selection is automatically cleared

### Project Organization

- **Sidebar List:** Projects displayed in sidebar sorted by modification time
- **Selection:** Clicking/tapping a project displays its content in the main area
- **Complete Isolation:** Each project maintains entirely separate data with no cross-project sharing

### Auto-Save System

- **Automatic Saving:** All changes automatically saved without user action
- **Debouncing:** Brief delay batches rapid changes to prevent excessive write operations
- **Save State Indicator:** Visual display of current save state:
  - **Saving:** Changes currently being written to storage
  - **Saved:** All changes successfully persisted
  - **Error:** Save operation failed (includes error details)
- **Timestamp Updates:** Project modification timestamps updated automatically on any content change

### State Persistence

- **Selected Project:** Remembers which project was selected between sessions
- **Expanded Sections:** Section expansion state persists across app restarts
- **Window State:** Application window position and size preserved

---

## 3. Content Specification System

### Specification Sections

Projects contain specification sections that define content requirements. Each section represents a distinct component of the content specification.

### Section Properties

Each specification section has the following properties:

- **Name:** Human-readable identifier for the section
- **Description:** Optional explanatory text for organizational clarity
- **Content:** The actual specification text for this section
- **Order Index:** Position in the section list (supports manual reordering)
- **Content Generation Prompt:** Instructions for AI-assisted content creation within the section
- **Content Usage Prompt:** Defines how the section content should be applied during project-level generation
- **Enabled/Disabled State:** Controls whether section is included in generation

### Section Management

- **Add Section:** Create new sections within a project
- **Edit Section:** Modify any section property
- **Reorder Sections:** Move sections up/down using dedicated controls
- **Delete Section:** Remove sections from the project
- **Toggle Section:** Enable or disable sections without deleting them

### Expandable Interface

- **Collapsed View:** Shows section name and enabled state
- **Expanded View:** Reveals full content, prompts, and configuration options

---

## 4. LLM Connection Management

### Global Connections

- **System-Wide:** LLM connections are configured globally and shared across all projects
- **Multiple Connections:** Support for configuring multiple LLM connections
- **Project Selection:** Each project can select which connection to use for generation

### Connection Configuration

Each LLM connection has the following settings:

- **Name:** Human-readable identifier for the connection
- **Base URL:** The LLM service endpoint (e.g., https://api.openai.com)
- **Custom URL Path:** Optional override for the API endpoint path
- **API Key:** Authentication credential (optional for local services)
- **Selected Model:** Which model to use (e.g., gpt-4, gpt-3.5-turbo, llama2)
- **Request Timeout:** How long to wait for responses (60-600 seconds)
- **Creation Timestamp:** When the connection was created
- **Last Used Timestamp:** When the connection was last used for generation

### OpenAI Endpoint Types

ContentGenerator supports two OpenAI-compatible API endpoint types:

- **Chat Completions:** Standard conversational endpoint (`/v1/chat/completions`)
  - Default for new connections
  - Supports all standard Chat Completions parameters
- **Responses:** Advanced endpoint with structured outputs (`/v1/responses`)
  - For applications requiring specific output formats

### Tested Providers

- **OpenAI:** Direct OpenAI API access
- **vLLM hosted model:** vLLM supports OpenAI-compatible endpoints to hosted models
- **Gemini:** Google Gemini provides access to OpenAI-compatible endpoints to hosted models
- **Grok:** xAI Grok provides access to OpenAI-compatible endpoints to hosted models
- **Local LLMs:** Self-hosted models (Ollama, LM Studio, etc.)
  - API key not required for local services, but is always available to provide, and is always securely stored
  - Custom base URLs supported

### Connection Validation

- **Configuration Check:** Validates URL format and required fields
- **Configured State:** A connection is "configured" when it has valid URL and model selection

### Connection Status

- **Usage Tracking:** Record when connections are used for analytics

---

## 5. Content Generation

### Generation Levels

- **Project-Level Generation:** Generates content based on all enabled specification sections combined
- **Section-Level Generation:** Generates or refines content for individual sections independently

### Generation Windows

- **Dedicated Interface:** Separate windows for content generation workflow
- **Real-Time Preview:** See generated content as it streams from the LLM
- **Iterative Refinement:** Regenerate with adjusted prompts until satisfactory

### Streaming Display

- **Character-by-Character:** Generated content appears in real-time as received
- **Progress Indication:** Visual feedback during active generation
- **Connection Status:** Real-time display of LLM connection state

### Generation Modes

- **Replace Mode:** New generation completely replaces existing section content
- **Append Mode:** New generation is added to the end of existing content
- **Mode Selection:** Choose before initiating generation

### Cancellation and Error Handling

- **Cancel Support:** Users can stop in-progress generation at any time
- **Error Recovery:** Graceful handling of generation failures
- **User-Friendly Messages:** Clear error descriptions for troubleshooting

### LLM Connection Selection

- **Dynamic Selection:** Choose from available connections at generation time
- **Connection Display:** Shows connection name, model, and availability
- **Fallback Behavior:** Prompts user to configure connections if none available
- **Per-Generation Choice:** Switch connections between generation attempts

---

## 6. Reference Files and Attachments

### Attaching Files

- **Drag-and-Drop:** Add files by dragging onto the attachment area
- **Supported Types:** Text-based files (txt, md, rtf)
- **Purpose:** Provide additional context for LLM content generation

### File Metadata

For each attached file, the system tracks:

- **Original Filename:** The file's name when attached
- **File Extension:** The file type
- **File Size:** Size of the file in bytes
- **Timestamps:** When attached and last modified

### Selective Inclusion

- **Choose Files:** Select which attached files to include in generation context
- **File Preview:** View file contents before including in generation
- **Accessibility Validation:** Only accessible files can be selected
- **Token Awareness:** Estimated token usage displayed for selected files

### File Management

- **View Files:** See all attached files in the project
- **Remove Files:** Detach files that are no longer needed
- **Re-Attach Files:** Add files back or update file references

### Security and Accessibility

- **Security-Scoped Bookmarks:** Files accessed via macOS sandbox-compliant bookmarks
- **Accessibility Status:** Files may become inaccessible (moved, deleted, permissions changed)
- **Inaccessible Indicator:** Warning icon shown for inaccessible files
- **Locate Button:** Re-link inaccessible files by browsing to their new location
- **Accessibility Requirement:** Inaccessible files cannot be selected for content generation

---

## 7. Prompt Management

### System Prompt (Project-Level)

- **Developer/System Role:** Optional project-level prompt providing persistent LLM context
- **Applied to All Generations:** System prompt included in every generation request for the project

### Section Prompts

- **Content Generation Prompt:** Instructions for how AI should create content for this section
- **Content Usage Prompt:** Defines how section content should be applied during project-level generation

### Prompt Editing

- **In-Window Editing:** Edit prompts directly in the generation window
- **Immediate Feedback:** See how prompt changes affect generation

### Prompt Persistence

- **Save to Section:** Edited prompts can be saved back to section configuration
- **Undo/Revert:** Revert prompt changes to previously saved state
- **Prompt Preview:** View the complete prompt before generation, including system context

### Prompt Construction

The final prompt sent to the LLM is constructed from:

1. System prompt (project-level)
2. Enabled specification section contents
3. Reference file contents (selected files)
4. Section-specific generation or usage prompts

---

## 8. Export and Sharing

### Markdown Export

- **Full Project Export:** Export entire project specification as formatted Markdown
- **Section Organization:** Markdown structure mirrors project section hierarchy
- **Heading Levels:** Proper heading hierarchy (H1, H2, etc.) based on section order
- **System Prompt Included:** Project system prompt exported when present
- **One-Click Export:** Single action to export
- **File Save Dialog:** Standard file picker for choosing location and filename

### Clipboard Operations

- **Copy Project Content:** Full project as formatted Markdown to clipboard
- **Copy Generated Content:** AI-generated content from generation window
- **Copy Section Content:** Individual section content
- **Universal Format:** Plain text compatible with all applications

### JSON Export

- **Portable Format:** Projects exported to JSON for backup or sharing
- **Schema Versioning:** Each export includes schema version for compatibility

**What IS Exported:**

- Project metadata (name, description, status, timestamps)
- Project system prompt
- All specification sections (name, content, prompts, order, enabled state)
- LLM connection references (both project-level and section-level)
- LLM configurations (deduplicated array of all referenced connections)
- File attachment metadata (filename, path, extension, size)

**What is NOT Exported:**

- **API Keys:** Never exported for security reasons
- **File Contents:** Only metadata exported, not actual file data
- **Generated Content:** Users regenerate after import
- **Security Bookmarks:** Platform-specific, not portable
- **Internal IDs:** Fresh UUIDs generated on import (exception: LLM config IDs preserved for reference mapping)

---

## 9. Project Import

### Import Workflow

- **JSON Import:** Import projects from previously exported JSON files
- **New Project Creation:** Imported projects created as new entries with fresh UUIDs
- **Validation:** Import data validated before creating project

### Name Conflict Handling

When importing a project with a name matching an existing project:

- **Conflict Detection:** Case-insensitive matching against existing project names
- **User Confirmation:** Dialog asks user whether to proceed
- **Timestamp Renaming:** If proceeding, imported name appended with date/time (e.g., "Project Name (2026-01-05 14:30:45)")
- **Cancel Option:** User can cancel import without creating duplicate

### LLM Connection Import

When importing projects with LLM configurations:

- **No Match:** New LLM connection created (user must provide API key)
- **Name Match Found:** User presented with conflict resolution options:
  - **Skip:** Use existing connection without changes
  - **Overwrite:** Update existing with imported values (API key preserved)
  - **Create New:** Create new connection with "(Imported)" suffix
- **Multiple Conflicts:** Each LLM configuration resolved independently
- **Side-by-Side Comparison:** UI shows differences between existing and imported configurations

### File Attachment Import

- **Metadata Preserved:** Original filename, size, extension, timestamps imported
- **Inaccessible by Default:** Imported attachments have no security bookmark
- **Visual Indication:** Warning icon and "Locate" button shown
- **Locate to Re-link:** Browse for file to re-establish access
- **File Validation:** Re-linked files must match supported types and size limits

---

## 10. Application Settings

### Auto-Save Settings

- **Auto-Save Toggle:** Enable or disable automatic saving of changes

### Appearance Settings

- **Theme Selection:** Choose application appearance:
  - **Light:** Always use light appearance
  - **Dark:** Always use dark appearance
  - **System:** Follow system appearance setting

### Data Management

- **Backup Location:** User-configurable path for data backup storage
- **Last Backup Date:** Tracks when last backup was performed

### Settings Metadata

- **Creation Timestamp:** When settings were initialized
- **Modification Timestamp:** When settings were last changed

---

## 11. User Interface

### Main Window Structure

- **NavigationSplitView:** Primary layout with sidebar and detail area
- **Sidebar:** Contains projects list and settings sections
- **Detail Area:** Displays selected project or settings content

### Sidebar Organization

**Projects Section:**

- Located at top of sidebar
- Apple HIG-compliant section header
- "New Project" button (plus icon) in header
- Projects listed by modification time
- Swipe and context menu actions available

**Settings Section:**

- Located at bottom of sidebar
- Categories include:
  - LLM Connections
  - Application Settings

### Project Detail View

When a project is selected, the detail area shows:

- **Project Properties Section:** Name, system prompt configuration
- **Reference Files Section:** Attached files and management
- **Content Specification Section:** All specification sections
- **Content Generation Settings:** LLM connection selection
- **Action Buttons:** Generate Content, Export, etc.

### Expandable Sections

- **Collapsed State:** Shows minimal information (name, status)
- **Expanded State:** Reveals full content and configuration options
- **Persistent State:** Expansion state remembered across sessions

### Platform-Specific Behaviors

**macOS:**

- Desktop-optimized interface
- Native window controls
- Keyboard shortcuts following macOS conventions
- Menu bar integration (File, Edit, View, etc.)
- Right-click context menus

---

## 12. Apple Human Interface Guidelines Compliance

### List Management

- **Swipe-to-Delete:** Standard deletion gesture on list items
- **Context Menus:** Right-click (macOS)
- **Confirmation Dialogs:** Required for destructive actions

### Visual Design

- **Section Headers:** Platform-appropriate typography (mixed case, automatic adaptation)
- **Button Placement:** Action buttons in section headers following standard patterns
- **Visual Hierarchy:** Consistent spacing, colors, typography
- **Touch Targets:** Appropriately sized for accessibility and platform

### Accessibility

- **VoiceOver:** Full support for screen reader navigation
- **Keyboard Navigation:** All elements accessible via keyboard
- **Dynamic Type:** Text scales with system settings
- **High Contrast:** Compatible with increased contrast modes
- **Focus Management:** Proper focus handling in split view interfaces

---

## Project Status Values

Projects can have the following status values:

- **Draft:** Project in initial creation phase
- **Active:** Project actively being worked on
- **Generating:** Content generation in progress
- **Completed:** Project finished

---

## OpenAI-Compatible API Integration

### API Communication

- Uses OpenAI-compatible API format for LLM communication
- Supports two endpoint types:
  - **Chat Completions** (`/v1/chat/completions`) -- default for new connections
  - **Responses** (`/v1/responses`) -- for structured outputs and reasoning
- Full API URL constructed from base URL + custom path or endpoint default path

### Tested Providers

- **OpenAI:** Direct OpenAI API access
- **vLLM:** OpenAI-compatible endpoints for hosted models
- **Gemini:** Google Gemini OpenAI-compatible endpoints
- **Grok:** xAI Grok OpenAI-compatible endpoints
- **Local LLMs:** Self-hosted models (Ollama, LM Studio, etc.)
  - API key not required for local services

### Error Handling

- Comprehensive error handling for API failures
- Network connectivity handling
- User-friendly error messages with recovery suggestions

---

*This reference document describes all functionality in ContentGenerator as of the current version. It is intended for use as context when generating content with the LLM assistant.*
