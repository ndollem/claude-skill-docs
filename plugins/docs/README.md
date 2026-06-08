# docs plugin

A Claude Code plugin that generates and maintains standard project documentation by
reading the codebase. Three skills, namespaced under `docs`:

| Command | What it does |
|---|---|
| `/docs:init` | Bootstrap full `docs/` from scratch by scanning an existing codebase |
| `/docs:update [area]` | Update specific docs sections after a feature or refactor |
| `/docs:check` | Audit documentation health and surface drift vs. the codebase |

These complement `/code-review` (built-in). `/code-review` looks at the code; these
skills look at whether the *documentation* reflects the code.

## What it generates

```
docs/
  01-prd.md              Product requirements
  02-erd.md              Engineering requirements / tech stack
  03-architecture.md     System design
  04-coding-standards.md Detected patterns & standards
  05-decision-log.md     Architecture Decision Records
  LAST_REVIEWED          Freshness marker
AGENTS.md                Instructions for AI coding agents
.ai/project-definition.json   Machine-readable project definition
```

Sections that cannot be inferred from the codebase are marked `⚠️ [Needs human input]`.
The skills never fabricate business goals, personas, or metrics.

## Design notes

- **Portable.** All environment scanning goes through `bin/doc-context`, which detects
  git vs. non-git and degrades gracefully — the skills work in any project, with or
  without git history.
- **Surgical updates.** `/docs:update` uses targeted edits, never whole-file rewrites,
  and preserves human-written prose. AI-generated additions are tagged
  `<!-- AI-generated -->`.
- **Human owns the business layer.** `init` and `update` flag business decisions for
  human review rather than inventing or changing them.
- **Opt-in discovery.** `/docs:init … --interactive` interviews you to fill business
  sections instead of leaving `⚠️` markers.

## Local development

From the repository root:

```bash
claude --plugin-dir ./plugins/docs
# then in the session:
/reload-plugins        # after editing any SKILL.md or template
/docs:check            # try it
```

See the repository root `README.md` for marketplace installation.
