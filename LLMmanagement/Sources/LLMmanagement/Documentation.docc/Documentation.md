# ``LLMmanagement``

A Swift package for managing Large Language Model connections with SwiftData persistence.

## Overview

LLMmanagement provides a robust, type-safe way to manage connections to Large Language Model services in your Swift applications. Built on SwiftData for seamless persistence, it supports both authenticated cloud services and local LLM instances.

### Key Features

- **SwiftData Integration**: Automatic persistence with modern Swift data modeling
- **Connection Management**: Store and manage multiple LLM service configurations
- **Flexible Authentication**: Support for both API key authentication and local services
- **Validation**: Built-in configuration validation and URL verification
- **Usage Tracking**: Monitor connection usage patterns and analytics
- **SwiftUI Ready**: Designed to work seamlessly with SwiftUI and @Observable patterns

### Supported Platforms

- iOS 26.0+
- macOS 26.0+
- visionOS 26.0+

## Topics

### Getting Started

- <doc:Getting-Started>
- <doc:User-Guide>

### API Reference

- <doc:API-Reference>
- ``LLMConnection``

### Connection Management

- ``LLMConnection/init(name:apiUrl:apiKey:selectedModel:requestTimeoutSeconds:isDefault:)``
- ``LLMConnection/init(copying:name:apiUrl:apiKey:selectedModel:requestTimeoutSeconds:isDefault:)``
- ``LLMConnection/isConfigured``
- ``LLMConnection/updateLastUsed()``

### Configuration Properties

- ``LLMConnection/name``
- ``LLMConnection/apiUrl``
- ``LLMConnection/apiKey``
- ``LLMConnection/selectedModel``
- ``LLMConnection/requestTimeoutSeconds``
- ``LLMConnection/isDefault``

### Tracking and Analytics

- ``LLMConnection/createdAt``
- ``LLMConnection/lastUsed``
- ``LLMConnection/displayName``

## See Also

- [SwiftData Documentation](https://developer.apple.com/documentation/swiftdata)
- [SwiftUI Integration](https://developer.apple.com/documentation/swiftui)