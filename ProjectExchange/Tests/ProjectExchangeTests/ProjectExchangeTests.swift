//
//  ProjectExchangeTests.swift
//  ProjectExchange
//

import Testing
import Foundation
@testable import ProjectExchange

@Suite("ProjectExchange Tests")
struct ProjectExchangeTests {

    @Test("Schema version is set correctly")
    func testSchemaVersion() {
        #expect(ProjectExchange.schemaVersion == "1.0.0")
        #expect(ExportableProject.currentSchemaVersion == "1.0.0")
    }
}

@Suite("ProjectSerializer Tests")
struct ProjectSerializerTests {
    let serializer = ProjectSerializer()

    // MARK: - Test Fixtures

    func createTestProject() -> ExportableProject {
        let llmId = UUID()

        let section = ExportableSection(
            name: "Test Section",
            sectionDescription: "A test section",
            content: "Section content here",
            orderIndex: 0,
            contentGenerationPrompt: "Generate content",
            contentUsagePrompt: "Use this content",
            isEnabled: true,
            llmConnectionId: llmId,
            createdAt: Date(),
            modifiedAt: Date()
        )

        let specification = ExportableSpecification(
            createdAt: Date(),
            modifiedAt: Date(),
            sections: [section]
        )

        let attachment = ExportableFileAttachment(
            originalFileName: "test.md",
            originalFilePath: "/Users/test/Documents/test.md",
            fileExtension: "md",
            fileSizeBytes: 1024,
            createdAt: Date(),
            modifiedAt: Date()
        )

        let llmConfig = ExportableLLMConfiguration(
            id: llmId,
            name: "Test OpenAI",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com",
            endpointType: .chatCompletions,
            urlPath: nil,
            requestTimeoutSeconds: 120
        )

        return ExportableProject(
            name: "Test Project",
            projectDescription: "A test project for unit testing",
            status: .active,
            systemPrompt: "You are a test assistant",
            createdAt: Date(),
            modifiedAt: Date(),
            specification: specification,
            attachmentMetadata: [attachment],
            llmConnectionId: llmId,
            llmConfigurations: [llmConfig]
        )
    }

    // MARK: - Serialization Tests

    @Test("Export project to JSON data")
    func testExportToData() throws {
        let project = createTestProject()
        let data = try serializer.export(project)
        #expect(!data.isEmpty)
    }

    @Test("Export project to JSON string")
    func testExportToString() throws {
        let project = createTestProject()
        let jsonString = try serializer.exportToString(project)
        #expect(jsonString.contains("Test Project"))
        #expect(jsonString.contains("schemaVersion"))
        #expect(jsonString.contains("1.0.0"))
    }

    @Test("Import project from JSON data")
    func testImportFromData() throws {
        let project = createTestProject()
        let data = try serializer.export(project)
        let imported = try serializer.importProject(from: data)

        #expect(imported.name == project.name)
        #expect(imported.status == project.status)
    }

    @Test("Import project from JSON string")
    func testImportFromString() throws {
        let project = createTestProject()
        let jsonString = try serializer.exportToString(project)
        let imported = try serializer.importProject(from: jsonString)

        #expect(imported.name == project.name)
        #expect(imported.schemaVersion == project.schemaVersion)
    }

    @Test("Round-trip preserves all data")
    func testRoundTrip() throws {
        let project = createTestProject()
        let data = try serializer.export(project)
        let imported = try serializer.importProject(from: data)

        // Project fields
        #expect(imported.name == project.name)
        #expect(imported.projectDescription == project.projectDescription)
        #expect(imported.status == project.status)
        #expect(imported.systemPrompt == project.systemPrompt)
        #expect(imported.schemaVersion == project.schemaVersion)
        #expect(imported.llmConnectionId == project.llmConnectionId)

        // Specification
        #expect(imported.specification?.sections.count == project.specification?.sections.count)
        #expect(imported.specification?.sections.first?.name == project.specification?.sections.first?.name)
        #expect(imported.specification?.sections.first?.llmConnectionId == project.specification?.sections.first?.llmConnectionId)

        // Attachments
        #expect(imported.attachmentMetadata.count == project.attachmentMetadata.count)
        #expect(imported.attachmentMetadata.first?.originalFilePath == project.attachmentMetadata.first?.originalFilePath)

        // LLM configs
        #expect(imported.llmConfigurations.count == project.llmConfigurations.count)
        #expect(imported.llmConfigurations.first?.name == project.llmConfigurations.first?.name)
        #expect(imported.llmConfigurations.first?.selectedModel == project.llmConfigurations.first?.selectedModel)
        #expect(imported.llmConfigurations.first?.id == project.llmConfigurations.first?.id)
    }

    @Test("Validate round-trip returns true for valid project")
    func testValidateRoundTrip() {
        let project = createTestProject()
        #expect(serializer.validateRoundTrip(project))
    }

    @Test("Invalid JSON string throws error")
    func testInvalidJSONString() {
        #expect(throws: ProjectExchangeError.self) {
            _ = try serializer.importProject(from: "not valid json")
        }
    }

    @Test("Empty project (minimal data) serializes correctly")
    func testMinimalProject() throws {
        let project = ExportableProject(
            name: "Minimal Project",
            projectDescription: nil,
            status: .draft,
            systemPrompt: nil,
            createdAt: Date(),
            modifiedAt: Date(),
            specification: nil,
            attachmentMetadata: [],
            llmConnectionId: nil,
            llmConfigurations: []
        )

        let data = try serializer.export(project)
        let imported = try serializer.importProject(from: data)

        #expect(imported.name == "Minimal Project")
        #expect(imported.specification == nil)
        #expect(imported.attachmentMetadata.isEmpty)
        #expect(imported.llmConfigurations.isEmpty)
        #expect(imported.llmConnectionId == nil)
    }

    @Test("Multiple LLM configurations are preserved")
    func testMultipleLLMConfigurations() throws {
        let llmId1 = UUID()
        let llmId2 = UUID()

        let section1 = ExportableSection(
            name: "Section 1",
            sectionDescription: nil,
            content: "Content 1",
            orderIndex: 0,
            contentGenerationPrompt: nil,
            contentUsagePrompt: nil,
            isEnabled: true,
            llmConnectionId: llmId1,
            createdAt: Date(),
            modifiedAt: Date()
        )

        let section2 = ExportableSection(
            name: "Section 2",
            sectionDescription: nil,
            content: "Content 2",
            orderIndex: 1,
            contentGenerationPrompt: nil,
            contentUsagePrompt: nil,
            isEnabled: true,
            llmConnectionId: llmId2,
            createdAt: Date(),
            modifiedAt: Date()
        )

        let specification = ExportableSpecification(
            createdAt: Date(),
            modifiedAt: Date(),
            sections: [section1, section2]
        )

        let llmConfig1 = ExportableLLMConfiguration(
            id: llmId1,
            name: "OpenAI",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com",
            endpointType: .chatCompletions,
            urlPath: nil,
            requestTimeoutSeconds: 120
        )

        let llmConfig2 = ExportableLLMConfiguration(
            id: llmId2,
            name: "Anthropic",
            selectedModel: "claude-3",
            baseUrl: "https://api.anthropic.com",
            endpointType: .responses,
            urlPath: "/v1/messages",
            requestTimeoutSeconds: 180
        )

        let project = ExportableProject(
            name: "Multi-LLM Project",
            projectDescription: nil,
            status: .active,
            systemPrompt: nil,
            createdAt: Date(),
            modifiedAt: Date(),
            specification: specification,
            attachmentMetadata: [],
            llmConnectionId: llmId1,
            llmConfigurations: [llmConfig1, llmConfig2]
        )

        let data = try serializer.export(project)
        let imported = try serializer.importProject(from: data)

        #expect(imported.llmConfigurations.count == 2)
        #expect(imported.specification?.sections[0].llmConnectionId == llmId1)
        #expect(imported.specification?.sections[1].llmConnectionId == llmId2)
    }

    @Test("JSON contains all expected keys")
    func testJSONContainsExpectedKeys() throws {
        // Note: Swift's JSONEncoder KeyedEncodingContainer does not preserve
        // insertion order, so we cannot test for specific key ordering.
        // The JSON is still human-readable due to prettyPrinted formatting.
        let project = ExportableProject(
            name: "Test",
            projectDescription: nil,
            status: .draft,
            systemPrompt: nil,
            createdAt: Date(),
            modifiedAt: Date(),
            specification: nil,
            attachmentMetadata: [],
            llmConnectionId: nil,
            llmConfigurations: []
        )

        let jsonString = try serializer.exportToString(project)

        // Verify all expected keys are present
        #expect(jsonString.contains("\"schemaVersion\""))
        #expect(jsonString.contains("\"name\""))
        #expect(jsonString.contains("\"status\""))
        #expect(jsonString.contains("\"attachmentMetadata\""))
        #expect(jsonString.contains("\"llmConfigurations\""))
        #expect(jsonString.contains("\"createdAt\""))
        #expect(jsonString.contains("\"modifiedAt\""))
    }
}

@Suite("ExportableLLMConfiguration Tests")
struct ExportableLLMConfigurationTests {

    @Test("Full API URL with default path")
    func testFullApiUrlDefaultPath() {
        let config = ExportableLLMConfiguration(
            id: UUID(),
            name: "Test",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com",
            endpointType: .chatCompletions,
            urlPath: nil,
            requestTimeoutSeconds: 120
        )

        #expect(config.fullApiUrl == "https://api.openai.com/v1/chat/completions")
    }

    @Test("Full API URL with custom path")
    func testFullApiUrlCustomPath() {
        let config = ExportableLLMConfiguration(
            id: UUID(),
            name: "Test",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com",
            endpointType: .chatCompletions,
            urlPath: "/custom/endpoint",
            requestTimeoutSeconds: 120
        )

        #expect(config.fullApiUrl == "https://api.openai.com/custom/endpoint")
    }

    @Test("Full API URL handles trailing slash")
    func testFullApiUrlTrailingSlash() {
        let config = ExportableLLMConfiguration(
            id: UUID(),
            name: "Test",
            selectedModel: "gpt-4",
            baseUrl: "https://api.openai.com/",
            endpointType: .responses,
            urlPath: nil,
            requestTimeoutSeconds: 120
        )

        #expect(config.fullApiUrl == "https://api.openai.com/v1/responses")
    }
}

@Suite("ExportableFileAttachment Tests")
struct ExportableFileAttachmentTests {

    @Test("Formatted file size")
    func testFormattedFileSize() {
        let attachment = ExportableFileAttachment(
            originalFileName: "test.md",
            originalFilePath: "/path/to/test.md",
            fileExtension: "md",
            fileSizeBytes: 1024,
            createdAt: Date(),
            modifiedAt: Date()
        )

        // ByteCountFormatter output varies by locale, just verify it's not empty
        #expect(!attachment.formattedFileSize.isEmpty)
    }
}
