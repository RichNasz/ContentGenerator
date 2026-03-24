# AgentGen (Swift Package)

AgentGen is a Swift package that provides agent-based content generation with pluggable inference backends. It supports both on-device Apple Intelligence (Foundation Models) and cloud/local Open Responses API backends, with a unified event-driven architecture consumed by the ContentGenerator app.

## Role in Monorepo

Referenced by the ContentGenerator app as a local Swift package (`../AgentGen`). Provides the agent generation window, inference backends, and tool definitions for autonomous content generation workflows.

## Key Features

- **Multi-Backend Architecture** — Pluggable inference backends conforming to `AgentInferenceBackend` protocol
- **Apple Intelligence Backend** — On-device generation using Foundation Models framework with non-streaming `respond()`
- **Open Responses Backend** — Cloud/local streaming generation using `SwiftOpenResponsesDSL` with `ToolSession`
- **Agent Tools** — Four read-only tools (list sections, read section, read system prompt, get unread sections) for autonomous spec inspection
- **Unified Event Stream** — `AgentEvent` enum consumed by the view regardless of backend
- **Activity Log** — Chronological log of all agent events (tool calls, thinking, status updates, token usage)
- **Section Read Tracking** — Actor-based tracker ensuring the agent reads all enabled sections

## Specs

See [Specs/](Specs/) for this target's specification files:
- [FunctionalSpecs.md](Specs/FunctionalSpecs.md) — What the package does
- [SwiftTechSpecs.md](Specs/SwiftTechSpecs.md) — How it's implemented
- [CodeLessonsLearned.md](Specs/CodeLessonsLearned.md) — Error patterns and solutions

## Building

```bash
swift build
```

---

[Back to root README](../README.md)
