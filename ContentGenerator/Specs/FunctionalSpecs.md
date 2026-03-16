# Functional Specifications

## Project Overview
**Application Name:** ContentGenerator
**Target Users:** Product marketing professionals
**Core Purpose:** AI-infused content generation application

## Application Characteristics
- **AI-First:** Every feature leverages AI capabilities
- **AI-Always:** Continuous AI integration throughout user workflows
- **macOS Application:** Native macOS desktop application
- **Single Window Application:** All functionality contained within a single main window
- **Project-Based Organization:** User-defined projects with isolated data and functionality

## Core Functionality

### 1. Bundle Management
- **Bundle System:** The application uses a `.cgspecs` bundle format to store all project data and settings
- **Bundle Required:** Users must create or open a bundle before accessing any application functionality
- **Welcome Screen:** On first launch or when no bundle is selected, a welcome view prompts users to create a new bundle or open an existing one
- **Bundle Contents:** Each bundle contains the data store and project files
- **Persistent Selection:** The selected bundle is remembered across application sessions, so users are returned to their previous bundle on relaunch
- **Create New Bundle:** Users can create a fresh bundle at a location of their choosing
- **Open Existing Bundle:** Users can open a previously created bundle to resume work

### 2. Project Management
- **Project Creation:** Users can create new projects with intelligent auto-generated names ("Project 1", "Project 2", etc.) that avoid conflicts
- **Project Customization:** Project names can be edited after creation through inline editing interface
- **Project Deletion:** Users can delete projects through multiple Apple HIG-compliant methods:
  - Swipe-to-delete gestures on project rows
  - Context menus (right-click) with Delete option
  - Confirmation dialogs prevent accidental deletion
  - Selection automatically cleared when selected project is deleted
- **Project Selection:** Users select projects from sidebar to access project-specific functionality
- **Project Isolation:** Each project maintains completely separate data with no cross-project sharing
- **Project Organization:** Projects are listed in sidebar for easy access and management

### 2.5 Auto-Save and State Management
- **Automatic Saving:** Changes to projects automatically saved with debouncing to prevent excessive writes
- **Save Debouncing:** Brief delay before auto-save triggers to batch rapid changes
- **Save State Indicator:** Visual indicator displays current save state:
  - Saving: Changes being written to storage
  - Saved: All changes successfully persisted
  - Error: Save operation failed with error details
- **Timestamp Updates:** Modified timestamps automatically updated on any content changes
- **State Persistence:** Application state (selected project, expanded sections) persists across sessions
- **Inline Property Editing:** Project properties editable inline with immediate auto-save

### 3. Content Generation Framework

#### Specification Sections
- **Section Structure:** Projects contain specification sections that define content requirements
- **Section Properties:**
  - Name and optional description for organizational clarity
  - Content field for the actual specification text
  - Order index for manual section arrangement
  - Content generation prompt for AI-assisted content creation within the section
  - Content usage prompt defining how the section content should be applied during project generation
  - Enabled/disabled state to include or exclude from generation
- **Section Management:** Add, edit, reorder, and delete sections within a project
- **Section Toggling:** Enable or disable individual sections without deleting them
- **Drag-and-Drop Reordering:** Sections can be reordered by dragging them to a new position in the list, in addition to move up/down buttons

#### Content Generation Workflows
- **Project-Level Generation:** Generate content based on all enabled specification sections combined
- **Section-Level Generation:** Generate or refine content for individual sections independently
- **Generation Windows:** Dedicated windows for content generation workflow with real-time preview
- **Three-Column Layout:** Both section and project generation windows use a three-column layout: (1) current content/overview, (2) LLM controls and prompt editing, (3) generated content display
- **Iterative Refinement:** Regenerate content with adjusted prompts until satisfactory

#### Streaming Content Generation
- **Real-Time Display:** Generated content streams to UI character-by-character as received from LLM
- **Progress Indication:** Visual feedback during active generation process
- **Cancellation Support:** Users can cancel in-progress generation at any time
- **Error Recovery:** Graceful handling of generation failures with user-friendly error messages

#### Content Generation Modes
- **Replace Mode:** New generation replaces existing section content entirely
- **Append Mode:** New generation appends to existing section content
- **Mode Selection:** Users choose generation mode before initiating generation

#### Prompt Management
- **Prompt Editing:** Edit generation prompts directly in generation window
- **Prompt Persistence:** Save edited prompts back to section configuration
- **Undo/Revert:** Revert prompt changes to previously saved state
- **Prompt Preview:** View full prompt before generation including system context
- **Prompt Export:** Users can copy the complete assembled prompt to clipboard or save it to a `.md` file for inspection and debugging

#### XML-Wrapped Prompt Format
- **Structured Prompts:** Specification sections are wrapped in camelCase XML tags when assembled into prompts for the LLM
- **Multiple Output Formats:** The prompt builder provides multiple output formats: minimal XML, LLM prompt, user message, and export

#### Reference File Selection
- **Selective Inclusion:** Choose which attached files to include in generation context
- **File Preview:** View file contents before including in generation
- **Accessibility Validation:** Only accessible files can be selected for generation
- **Context Size Awareness:** Display estimated token usage for selected files

#### Generated Content Management
- **Content Storage:** Generated text stored with project association
- **Metadata Capture:** LLM connection ID and timestamps preserved
- **Latest Content Access:** Quick access to most recent generation result
- **Save to File:** Users can save generated content to a `.md` file from the project generation window
- **Copy to Clipboard:** Users can copy generated content to clipboard from the generation window

#### File Attachments
- **Reference Files:** Attach text files to projects to provide additional context for LLM generation
- **Drag-and-Drop:** Add files by dragging onto the attachment area in the UI
- **File Picker:** Users can click an "Add Reference Content" button to open a file picker for selecting attachments
- **File Type Restrictions:** Only `.txt`, `.md`, and `.rtf` files are accepted
- **File Size Limit:** Attachments are limited to 10MB per file
- **Metadata Tracking:** Track original filename, file size, file extension, and timestamps
- **Context Inclusion:** Attached file contents automatically included in generation prompts
- **File Management:** View, remove, and re-attach files as needed
- **Open in Default Application:** Attached files can be opened in their default application
- **Persistent File Access:** File access is maintained across application sessions despite sandboxing
- **Accessibility Requirement:** Inaccessible files cannot be selected for content generation; users must first re-link them using the "Locate" button

### 4. Text Editing Features
- **Spell Checking:** Text editors and text fields provide macOS-native spell checking and grammar checking
- **Plain Text Enforcement:** Paste operations intercept and enforce plain text to maintain consistency
- **Expandable Text Editors:** Text fields can be expanded into a modal sheet for editing longer content, with character count displayed in expanded mode

### 5. System-Wide Settings
- **Global Configuration:** Settings that affect application behavior across all projects
- **LLM Management:** Global LLM connection configuration shared across all projects
- **Appearance Settings:** UI theme selection (Light, Dark, System)

#### Application Settings Details
- **Auto-Save Toggle:** Enable or disable automatic saving of changes
- **Appearance Theme:** Select application theme:
  - Light: Always use light appearance
  - Dark: Always use dark appearance
  - System: Follow system appearance setting
- **Data Backup Location:** User-configurable path for data backup storage
- **Last Backup Date:** Track when last backup was performed
- **Settings Timestamps:** Track creation and modification dates for settings

### 6. LLM Connection Management
- **Global LLM Connections:** System-wide LLM connections accessible from all projects
- **Connection Configuration:** Setup and management of LLM service connections
- **OpenAI Endpoint Types:** Connections specify an endpoint type:
  - Chat Completions (`/v1/chat/completions`) -- default for new connections
  - Responses (`/v1/responses`) -- for structured outputs and reasoning
- **Full URL Construction:** The system combines the base URL with a custom URL path (or the endpoint type's default path) to construct the full API URL
- **Dynamic Selection:** Projects can select from available global LLM connections during content generation
- **Shared Credentials:** Secure storage of API keys and authentication information (API keys optional for local services)

### 7. AI Integration Points

#### LLM Connection Selection
- **Dynamic Selection:** Projects select from globally configured LLM connections at generation time
- **Connection Display:** Show connection name, model, and availability status in generation UI
- **Fallback Behavior:** Prompt user to configure connections if none available
- **Per-Generation Choice:** Users can switch connections between generation attempts

#### Section-Level AI Assistants
- **Per-Section Configuration:** Each specification section can have its own LLM assistant connection
- **Independent Generation:** Section assistants operate independently from project-level generation
- **Assistant Selection:** Users select from global LLM connections for each section's assistant
- **Expandable Interface:** Section details expand to reveal assistant configuration and content
- **Section Reordering:** Move sections up/down with dedicated controls or drag-and-drop

#### Prompt Construction
- **System Prompt:** Optional project-level system prompt provides persistent LLM context
- **Specification Content:** Enabled sections formatted as XML-wrapped structured content in prompts
- **File Attachments:** Reference file contents automatically included in prompt context
- **Generation Prompts:** Section-specific generation prompts guide AI content creation
- **Usage Prompts:** Section usage prompts inform how content should be applied

### 8. Export and Sharing

#### Markdown Export
- **Full Project Export:** Export entire project specification as formatted Markdown document
- **Section Organization:** Markdown structure mirrors project section hierarchy with proper headings
- **System Prompt Inclusion:** Project system prompt included in export when present
- **One-Click Export:** Single action to export project as Markdown file
- **File Save Dialog:** Standard file picker for choosing export location and filename

#### Clipboard Operations
- **Copy Project Content:** Copy formatted project content to system clipboard as Markdown
- **Copy Generated Content:** Copy AI-generated content to clipboard from generation window
- **Copy Section Content:** Copy individual section content to clipboard
- **Universal Format:** Content copied in plain text format compatible with all applications

#### Project Export
- **JSON Export:** Projects can be exported to a portable JSON format for backup or sharing with other applications
- **Export Contents:** Exports include project metadata, specification sections, system prompts, and LLM connection references
- **Multiple LLM Connections:** Projects can reference multiple LLM connections (project-level for content generation, section-level for assistants); all unique connections are exported as a deduplicated array
- **Generated Content Not Exported:** Generated content is excluded; users regenerate content after import
- **File Attachment Metadata:** File paths are captured for reference, but actual file contents are not embedded
- **Security:** API keys are never included in exports for security reasons
- **Schema Versioning:** Exports include a schema version for forward compatibility

#### Project Import
- **JSON Import:** Projects can be imported from previously exported JSON files
- **New Project Creation:** Imported projects are created as new entries (new UUIDs generated)
- **File Re-attachment Required:** Users must manually re-attach files after import (paths are informational only)
- **LLM Connection Handling:** Imported LLM configurations are matched against existing connections or created as new
- **Content Regeneration Required:** Users must regenerate content after import as generated content is not exported

#### Project Name Conflict Handling
When importing a project with a name that matches an existing project:
- **Conflict Detection:** Case-insensitive name matching against existing projects
- **User Confirmation:** Confirmation dialog presented asking user to proceed
- **Timestamp Renaming:** If user proceeds, imported project name appended with date/time (e.g., "Project Name (2026-01-05 14:30:45)")
- **Cancel Option:** User can cancel import without creating duplicate

#### LLM Connection Import Behavior
When importing a project with LLM configurations:
- **No Match:** New LLM connection created (user must provide API key)
- **Name Match Found:** User presented with conflict resolution options:
  - Skip: Use existing connection without changes
  - Overwrite: Update existing connection with imported values (API key preserved)
  - Create New: Create new connection with "(Imported)" suffix
- **Multiple Conflicts:** Each LLM configuration with a name conflict is resolved independently
- **Side-by-Side Comparison:** UI shows differences between existing and importing configurations

#### File Attachment Import
When importing a project with file attachments:
- **Metadata Preserved:** Original filename, file size, extension, and timestamps are imported
- **Inaccessible by Default:** Imported attachments are marked as inaccessible (no security bookmark)
- **Visual Indication:** Inaccessible files show warning icon and "Locate" button instead of "Open"
- **Locate to Re-link:** Users can use the "Locate" button to browse for the file and re-establish access
- **File Validation:** When re-linking, the file must match supported types (txt, md, rtf) and size limits

## User Experience Requirements

### Application Architecture
- **Main Window:** Single window containing all application functionality
  - Split-view interface with sidebar and main content area
  - Sidebar contains projects section and settings section
  - Main content area displays selected project interface or settings
  - Persistent window state and project selection across app sessions

### Sidebar Organization
- **Projects Section:**
  - List of user-created projects at top of sidebar with Apple HIG-compliant section header formatting
  - "New Project" button in section header (plus icon) following Apple HIG patterns
  - Project selection determines main content area display
  - Each project maintains isolated data and functionality
  - Project deletion available through swipe-to-delete and context menus
  - Consistent typography and spacing following platform conventions

- **Settings Section:**
  - Standard section at bottom of sidebar
  - System-wide settings accessible from any project context
  - Categories include: LLM Connections, Application Settings

### Navigation Behavior
- **Project Selection:** Selecting a project shows project-specific content and tools
- **Settings Selection:** Selecting a settings category shows system-wide configuration

### Platform Behaviors
- **macOS:** Desktop-optimized interface with full feature set
  - Native macOS window controls and behaviors
  - Keyboard shortcuts following macOS conventions
  - Menu bar integration for standard actions (File, Edit, View, etc.)

### Navigation Patterns
- **Sidebar Navigation:** Primary method for accessing projects and settings
- **Project Context:** Selected project determines available functionality and data
- **Settings Access:** System-wide settings accessible regardless of selected project
- **State Persistence:** Remember selected project and settings expanded state

### Apple Human Interface Guidelines (HIG) Compliance
- **List Management:** Standard deletion patterns with swipe-to-delete and context menus
- **Confirmation Dialogs:** Destructive actions require user confirmation with clear warnings
- **Section Headers:** Platform-appropriate typography and formatting (mixed case, automatic platform adaptation)
- **Button Placement:** Action buttons in section headers following standard patterns
- **Visual Hierarchy:** Consistent spacing, colors, and typography throughout interface

### Accessibility
- Full support for VoiceOver and accessibility features
- Keyboard navigation support for all interface elements
- High contrast and dynamic type support
- Focus management for split view interfaces

## Data Requirements

### Project Data Isolation
- **Unified Data Storage:** All application data stored in a unified data store with project-level isolation
- **No Cross-Project Access:** Projects cannot access or share data with other projects
- **Independent Lifecycle:** Projects can be created, modified, or deleted independently
- **Scalable Storage:** Support for multiple projects without performance degradation

### System-Wide Settings
- **Global Configuration:** Settings stored with global scope, separate from project data
- **LLM Connection Data:** Global LLM connections and credentials stored securely with application-wide access
- **Persistent Preferences:** Settings persist across app sessions and project changes
- **Default Values:** Sensible defaults for new installations and project creation

### Storage Architecture
- **Local Data Persistence:** All data stored locally within the selected bundle
- **Data Portability:** Projects can be exported/imported independently

### Security
- **Secure API Communication:** Encrypted communication with AI services
- **Project Privacy:** Each project's data remains isolated and secure

## Performance Requirements
- Responsive UI with smooth animations
- Fast AI response times
- Efficient memory usage

---

**Note:** This specification will be updated as functionality is developed. Each new feature should be documented here in language-agnostic terms focusing on WHAT the feature does, not HOW it's implemented.
