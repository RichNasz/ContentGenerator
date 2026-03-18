# Functional Specifications

## Package Overview
**Package Name:** ChatCompletionsAgentGen
**Purpose:** Agent-based project content generation using tool-calling LLMs
**Consumers:** ContentGenerator macOS app

## Core Functionality

### Agent-Based Project Generation
- Provides a "Generate with Agent" workflow at the project level, separate from the existing single-turn `ProjectContentGenerationWindow`
- The agent calls read-only tools to inspect specification sections and the project system prompt before producing final content
- Four tools available to the agent:
  - **list_sections_tool**: Returns a JSON list of `{name, isEnabled}` objects for all sections
  - **read_section_tool**: Returns content, generation prompt, and usage prompt for a named section; records the read server-side
  - **read_system_prompt_tool**: Returns the project system prompt string
  - **get_unread_sections_tool**: Returns a JSON array of enabled section names not yet read via `read_section_tool`; returns `[]` when all enabled sections have been read
- **Section Completeness Enforcement**: The harness tracks which sections have been read server-side via `SectionReadTracker`. The agent queries `get_unread_sections_tool` after its initial reads and repeats reading until the tool returns `[]`, guaranteeing all enabled sections are read before final content is written. This shifts the completeness guarantee from probabilistic instruction-following to a deterministic environmental signal.
- **Timeout Respect**: Every internal LLM request in the tool-calling loop honours the `requestTimeoutSeconds` configured on the selected `LLMConnection`, matching the behaviour of the non-agent generation window

### Window Layout
- Three-column `HSplitView` window (1000×700 minimum, 1200×700 default)
- **Column 1** (Project Overview): Read-only display of system prompt and section names list
- **Column 2** (Agent Controls): LLM picker, editable instructions field, "Run Agent" button, tool call log
  - The instructions field always defaults to a generic task request: *"Please review the specification sections and generate comprehensive content for this project."*
  - The project system prompt is **not** used as the instructions default. It already appears in the LLM system message (via `buildSystemPrompt()`) as role/context. Reusing it as a user message would place the same text in two semantically different roles simultaneously (role description sent as a task request), which is wrong for models that treat system and user turns distinctly.
- **Column 3** (Generated Content): Scrollable, copyable, saveable generated output with same footer actions as the basic window
  - While the agent is running and no final content has been produced yet, Column 3 shows a live status string reflecting the current agent phase (e.g., "Thinking (iteration 1)…", "Calling read_section_tool…", "Tool read_section_tool finished. Waiting for model…")
  - Once final content is available it replaces the status text immediately

### Tool Call Log
- **While running**: An in-progress spinner row appears for the tool currently executing, showing the tool name and a "running…" label. It disappears and is replaced by a completed row (with duration) once the tool finishes.
- **After agent completes**: Log shows all tool calls with: tool name, arguments (truncated, expandable), result preview (truncated), duration in milliseconds

### Token Usage Display
- **During generation**: Live status text should include token usage when available from the DSL. Currently only the final API response provides usage data; a future DSL enhancement (adding `ChatResponse.Usage` to `ToolSessionEvent.modelResponse`) will enable per-iteration token counts.
- **On completion**: Always display a token usage summary showing prompt tokens, completion tokens, and total tokens from the final API response
- **Location**: Token usage summary displayed in Column 2 below the tool call log, visible after the agent completes
- **Empty state**: If the API response does not include usage data (some providers omit it), show "Token usage unavailable"

### Generated Content Actions
- Copy to Clipboard
- Save to File (as `.md`)
- Done (dismisses window)

## Data Requirements
- `AgentSection`: Plain `Sendable` value type carrying section name, content, prompts, and enabled state — no SwiftData dependency
- `AgentGenerationWindowState`: Observable class coordinating window data, populated by the app before opening the window

---
**Last Updated:** 2026-03-18 (token usage display: completion summary and future per-iteration tracking)
