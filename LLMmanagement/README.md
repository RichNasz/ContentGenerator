# LLMmanagement (Swift Package)

LLMmanagement is a Swift package that provides connection management and configuration for Large Language Model services. It includes a SwiftData-backed connection model, OpenAI-compatible API client, and streaming support for real-time content generation.

## Role in Monorepo

Referenced by the ContentGenerator app as a local Swift package (`../LLMmanagement`). Provides the data model and API layer for all LLM interactions.

## Key Features

- **LLMConnection Model** — SwiftData `@Model` for persisting LLM service configurations (URLs, API keys, models, timeouts)
- **OpenAI Endpoint Types** — Support for Chat Completions (`/v1/chat/completions`) and Responses (`/v1/responses`) endpoints
- **Flexible URL Construction** — Base URL + optional custom path or endpoint-type default path
- **Configuration Validation** — URL format, required field, and model selection validation
- **Timeout Management** — Configurable timeouts constrained to 60-600 seconds with automatic clamping
- **Multi-Provider Support** — Works with OpenAI, Gemini, Grok, vLLM, Ollama, LM Studio, and other OpenAI-compatible services

## Specs

See [Specs/](Specs/) for this target's specification files:
- [FunctionalSpecs.md](Specs/FunctionalSpecs.md) — What the package does
- [SwiftTechSpecs.md](Specs/SwiftTechSpecs.md) — How it's implemented
- [CodeLessonsLearned.md](Specs/CodeLessonsLearned.md) — Error patterns and solutions

## Building

```bash
swift build
swift test
```

---

[Back to root README](../README.md)
