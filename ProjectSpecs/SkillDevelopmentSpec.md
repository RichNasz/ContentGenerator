# SkillDevelopmentSpec

> Authoritative rules for creating, structuring, and maintaining Claude Code skills in this project. Grounded in the [Agent Skills specification](https://agentskills.io/specification).

---

## Governing Standard

This project's skills conform to the [Agent Skills specification](https://agentskills.io/specification), an open format for extending AI agent capabilities. All SKILL.md files must be valid per that specification. This document adds project-specific conventions on top of the base standard.

## Skill System Overview

Skills exist in two locations with distinct roles:

| Location | Role | Contents |
|----------|------|----------|
| `.claude/skills/<name>/SKILL.md` | Executable definition | YAML frontmatter + markdown instructions loaded by Claude Code at runtime |
| `Skills/<name>/SkillSpec.md` | Project-level specification | Human-readable documentation of purpose, workflow position, inputs, outputs |

The `.claude/skills/` files are the runtime definitions that Claude Code loads. The `Skills/` folder is the specification and documentation layer visible on GitHub.

---

## SKILL.md Template

Per the Agent Skills specification, each skill directory must contain a `SKILL.md` file with YAML frontmatter and markdown body.

### Required Frontmatter Fields

| Field | Constraints | Example |
|-------|------------|---------|
| `name` | 1-64 chars, lowercase alphanumeric + hyphens, must match parent directory name | `prep-for-coding` |
| `description` | 1-1024 chars, describes what and when | `Reads all applicable specs before code generation...` |

### Project-Specific Frontmatter Fields

These fields are not part of the base Agent Skills spec but are used by this project:

| Field | Required | Purpose |
|-------|----------|---------|
| `argument-hint` | Yes | Bracketed hint for the expected argument (e.g., `"[feature or area]"`) |
| `allowed-tools` | No | Comma-separated list of tools the skill may use (e.g., `Read, Glob, Grep`) |
| `disable-model-invocation` | No | Set to `true` for skills that should not auto-trigger |

### Optional Agent Skills Fields

| Field | Purpose |
|-------|---------|
| `license` | License name or reference to bundled license file |
| `compatibility` | Environment requirements (max 500 chars) |
| `metadata` | Arbitrary key-value mapping for additional properties |

### Body Structure

The markdown body after frontmatter contains the skill instructions:

1. **H1 Title** -- descriptive name for the skill's action
2. **Edit scope constraint** (if applicable) -- declares which files the skill may modify
3. **Numbered Step sections** (`## Step N: Title` or `## Phase N: Title`) -- each step has clear instructions
4. **Output template** (if applicable) -- structured format for the skill's output

Keep the main SKILL.md under 500 lines per the Agent Skills spec's progressive disclosure guidance. Move detailed reference material to `references/` files.

---

## Skill Categories

Skills are classified by their position in the development workflow:

| Category | Skills | When to Invoke |
|----------|--------|----------------|
| **Required workflow** | `prep-for-coding`, `validate-build`, `log-error`, `update-specs` | Must be invoked at the indicated workflow point per CLAUDE.md |
| **Optional workflow** | `log-change` | Available after completing functionality changes |
| **On-demand** | `evaluate-specs`, `generate-docc` | Invoke when explicitly requested |

---

## SkillSpec.md Requirements

Each `Skills/<name>/SkillSpec.md` must contain these sections in order:

1. **H1 Title** -- skill name in human-readable form (e.g., "prep-for-coding")
2. **Description** -- one paragraph explaining the skill's purpose
3. **Workflow Position** -- category (required/optional/on-demand) and when to invoke relative to other workflow steps
4. **Invocation** -- exact slash command syntax with argument description
5. **Inputs** -- files and data the skill reads
6. **Outputs** -- what the skill produces (reports, file edits, synthesis)
7. **Allowed Tools** -- tools the skill is permitted to use
8. **Related Skills** -- skills typically invoked before or after this one
9. **Back Links** -- links to `Skills/README.md` and root `README.md`

### Rules

- Do not replicate the full SKILL.md body -- describe what the skill does, not the step-by-step instructions
- Same tone as root README (professional, precise, no emojis)
- Keep concise -- orient the reader, point them to the SKILL.md for execution details

---

## Optional Directories

Per the Agent Skills specification, each skill directory may include:

| Directory | Purpose | When to Create |
|-----------|---------|----------------|
| `scripts/` | Executable code the skill can run | When the skill needs to run shell scripts, Python, etc. |
| `references/` | Additional documentation loaded on demand | When SKILL.md exceeds 500 lines or needs supplemental reference |
| `assets/` | Templates, images, data files | When the skill uses static resources |

Create these directories only when actual content is needed. Do not pre-create empty directories.

---

## Naming Conventions

| Item | Convention | Example |
|------|-----------|---------|
| Skill directory name | kebab-case, matches `name` field | `prep-for-coding/` |
| Executable definition | Uppercase | `SKILL.md` |
| Skill specification | PascalCase | `SkillSpec.md` |
| Script files | Descriptive, lowercase | `scripts/extract.py` |
| Reference files | Uppercase or descriptive | `references/REFERENCE.md` |

---

## Adding a New Skill

Checklist for creating a new skill:

1. Create `.claude/skills/<name>/SKILL.md` with frontmatter and body per the template above
2. Create `Skills/<name>/SkillSpec.md` per the SkillSpec.md requirements above
3. Add an entry to the skills table in `Skills/README.md`
4. Add the invocation rule to `CLAUDE.md` with its workflow position
5. Add the skill directory to the tree in `ProjectSpecs/RepositoryStructureSpec.md`
6. Add `Skills/<name>/SkillSpec.md` to the generated files table in `ProjectSpecs/DocumentationGenerationSpec.md`

## Modifying an Existing Skill

When modifying a skill's SKILL.md:

- Update the corresponding `Skills/<name>/SkillSpec.md` if the change affects purpose, inputs, outputs, or workflow position
- Update `Skills/README.md` if the description or category changes
- Update `CLAUDE.md` if the invocation rules change
