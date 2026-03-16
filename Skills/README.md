# Skills (Claude Code Skill Documentation)

Project-level specifications and documentation for the Claude Code skills used in this monorepo. The executable skill definitions (SKILL.md files) live in `.claude/skills/` where Claude Code loads them at runtime. This folder holds human-readable specifications that describe each skill's purpose, workflow position, inputs, and outputs.

The skill system follows the [Agent Skills specification](https://agentskills.io/specification).

## Skills

| Skill | Category | Description |
|-------|----------|-------------|
| [prep-for-coding](prep-for-coding/) | Required (before code) | Reads specs and produces a synthesized implementation approach |
| [validate-build](validate-build/) | Required (after code) | Runs phased build validation and classifies errors |
| [log-error](log-error/) | Required (after errors) | Documents resolved errors in CodeLessonsLearned |
| [update-specs](update-specs/) | Required (after changes) | Updates specification files to reflect changes |
| [log-change](log-change/) | Optional (after changes) | Proposes changelog entries for completed changes |
| [evaluate-specs](evaluate-specs/) | On-demand | Runs spec quality evaluation with scored criteria |
| [generate-docc](generate-docc/) | On-demand | Generates or validates DocC documentation catalogs |

## Workflow

The required skills form a development loop:

```
prep-for-coding --> [write code] --> validate-build --> [fix errors] --> log-error
                                                                           |
                                                                           v
                                                     log-change <-- update-specs
```

On-demand skills (`evaluate-specs`, `generate-docc`) can be invoked at any time independently.

## Relationship to .claude/skills/

| `.claude/skills/<name>/SKILL.md` | `Skills/<name>/SkillSpec.md` |
|----------------------------------|------------------------------|
| Executable definition loaded by Claude Code | Human-readable specification |
| Contains step-by-step instructions | Describes purpose, inputs, outputs |
| YAML frontmatter + markdown body | Documentation-oriented markdown |

## Skill Development

See [ProjectSpecs/SkillDevelopmentSpec.md](../ProjectSpecs/SkillDevelopmentSpec.md) for the authoritative rules on creating and maintaining skills, including the SKILL.md template and the new-skill checklist.

---

[Back to root README](../README.md)
