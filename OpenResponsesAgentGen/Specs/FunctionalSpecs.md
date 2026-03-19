# Functional Specifications

## Package Overview
**Package Name:** OpenResponsesAgentGen
**Purpose:** Agent-based project content generation using the Open Responses API with tool-calling LLMs
**Consumers:** ContentGenerator macOS app

## Core Functionality

### Agent-Based Project Generation
- Provides a "Generate with Agent" workflow at the project level using the Open Responses API
- The agent calls read-only tools to inspect specification sections and the project system prompt before producing final content
- Four tools available to the agent:
  - **list_sections_tool**: Returns a JSON list of `{name, isEnabled}` objects for all sections
  - **read_section_tool**: Returns content, generation prompt, and usage prompt for a named section; records the read server-side
  - **read_system_prompt_tool**: Returns the project system prompt string
  - **get_unread_sections_tool**: Returns a JSON array of enabled section names not yet read via `read_section_tool`; returns `[]` when all enabled sections have been read
- **Section Completeness Enforcement**: The harness tracks which sections have been read server-side via `SectionReadTracker`. The agent queries `get_unread_sections_tool` after its initial reads and repeats reading until the tool returns `[]`, guaranteeing all enabled sections are read before final content is written.
- **Conversation Continuity**: Uses `previous_response_id` for conversation continuity between tool-calling iterations, instead of re-sending full message history (as in the Chat Completions variant)
- **Streaming Execution**: Uses `ToolSession.stream()` which yields `ToolSessionEvent` values in real time. The window shows live iteration status, tool call spinners, streamed text output, and incremental token usage as the agent runs.
- **Timeout Respect**: Every internal LLM request in the tool-calling loop honours the `requestTimeoutSeconds` configured on the selected `LLMConnection`
- **Iteration Limit**: The maximum number of LLM round-trips is dynamically computed from the number of enabled sections: `enabledSections + 5`. The +5 accounts for list, verify, final response, optional system prompt read, and one buffer iteration. If the agent exceeds this limit, an error is raised.

### Window Layout
- Three-column `HSplitView` window (1000x700 minimum, 1200x700 default)
- **Column 1** (Project Overview): Read-only display of system prompt and section names list with live read-count badges
- **Column 2** (Agent Controls): LLM picker, reasoning effort picker, editable instructions field, "Run Agent" button, tool call log, token usage summary
  - The instructions field always defaults to a generic task request
  - The project system prompt is **not** used as the instructions default
- **Column 3** (Generated Content): Scrollable, copyable, saveable generated output
  - While the agent is running and no content has streamed yet, Column 3 shows live status text (e.g. "Thinking (iteration 1)…", "Calling read_section_tool…")
  - As content streams in via `contentPartDelta` events, it appears incrementally in real time
  - Thinking blocks are collected during the stream from `ReasoningItem.contentText` (structured reasoning) and from `<think>` tag extraction after the stream completes; both sources are combined

### Tool Call Log
- **During execution**: Log populates incrementally as tool calls complete; an in-progress spinner row shows the currently executing tool
- **After agent completes**: Log shows all tool calls with: tool name, arguments (truncated, expandable), result preview (truncated), duration in milliseconds

### Token Usage Display
- **Live updates during generation**: After each LLM iteration completes, the token usage summary updates in real time showing cumulative input, output, and total token counts. When present, cached input token count and reasoning output token count are also shown.
- **On completion**: Display a final token usage summary showing cumulative input tokens (with cached count if non-zero), reasoning tokens (if non-zero), output tokens, total tokens, and iteration count across all iterations
- **Location**: Token usage summary displayed in Column 2 below the tool call log
- **Empty state**: If the API response does not include usage data, show "Token usage unavailable"

### Reasoning Effort
- **Control**: A "Reasoning Effort" picker in Column 2, between the LLM model picker and the instructions field
- **Options**: None, Low, Medium, High, xHigh
- **Default**: Medium
- **Behaviour**: When a non-None effort is selected, a `Reasoning` config parameter with the chosen effort level and `summary: .auto` is appended to the `configParams` array passed to `session.stream()`. When None is selected, no `Reasoning` param is sent.
- **Disabled during run**: The picker is non-interactive while the agent is running

### Section Read Count Badges
- **Location**: Column 1, inline with each section name row
- **Appearance**: A compact badge showing the number of times the agent has read each section (e.g., "1×", "2×")
- **Visibility**: Badge only appears for sections that have been read at least once; sections with zero reads show no badge
- **Live updates**: Badge count increments in real time as `read_section_tool` calls complete during agent execution
- **Reset**: All badges clear when a new agent run starts

### Generated Content Actions
- Copy to Clipboard
- Save to File (as `.md`)
- Done (dismisses window)

## Data Requirements
- `AgentSection`: Plain `Sendable` value type carrying section name, content, prompts, and enabled state -- no SwiftData dependency
- `AgentGenerationWindowState`: Observable class coordinating window data, populated by the app before opening the window

## Window ID
- `"project-agent-generation-responses"` -- distinct from the Chat Completions variant's `"project-agent-generation"`

---
**Last Updated:** 2026-03-19 (reasoning effort picker, contentText reasoning capture, detailed token breakdown)
