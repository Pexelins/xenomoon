---
description: Build/verify LexFlow — local production build + smoke (default), or watch the CI deploy
argument-hint: "[ local | smoke | deploy ]"
allowed-tools: Bash
---

Build & verify LexFlow. Default = **local production build** (the test build). LexFlow
**never deploys from a laptop** — production ships via **GitHub Actions on push to
`main`** (`deploy-api.yml` / `deploy-app.yml`, paths-filtered). This command runs the
local build/smoke and, for `deploy`, helps you watch the CI run. It must **never** run
`sam deploy`, `wrangler deploy`, or any manual deploy.

Arguments: `$ARGUMENTS`

## Routing

- **(empty)** or **`local`** → `pnpm build`
  Vite production build → `dist/app/`. Plus `pnpm validate` if not already green this
  session. This is the default for verifying a change builds clean locally. For quick
  iteration the dev servers are enough (`pnpm dev` for api on :3001, `pnpm dev:app` for
  the Vite app) — no rebuild needed.

- **`smoke`** → `pnpm smoke`
  End-to-end check of the data API against the real DB (throwaway user, self-cleans).
  Use after an api/db change to confirm the live data path works.

- **`deploy`** → **do NOT deploy from here.** Confirm with me first, then:
  1. Remind me deploy happens by pushing to `main` (CI does the AWS work; manual deploy
     is forbidden — shared AWS account, OIDC role).
  2. After a push, watch the run:
     `gh run list -R Coghatch-ai/lexflow --branch main --limit 5` and
     `gh run watch -R Coghatch-ai/lexflow <run-id>`.
  3. Report pass/fail of `deploy-api` / `deploy-app`. A failed run made no AWS change
     unless it passed the credentials step — say which step failed.

## Notes

- `pnpm build` + `pnpm smoke` are local and safe. **`deploy` is outward-facing and
  CI-only** — never `sam deploy`/manual; always confirm before pushing `main`.
- Pipeline: `/implement` offers a `/build` after a fix so you can verify it builds, then
  you commit + push to let CI ship it.
- Migrations are separate: `pnpm db:generate` → review SQL → `pnpm db:migrate` (never
  manual SQL, never `db:push`).
