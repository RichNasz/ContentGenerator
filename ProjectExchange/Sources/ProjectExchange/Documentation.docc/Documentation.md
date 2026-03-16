# ``ProjectExchange``

Import and export ContentGenerator projects to a portable JSON format.

## Overview

ProjectExchange provides a type-safe, secure mechanism for serializing and deserializing ContentGenerator projects. The package produces human-readable JSON with schema versioning for forward compatibility and migration support.

### Design Principles

- **Security-First**: API keys are never included in exports
- **Portability**: JSON format works across applications and platforms
- **Human-Readable**: Pretty-printed output for easy inspection
- **Type-Safe**: Full Codable conformance with Sendable support
- **Versioned**: Schema versioning enables graceful format evolution

### Package Structure

The package is organized into four main components:

- **Services**: `ProjectSerializer` handles all import/export operations
- **Models**: Transfer objects for projects, sections, and configurations
- **Enums**: Type-safe status and configuration enumerations
- **Errors**: Comprehensive error types for operation failures

## Topics

### Essentials

- <doc:Getting-Started>
- <doc:User-Guide>
- <doc:API-Reference>

### Serialization

- ``ProjectSerializer``
- ``ProjectExchangeError``

### Project Models

- ``ExportableProject``
- ``ExportableSpecification``
- ``ExportableSection``

### Configuration Models

- ``ExportableLLMConfiguration``
- ``ExportableFileAttachment``

### Enumerations

- ``ExportableProjectStatus``
- ``ExportableEndpointType``

### Version Information

- ``ProjectExchange``
