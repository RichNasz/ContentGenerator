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
- Project-related files (including file attachments) organized within the bundle directory structure

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
- **Bundle Cleanup:** Each deleted project's `projects/<uuid>/` bundle directory is automatically removed from disk after the database deletion is committed, preventing orphaned directories from accumulating

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
- **Reorder Sections:** Move sections up/down using dedicated controls, or drag sections to a new position
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
- **Responses:** Advanced endpoint with structured outputs and reasoning (`/v1/responses`)

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
- **Window Layouts:**
  - `SectionContentGenerationWindow` uses a three-column layout: (1) current section content read-only, (2) LLM controls and prompt editing, (3) generated content display
  - `ProjectContentGenerationWindow` uses a two-column layout: (1) LLM controls, (2) generated content display

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

### LLM Connection Selection in Generation Windows

- **Grouped Picker:** LLM connections are presented in a grouped dropdown. Standard generation windows show two sections — "Chat Completions" and "Responses" — containing only connections of that endpoint type
- **Locality Icon:** Each connection row shows an icon indicating where the model runs: a house icon for local connections (localhost, 127.0.0.1, etc.) and a cloud icon for remote connections
- **Per-Generation Choice:** Switch connections between generation attempts
- **Fallback Behavior:** Prompts user to configure connections if none available

### Prompt Management

- **In-Window Editing:** Edit prompts directly in the generation window
- **Prompt Persistence:** Save edited prompts back to section configuration
- **Undo/Revert:** Revert prompt changes to previously saved state
- **Prompt Preview:** View the complete prompt before generation, including system context
- **Prompt Export:** Copy the assembled prompt to clipboard or save it as a `.md` file

---

## 5.5 Agent-Based Content Generation

### Overview

In addition to standard streaming generation, ContentGenerator provides an agent-based generation window (`ProjectAgentGenerationWindow`) that uses a tool-calling LLM to autonomously inspect specification sections before writing final content. The agent reads tools from the application and uses them iteratively until it has gathered all necessary context.

### Inference Backends

The agent window supports two inference backends, selectable from a unified picker:

- **Apple Intelligence (on-device):** Uses the Foundation Models framework (`LanguageModelSession`) directly on-device. Available only when the on-device model is present on the system. Uses non-streaming inference with a 4,096 token context window; the model reads section content incrementally via tools.
- **Open Responses (cloud/local):** Uses an OpenAI-compatible Responses endpoint via the `SwiftOpenResponsesDSL` package. Supports streaming execution, conversation continuity across tool-calling iterations, and optional extended thinking (reasoning) models.

Only connections with the Responses endpoint type are shown in the agent picker. Connections with local base URLs are grouped under "On-Device" alongside Apple Intelligence; remote connections appear under "Cloud Connections".

### Agent Tools

The agent has access to four tools to inspect project content:

| Tool | Purpose |
|------|---------|
| List sections | Returns the list of all sections with their enabled state |
| Read section | Returns content, generation prompt, and usage prompt for a named section |
| Read system prompt | Returns the project system prompt |
| Get unread sections | Returns enabled sections not yet read; returns empty when all have been read |

The agent queries unread sections after initial reads and repeats until all enabled sections have been reviewed.

### Activity Log

All agent events are displayed in a single chronological activity log (Column 2):

- **Status updates:** Iteration status, tool invocation status
- **Thinking summaries:** Deduplicated reasoning summaries from extended thinking models (collapsed by default, expandable)
- **Thinking blocks:** Full raw reasoning content (collapsed by default, expandable with word count)
- **Tool calls in progress:** Spinner indicating a tool is executing
- **Tool calls completed:** Expandable arguments, result preview (truncated at 400 characters), and duration in milliseconds
- **Token usage:** Cumulative input, output, and total token counts after each iteration; cached input and reasoning output shown when non-zero (Open Responses only)
- **Completion and failure:** Final status entry

The log auto-scrolls to the bottom as new entries arrive.

### Section and Tool Read Tracking

- **Section Read Counts:** A badge on each section row in Column 1 shows how many times the agent read that section during the current run
- **Tool Call Counts:** A badge on each tool name shows how many times the tool was called

### Reasoning Effort

For cloud/local Open Responses connections, a Reasoning Effort picker allows selecting None, Low, Medium (default), High, or xHigh to control extended thinking depth.

### Instruments Telemetry (Opt-In)

For cloud/local Open Responses connections, an opt-in Instruments telemetry toggle captures detailed profiling data:

- Per-run, per-iteration, and per-tool-call timing intervals
- Streaming content delta events
- Token usage per iteration
- Full prompt capture (system prompt + user message) written to a temp file
- Complete wire-format HTTP POST body (including tool schemas, reasoning effort, `previous_response_id`) written to a temp file per LLM iteration

The telemetry preference persists across sessions via UserDefaults.

### Generated Content Actions

- **Copy to Clipboard:** Copy the generated content to the system clipboard
- **Save to File:** Save generated content as a `.md` file (default filename: `<projectName>_agent_generated.md`)
- **Done:** Dismiss the agent window

---

## 6. Reference Files and Attachments

### Attaching Files

- **File Picker:** Click the "Add Reference Content" button to open a system file picker
- **Drag-and-Drop:** Add files by dragging onto the attachment area in the project view
- **Supported Types:** Text-based files only: `.txt`, `.md`, and `.rtf`
- **File Size Limit:** 10 MB per file
- **Purpose:** Provide additional context for LLM content generation

### Bundle Storage

When a file is attached, it is copied into the `.cgspecs` bundle at `projects/<uuid>/attachments/<filename>`. The bundle's single security-scoped bookmark covers all files inside it, eliminating the need for per-file bookmarks. Files remain accessible across application sessions without any additional user interaction.

### File Metadata

For each attached file, the system tracks:

- **Original Filename:** The file's name when attached
- **File Extension:** The file type
- **File Size:** Size of the file in bytes
- **Timestamps:** When attached and last modified

### Duplicate File Handling

If the user tries to attach a file whose name already matches an existing attachment (via either the file picker or drag-and-drop), a confirmation dialog is presented:

- **Title:** "Replace `<filename>`?"
- **Message:** "A file named `<filename>` is already attached to this project. Do you want to replace it with the selected file? This cannot be undone."
- **Replace (destructive):** Overwrites the bundle copy with the new file and updates the existing attachment record in-place (same UUID, updated file size and timestamp)
- **Keep Existing (cancel):** Dismisses the dialog with no change
- Multiple simultaneous duplicates (e.g., multi-file picker with two conflicting names) are queued and each dialog is shown in sequence

### Selective Inclusion

- **Choose Files:** Select which attached files to include in generation context
- **File Preview:** View file contents before including in generation
- **Accessibility Validation:** Only accessible files can be selected
- **Token Awareness:** Estimated token usage displayed for selected files

### File Management

- **View Files:** See all attached files in the project
- **Remove Files:** Detach files that are no longer needed; the bundle copy is automatically deleted
- **Replace Files:** Replace an existing attachment with a new version; the bundle copy is overwritten in-place and the attachment record (UUID, timestamps) is preserved
- **Open in Default Application:** Attached files can be opened in their default application

### Legacy Attachments and the Locate Button

Attachments created before bundle-based storage (pre-bundle era) may have stored a security-scoped bookmark instead of a bundle copy. These appear with a warning icon and a "Locate" button instead of "Open". Using "Locate" browses for the file, copies it into the bundle, and re-establishes permanent access. After locating, the file behaves identically to a normally attached file.

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
2. Enabled specification section contents (wrapped in camelCase XML tags)
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
- LLM configurations (deduplicated array of all referenced connections, without API keys)
- File attachment metadata (filename, extension, size, timestamps)
- File attachment contents: base64-encoded raw bytes for files stored in the bundle and accessible at export time; files that cannot be read export with no content field

**What is NOT Exported:**

- **API Keys:** Never exported for security reasons
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
- **Content Restored Automatically:** If the export contains embedded file contents (base64), files are written into the new bundle's `projects/<uuid>/attachments/` directory and are immediately accessible — no "Locate" step required
- **Legacy Exports (No Embedded Content):** Attachments from older exports that do not include file contents are marked inaccessible and show a warning icon and "Locate" button instead of "Open"
- **Locate to Re-link:** For inaccessible attachments, users can use the "Locate" button to browse for the file and copy it into the bundle
- **File Validation:** Files re-linked via "Locate" must match supported types (.txt, .md, .rtf) and the 10 MB size limit

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
- **Action Buttons:** Generate Content, Generate with Agent, Export, etc.

### Expandable Sections

- **Collapsed State:** Shows minimal information (name, status)
- **Expanded State:** Reveals full content and configuration options
- **Persistent State:** Expansion state remembered across sessions

### Text Editing Features

- **Spell Checking:** Text editors provide macOS-native spell checking and grammar checking
- **Plain Text Enforcement:** Paste operations intercept and enforce plain text to maintain consistency
- **Expandable Text Editors:** Text fields can be expanded into a modal sheet for editing longer content, with character count displayed in expanded mode

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
