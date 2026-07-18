# Token-audit ledger

Running record for `/token-audit`. The hive's session logs are mined a couple at a
time for turns we could make deterministic (a script/tool/hook instead of an agent/LLM call).

**How to use:** read this file first. Skip any session already in `Covered sessions`. After a
run, add the analyzed tags below and append ONE super-brief entry under `Audits`. Keep it
scannable — this is the memory the next run learns from, not a report.

Entry template:

```
### <YYYY-MM-DD> — sessions: <tag>, <tag>
- Offenders: <top 1–3: wasteful pattern + rough token/$ cost>
- Opportunity: <deterministic replacement for an agent/LLM turn> → task <id>
- Process note: <improvement to this command/loop, or "none">
```

## Covered sessions

<!-- one session-tag per line (the part between `session-` and `.ndjson`); newest at the bottom -->

2026-07-11T18-21-47-706Z
2026-07-18T09-42-40-297Z

## Audits (newest first)

### 2026-07-18 — sessions: 07-11T18-21, 07-18T09-42

- Offenders: (1) **raw `gh issue view N --json …,comments` full-thread dumps** — 10–22k chars each; the webapp pipeline (triage→review→implement) re-fetches the SAME issue 3–4×/session as each stage re-reads the thread. 155k chars (~39k tok) total, 69k chars (~17k tok) pure repeat across the 2 sessions. (2) Costliest turns = cache_read on standing orchestrator ctx ($5.5–6.3/turn, 150–360k cr) — inherent, same as upstream forge's finding.
- Opportunity: **TASK (owner:user)** [id `issue-view-incremental`, apply via `/token-audit-fix issue-view-incremental`]: incremental issue view (issuekit `view <n> --since-last` or jq filter) printing compact header + only comments newer than last-seen; MUST emit a countable skip-marker (e.g. `[issuekit] skipped K seen comments (~X chars)`) so a later audit tallies actual savings. Blind dedup is WRONG here — threads mutate between stages. Est ~17k tok/2 sessions. — _mcp**ui**tasks unavailable from terminal session; recorded here for the human._
- Framework-quality hand-off (human): session 07-11 log has **ZERO `result` events** (only assistant/user/system/rate_limit) — its whole spend is invisible to the meter (counted $0/0 turns; covered.cost underreports this run). Logging/usage path gap, not a token opportunity.
- Discarded (checked, not offenders): repeated Reads ×3–4 (edit-driven, files mutate); Agent dispatches 7–8/session (triage/review/implement — judgment work); duplicate `pnpm validate`/`build` (legit re-checks); 5× `grep "§"` (small payloads).
- Process note: add session-health validation to token-history.js — flag sessions lacking `result` events as incomplete, preventing silent cost underreporting.
- Fix-arm note (2026-07-18, `issue-view-incremental` applied): opportunity was mis-scoped as a watermark/"since-last" dedup — each pipeline stage is a FRESH subagent context, so a cross-context watermark would hide content a stage never saw. When scoping a dedup fix, name the CONTEXT BOUNDARY it operates within. Actual fix = stage-contract filtering (developer sees body + latest handoff onward) + compact jq render; Δ 56k chars replayed on the covered corpus. The jq filter is duplicated across 3 pack agents — consumer-local patch on the agnostic webapp pack: UPSTREAM it via arthur0n/xenomoon or it re-conflicts every /sync-framework.
