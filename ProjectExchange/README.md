# ProjectExchange (Swift Package)

ProjectExchange is a Swift package that provides portable transfer objects for importing and exporting ContentGenerator projects. It enables project data to be serialized to JSON format for backup, sharing, or use in other applications.

## Role in Monorepo

Referenced by the ContentGenerator app as a local Swift package (`../ProjectExchange`). Handles all JSON serialization and deserialization for project import/export workflows.

## Key Features

- **Transfer Objects** — Immutable value types mirroring application models, free of SwiftData dependencies
- **JSON Serialization** — Encode/decode projects with ISO8601 dates, pretty-printed output, and UTF-8 encoding
- **Schema Versioning** — Each export includes a schema version for forward and backward compatibility
- **Round-Trip Validation** — Encode then decode produces equivalent data
- **Scoped Export** — Exports project metadata, specifications, prompts, and LLM references; excludes API keys and file contents for security

## Specs

See [Specs/](Specs/) for this target's specification files:
- [FunctionalSpecs.md](Specs/FunctionalSpecs.md) — What the package does
- [SwiftTechSpecs.md](Specs/SwiftTechSpecs.md) — How it's implemented

## Building

```bash
swift build
swift test
```

---

[Back to root README](../README.md)
