@AGENTS.md

## Working in this repo with Claude Code

- Read the docs in order first: `docs/01-prd.md` → `docs/05-decision-log.md`.
- After shipping a change, run `/docs:update [area]` to keep docs in sync.
- Run `/docs:check` anytime to audit documentation health.

<!-- AGENTS.md is the single source of truth for agent instructions; this file imports
     it so Claude Code (which reads CLAUDE.md, not AGENTS.md) picks it up. Edit AGENTS.md,
     not this file. -->
