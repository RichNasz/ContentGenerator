---
name: evaluate-specs
description: Runs the formal 5-criterion quality evaluation from SpecificationQualitySpec.md. Scores each criterion 0-10 and produces a weighted overall score with recommendations.
argument-hint: "[project name or \"all\"]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep
---

# Specification Quality Evaluation

Run the formal quality evaluation defined in `CommonSpecs/SpecificationQualitySpec.md` against the specification suite for a target project or all projects.

## Step 1: Read the Evaluation Framework

Read `CommonSpecs/SpecificationQualitySpec.md` to confirm the current evaluation criteria and rating scales.

## Step 2: Read All Applicable Specs

**If a specific project is named** (ContentGenerator, LLMmanagement, or ProjectExchange):
- Read all files in `<Project>/Specs/` (FunctionalSpecs.md, SwiftTechSpecs.md, CodeLessonsLearned.md, and any additional specs)

**If "all" is specified**:
- Read all files in each project's `Specs/` directory

**Always read all 8 CommonSpecs files**:
- `CommonSpecs/SwiftCodeGeneration.md`
- `CommonSpecs/SwiftUISpec.md`
- `CommonSpecs/SwiftUIWithoutMVVM.md`
- `CommonSpecs/SwiftDataPatterns.md`
- `CommonSpecs/SwiftTestingSpec.md`
- `CommonSpecs/NavigationPatterns.md`
- `CommonSpecs/DocumentationSpec.md`
- `CommonSpecs/SpecificationQualitySpec.md`

## Step 3: Score Each of the 5 Criteria (0-10)

Evaluate using the rating scales from SpecificationQualitySpec.md:

### Criterion 1: Human-AI Interaction (Weight: 20%)
Assess: roles and responsibilities, communication protocols, workflow integration, knowledge transfer, error recovery processes.

### Criterion 2: Ability to Generate Error-Free Code (Weight: 20%)
Assess: testing integration, error prevention, quality gates, debugging support, regression prevention.

### Criterion 3: Quality of Documentation That Will Be Generated (Weight: 20%)
Assess: documentation standards, consistency requirements, completeness criteria, accessibility, maintenance processes.

### Criterion 4: Quality of Code That Can Be Generated (Weight: 20%)
Assess: code quality standards, performance requirements, maintainability, best practices alignment, testing standards.

### Criterion 5: Holistic Specification Suite Integration (Weight: 20%)
Assess: cross-specification consistency, suite completeness, integration dependencies, cohesive codebase generation capability, unified knowledge base, implementation coverage, conflict resolution, version synchronization.

For each criterion, provide:
- A numeric score (0-10)
- 2-3 sentences of justification referencing specific spec content

## Step 4: Calculate Weighted Overall Score

Apply the equal-weight formula:

```
Overall = (C1 + C2 + C3 + C4 + C5) * 0.20
```

Map to the final rating category:
- **9-10**: Exceptional specification quality
- **7-8**: Good specification quality
- **5-6**: Adequate specification quality
- **3-4**: Poor specification quality
- **0-2**: Unacceptable specification quality

## Step 5: Produce the Evaluation Report

Output a structured report with these sections:

### Scores Table

| Criterion | Score | Weight | Weighted |
|-----------|-------|--------|----------|
| 1. Human-AI Interaction | X/10 | 20% | X.X |
| 2. Error-Free Code Generation | X/10 | 20% | X.X |
| 3. Documentation Quality | X/10 | 20% | X.X |
| 4. Code Quality | X/10 | 20% | X.X |
| 5. Holistic Suite Integration | X/10 | 20% | X.X |
| **Overall** | | | **X.X/10** |

### Rating Category
State the rating category and what it means.

### Strengths
List 3-5 specific strengths observed in the specification suite, referencing specific files and sections.

### Areas for Improvement
List 3-5 specific areas where the specs fall short, referencing the criteria and what's missing.

### Per-File Scores
For each spec file evaluated, attribute a file-level score (0-10) indicating how well that individual file contributes to the overall suite quality. Present as a table:

| File | Score | Notes |
|------|-------|-------|
| `<Project>/Specs/FunctionalSpecs.md` | X/10 | [brief note on strengths/weaknesses] |
| `<Project>/Specs/SwiftTechSpecs.md` | X/10 | [brief note] |
| ... | ... | ... |

This helps identify which specific files need the most attention.

### Actionable Recommendations
Provide 3-5 specific, prioritized recommendations for improving the lowest-scoring criteria. Each recommendation should identify the file to modify and the change to make.
