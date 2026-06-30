# Xenomoon Forge — framework spine rules

Rules for working **on the framework itself** (the Node/JS web UI and tooling under
`ui/`). The bound project's own rules live in the project, not here — they come from the
active domain pack's `orchestrator.md` + the project's own `CLAUDE.md`, which the
framework loads into every project session.

> Scaffold — expand with your own conventions. The essentials below match what the repo
> already enforces.

## Always

- Prefix shell commands with `rtk` (a PreToolUse hook enforces it; see `.claude/settings.json`).
- Plain JS + JSDoc only — no `.ts` files. Types are checked via tsconfig `checkJs`.
- Node/CLI scripts live in `ui/server/` so eslint's node group + tsconfig type-check them.

## Before committing

- `npm run validate` (tsc + eslint zero-warnings + structure + skill-scope) must pass.
- `npx prettier --write` keeps formatting clean (lint-staged also runs it on commit).

## Layout

- `plugin/` — the **CORE plugin** (the "basic install"): the domain-agnostic capabilities loaded
  into EVERY project session regardless of domain — meta skills (`caveman`, `quick`, `agent-report`,
  `tasks-mcp`, `autonomous-main-goal`), safety hooks, `handoff-summarizer`, and the researcher
  learning loop. Capabilities namespace as `xenomoon:<name>`.
- `domains/<name>/` — the **domain packs** (`app`, `webapp`). Each ships its own Claude Code plugin
  (the domain's agents/commands/skills), a `domain.json` descriptor, and an `orchestrator.md` routing
  prompt. The active pack loads ALONGSIDE the CORE plugin (`session.js`), so a project needs no copies.
  `webapp` is a populated head-start (an issue-driven triage → solution → implement pipeline); `app`
  is an empty learning pack.
- `ui/server/` — Node server + CLI scripts, grouped by area: `core/` (+ `core/http/`),
  `integrations/{hermes,codex}/`, `features/{tasks,promotions,transcripts,skills,autonomous}/`,
  `mcp-tools/` (the in-process `makeXTool` SDK tools), and `cli/` (`setup`, `new`, `doctor`,
  `materialize`, `update-badges`, `release-*`; `promote` lives in `features/promotions/`). New files
  go in the matching area.
- `ui/client/` — browser modules, grouped by area: `core/` (state, transport, dom/render helpers,
  `main.js` entry) and `features/{chat,activity,tasks,approvals,agents,settings,sessions,promotions,
project,autonomous}/`. `ui/lib/` — shared JSDoc typedefs + helpers.
- `ui/server/core/domain-resolver.js` is the **seam**: the spine reads per-domain values (engine,
  inventory, plugin, orchestrator, commands) from the active pack instead of hardcoding them — it
  never branches on the domain name. Godot is NOT a domain here; it stays the exclusive upstream
  product, and we pull only curated, domain-agnostic updates so the engine payload never lands.
- Never put project-specific files in the framework; it points at an external project, reads it in
  place, and the project stays pure.
