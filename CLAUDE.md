# CLAUDE.md

## Skill-Driven Development Workflow

This project uses Claude Code skills to enforce its specification-driven methodology.
The following skills MUST be invoked at the indicated workflow points.

### Before Writing or Modifying Code
Invoke `/prep-for-coding <feature area>` before generating or modifying any code.
This reads all applicable specs, checks for spec currency issues (outdated references,
contradictions, stale entries), and produces a synthesized implementation approach.
Do not skip this step -- it is required for every code change.

### After Generating or Modifying Code
Invoke `/validate-build <target>` after any code generation or modification.
Target is one of: ContentGenerator, LLMmanagement, ProjectExchange.
This runs phased build validation and classifies errors against CodeLessonsLearned.

### After Resolving Any Error
Invoke `/log-error <description>` after resolving any compilation error,
test failure, or runtime issue. This documents the error in CodeLessonsLearned.md
using the 12-field template. Do not skip this -- every resolved error must be logged.

### After Completing Functionality Changes
Invoke `/update-specs <description>` after functionality changes are complete
and validated. This updates FunctionalSpecs, SwiftTechSpecs, and CodeLessonsLearned
to reflect the changes, verifies cross-reference consistency, detects dead references,
and checks for terminology drift.

### Optional: Log Change to Changelog
`/log-change <description>` is available after completing functionality changes
(typically after `update-specs`). Proposes a changelog entry using Keep a Changelog format
and writes it to CHANGELOG.md upon user approval. Invoke when you want to record the change.

### On-Demand: Specification Quality Audit
`/evaluate-specs <project or "all">` is available for on-demand quality audits.
Invoke when explicitly requested by the user.

### On-Demand: DocC Documentation Generation
`/generate-docc <target>` is available for generating or validating DocC documentation.
Target is one of: ContentGenerator, LLMmanagement, ProjectExchange.
Invoke when explicitly requested by the user.

### After Successful Build Validation (Optional)
`/run-tests <target>` is available after `/validate-build` passes.
Runs the Swift Testing suite and classifies failures against CodeLessonsLearned.

### On-Demand: Repository Documentation Generation
`/generate-repo-docs <file or "all">` generates or regenerates README.md,
CONTRIBUTING.md, issue templates, and other documentation from ProjectSpecs.

### On-Demand: Integration Validation
`/validate-integration` builds all three targets in dependency order
to verify cross-project compatibility.

### On-Demand: Specification Validation
`/validate-specs <project or "all">` checks spec consistency,
cross-references, terminology, and completeness.

### On-Demand: Commit Validation
`/validate-commit [ref]` validates commit message format against
ContributingSpec conventions.
