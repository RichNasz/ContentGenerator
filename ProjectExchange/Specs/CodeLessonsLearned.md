# Error Resolution Database

## Purpose and Scope

This specification defines a **living knowledge base** that captures compilation errors, test failures, and runtime issues encountered during AI code generation for the ProjectExchange package, along with their proven fixes. This system enables instant error resolution, enforces consistency across the codebase, and creates a self-improving AI development environment.

**Critical Requirement**: Every error encountered must be documented with its proven solution to prevent re-solving the same problems and ensure consistent fixes throughout the codebase.

**Swift 6 + Default MainActor Context**: This project uses Swift 6 with default actor isolation set to MainActor, which changes common error patterns compared to manual @MainActor annotation projects.

## Quick Reference Index

- [High-Frequency Errors](#high-frequency-errors)
- [Compilation Errors](#compilation-errors)
- [SwiftData Errors](#swiftdata-errors)
- [SwiftUI Errors](#swiftui-errors)
- [Test Failure Errors](#test-failure-errors)
- [Runtime Errors](#runtime-errors)
- [Search Guidelines](#search-guidelines)

## Error Entry Template

### Error ID: ERR-[CATEGORY]-[NUMBER]
- **Discovery Method**: [Compilation | Unit Test | Integration Test | Runtime]
- **Frequency**: [Count of occurrences - updated each time encountered]
- **Error Message**: [Exact error text from compiler/test/runtime]
- **Test Case**: [Specific test that revealed error, if applicable]
- **Context**: [When/where this occurs - file types, operations, patterns]
- **Root Cause**: [Technical explanation of why this happens]
- **Proven Fix**: [Step-by-step resolution that has been verified]
- **Code Before**: [Example of error-causing code]
- **Code After**: [Example of fixed code]
- **Prevention Pattern**: [How to avoid this error in future code generation]
- **Verification**: [How to confirm the fix works]
- **Related Errors**: [Links to similar error IDs]
- **Last Updated**: [Date of most recent update]

---

## High-Frequency Errors

*No high-frequency errors recorded yet.*

---

## Compilation Errors

*No entries yet.*

---

## SwiftData Errors

*No entries yet.*

---

## SwiftUI Errors

*No entries yet.*

---

## Test Failure Errors

*No entries yet.*

---

## Runtime Errors

*No entries yet.*

---

## Search Guidelines

When encountering an error in ProjectExchange:

1. **Search by error message**: Use exact compiler error text
2. **Search by category**: SWIFT, DATA, UI, RUNTIME, TEST, CONCURRENCY
3. **Search by context**: File type, operation, or pattern involved
4. **Check related errors**: Follow Related Errors links for similar issues
5. **Check other targets**: If no match here, check `ContentGenerator/Specs/CodeLessonsLearned.md` and `LLMmanagement/Specs/CodeLessonsLearned.md` for similar patterns

---

*This file is automatically maintained during AI code generation sessions and should capture learning from both project-specific and common specification contexts.*

---

**Last Updated**: 2026-03-16
**Swift Version**: 6.2 (swift-tools-version: 6.2)
