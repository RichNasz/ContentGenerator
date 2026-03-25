# Functional Specifications

## Package Overview
**Package Name:** AgentGen
**Purpose:** Agent-based project content generation with pluggable inference backends (Apple Intelligence on-device, Open Responses API cloud/local)
**Consumers:** ContentGenerator macOS app

## Core Functionality

### Multi-Backend Agent Architecture
- Provides a "Generate with Agent" workflow at the project level
- The agent calls read-only tools to inspect specification sections and the project system prompt before producing final content
- Two inference backends, selected via a unified picker:
  - **Apple Intelligence** (on-device): Uses Foundation Models framework (`LanguageModelSession`), non-streaming `respond()`, 4,096 token context window
  - **Open Responses** (cloud/local): Uses `SwiftOpenResponsesDSL` (`ToolSession.stream()`), streaming execution with real-time events
- Backends conform to `AgentInferenceBackend` protocol and yield `AgentEvent` values through `AsyncThrowingStream`
- The view consumes events in a single loop without knowing the backend implementation

### Agent Tools
- Four tools available to the agent, with backend-specific naming:

| Logical Tool | Open Responses Name | Apple Intelligence Name |
|---|---|---|
| List sections | `list_sections_tool` | `listSections` |
| Read section | `read_section_tool` | `readSection` |
| Read system prompt | `read_system_prompt_tool` | `readSystemPrompt` |
| Get unread sections | `get_unread_sections_tool` | `getUnreadSections` |

- **list_sections_tool / listSections**: Returns a JSON list of `{name, isEnabled}` objects for all sections
- **read_section_tool / readSection**: Returns content, generation prompt, and usage prompt for a named section; records the read server-side
- **read_system_prompt_tool / readSystemPrompt**: Returns the project system prompt string
- **get_unread_sections_tool / getUnreadSections**: Returns a JSON array of enabled section names not yet read; returns `[]` when all enabled sections have been read
- **Section Completeness Enforcement**: The harness tracks which sections have been read via `SectionReadTracker` (actor). The agent queries the unread sections tool after initial reads and repeats until `[]` is returned.

### Apple Intelligence Backend
- Uses `LanguageModelSession.respond()` (non-streaming) to avoid rate limiting
- Concise prompts (section names only, no XML spec) to fit within the 4,096 token context window
- Tool-first approach: model uses `listSections` then `readSection` to discover content incrementally
- Tool calls extracted from `session.transcript` entries after `respond()` completes
- Section reads reported from `SectionReadTracker` after execution
- Available only when `SystemLanguageModel.default.isAvailable` is true

### Instruments Telemetry
- **Opt-in**: The user toggles telemetry on/off in the agent window (cloud/local Open Responses connections only). The preference persists across sessions.
- **Scope**: Every Open Responses LLM interaction emits OSSignpost data — run intervals, per-iteration intervals, per-tool-call intervals, streaming content delta events, token usage events, prompt captures, and full HTTP POST body captures.
- **Instruments tracks** (visible in the os_signpost template, subsystem `com.rnaszcyn.ContentGenerator.AgentGen`):
  - `AgentRun`: interval spanning the full generation run
  - `Iteration`: interval per LLM iteration
  - `ToolCall`: interval per tool call
  - `ContentDelta`: point event per streamed content delta
  - `TokenUsage`: point event per usage update
  - `PromptSent`: point event with path to temp file containing the system prompt and user message
  - `HTTPRequest`: point event with path to temp file containing the complete wire-format JSON POST body (model, instructions, input, tools array with schemas, reasoning effort, `stream: true`, timeouts, `previous_response_id`, etc.) — one event per LLM iteration
- **HTTP POST capture**: The full serialized JSON body is intercepted at the transport layer and written to a temp file (e.g., `/tmp/agentgen_http_post_<timestamp>.json`). This captures fields invisible to higher-level telemetry, such as tool JSON schemas.
- **Backend isolation**: Telemetry is emitted by the backend, not the view. The view only creates and passes the telemetry object.
- **Other backends**: Apple Intelligence and any future backends not yet instrumented use a no-op telemetry implementation with zero overhead.

### Open Responses Backend
- **Streaming Execution**: Uses `ToolSession.stream()` yielding `ToolSessionEvent` values in real time
- **Conversation Continuity**: Uses `previous_response_id` between tool-calling iterations
- **XML Spec Delivery**: Full specification sections sent as XML-wrapped content via `XMLSpecFormatter`, with a section manifest listed twice for parsing robustness
- **Timeout Respect**: Every LLM request honours the `requestTimeoutSeconds` from the selected `LLMConnection`
- **Iteration Limit**: `enabledSections.count + 5` — accounts for list, verify, final response, optional system prompt read, and one buffer
- **Thinking Block Extraction**: `<think>...</think>` blocks extracted during streaming and yielded as events

### Backend Picker
- **On-Device section**: Apple Intelligence + LLM connections with local base URLs (localhost, 127.0.0.1, 0.0.0.0, ::1)
- **Cloud Connections section**: LLM connections with non-local base URLs
- **Connection filtering**: Only connections with `endpointType == .responses` are shown (Chat Completions connections excluded)
- **Reasoning Effort picker** (cloud/local Open Responses only): None, Low, Medium, High, xHigh — default Medium

### Window Layout
- Three-column `HSplitView` window (1000×700 minimum, 1200×700 default)

**Column 1** (Project Overview): Read-only display of:
- System prompt
- Specification sections list with live read-count badges (blue capsule, e.g., "2×")
- Available tools list showing backend-specific tool names with live call-count badges (orange capsule)

**Column 2** (Agent Controls):
- Model picker (On-Device / Cloud Connections sections)
- Reasoning effort picker (conditional on cloud/local Open Responses selection, disabled during run)
- Instruments Telemetry toggle (conditional on cloud/local Open Responses selection, disabled during run; persists across sessions via UserDefaults)
- Editable instructions field (defaults to a generic task request, not the system prompt)
- "Run Agent" button
- Token usage summary (conditional on Open Responses selection, persistent during/after run)
- Unified Activity Log showing all events chronologically

**Column 3** (Generated Content):
- Scrollable, copyable, selectable generated output
- While running with no content: shows "Agent is running…" placeholder
- As content streams in (Open Responses): appears incrementally in real time

### Activity Log
- Single chronological log replacing the former separate "Thinking Steps" and "Tool Call Log" sections
- Event types displayed with distinctive icons and styling:
  - **Status updates** (info icon, secondary color): iteration status, "Calling tool…", etc.
  - **Thinking summaries** (brain icon, purple): reasoning summary lines
  - **Thinking blocks** (brain.head.profile icon, purple): full reasoning blocks, expandable (collapsed by default) with word count
  - **Tool calls in progress** (spinner, blue): "running..." label
  - **Tool calls completed** (function icon, blue): expandable arguments, result preview (truncated at 400 chars), duration in ms
  - **Token usage** (gauge icon, secondary): formatted token summary
  - **Completion** (checkmark icon, green): "Generation complete"
  - **Failure** (xmark icon, red): error message
- Auto-scrolls to bottom as new entries arrive
- Shows event count in header
- Tool call started entries are replaced in-place with completed entries (single row per call)
- Thinking summaries are deduplicated

### Token Usage Display
- **Live updates during generation**: After each LLM iteration, cumulative input, output, and total token counts update. Cached input and reasoning output shown when non-zero.
- **Location**: Persistent summary in Column 2 above the Activity Log (cloud/local Open Responses only). Also appears as entries within the Activity Log.
- **Apple Intelligence**: No token usage (Foundation Models does not expose token counts programmatically)

### Generated Content Actions
- Copy to Clipboard
- Save to File (as `.md`, default filename: `<projectName>_agent_generated.md`)
- Done (dismisses window)

## Data Requirements
- `AgentSection`: Plain `Sendable` value type carrying section name, content, prompts, and enabled state — no SwiftData dependency
- `AgentGenerationWindowState`: Observable class coordinating window data, populated by the app before opening the window

## Window ID
- `"project-agent-generation-responses"`

---
**Last Updated:** 2026-03-25 (added HTTPRequest OSSignpost event: captures full wire-format HTTP POST body per LLM iteration to temp file; added PromptSent event description)
