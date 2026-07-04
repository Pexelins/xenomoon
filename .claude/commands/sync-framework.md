---
description: Pull framework updates DOWN into this consumer repo from upstream (arthur0n/xenomoon). Human-gated and analysis-driven — review incoming commits, merge on a throwaway sync branch, resolve each conflict by judgment (spine/pack → theirs; identity color/branding → OURS), then run the agnostic gate + validate. Never pushes, never touches the trunk.
argument-hint: "[--from <remote>] [--branch <branch>] [--project <name>]"
allowed-tools: Bash, Read, Edit
model: opus
---

# Sync framework — ride the framework's updates without re-forking it

> **Terminal-CLI mirror** of `plugin/commands/sync-framework.md` (the framework's plugin
> command, which only loads inside the web-app's SDK sessions). This copy lives in
> `.claude/commands/` so it runs as `/sync-framework` in interactive Claude Code. It is kept
> identical to the plugin command except: (1) the gate path is repo-relative, and (2) the
> **identity** conflict rule is resolved as OURS per this repo's `.claude/CLAUDE.md` bronze-
> identity rule (the stock plugin command, written from the framework's own vantage, resolves
> identity as theirs).

The framework (`arthur0n/xenomoon`) moves all the time; this consumer rides those updates
with this command. The mechanical parts are deterministic (fetch, branch, the leakage gate,
validate) — but the **merge is analysis, not a recipe**: you decide, conflict by conflict,
what is the agnostic framework's to win and what is a genuine local fix or identity choice to
keep. That judgment is why this is a command and not a script. See `docs/whitelabel/DOWNSTREAM.md`.

## The one rule the analysis serves

The framework spine + domain packs are **agnostic** and the framework owns them — a consumer
must not fork them into a project-specific variant. A project's facts (stack, conventions,
commands, tenancy) live in the **project's own `CLAUDE.md`**, never baked into `domains/` or
the spine. So on conflict the framework's version (theirs) almost always wins; the exceptions
are (a) a real spine bug you fixed locally and mean to upstream, and (b) this repo's committed
**bronze identity**, which upstream must never be allowed to revert.

## Arguments

Parse `$ARGUMENTS`: `--from <remote>` (the framework remote, default `upstream`),
`--branch <branch>` (default `main`), `--project <name>` (the bound project, e.g. `lexflow` —
feeds the gate's hardcoding tripwire). Let `REF = <remote>/<branch>`.

## Steps

1. **Preflight (deterministic — stop if it fails).** Confirm a clean tree
   (`rtk git status --porcelain` empty; generated `graphify-out/` is gitignored so it won't show;
   if anything else shows, stop and tell the user to commit/stash).
   Resolve the remote: `rtk git remote get-url <remote>`. It MUST be the framework
   (`arthur0n/xenomoon`) — if it's a `xenodot-forge` URL (the godot source) or this repo's
   own origin, stop: that's the wrong direction. If the remote is missing, tell the user to
   add it (`git remote add upstream https://github.com/arthur0n/xenomoon.git`) and stop.

2. **Fetch + review the incoming work (ANALYZE — this is a checkpoint, not a rubber stamp).**
   `rtk git fetch <remote> <branch>`, then `rtk git log --oneline --reverse HEAD..$REF`.
   If empty → already current, say so and stop. Otherwise **read** the commit list and skim
   `rtk git diff --stat HEAD..$REF`: what's landing — spine refactor, new CORE skill/hook,
   domain-pack change, identity? Summarize it for the human before you touch anything. If
   anything looks like it would regress this consumer, name it now.

3. **Branch — never touch the trunk.** `rtk git switch -C sync-framework-<branch>`. All work
   happens here; the trunk is only updated by the human after they review this branch.

4. **Merge, then resolve each conflict by JUDGMENT (the core analysis step).**
   `rtk git merge --no-ff $REF`. If it conflicts, do **not** blanket `-X theirs` — list the
   unmerged files (`rtk git diff --name-only --diff-filter=U`) and decide each:
   - **Spine** (`ui/**` logic), **domain pack** (`domains/<name>/**`), **CORE plugin**
     (`plugin/**`) → the framework wins: `rtk git checkout --theirs -- <file>` then
     `rtk git add <file>`.
   - **Identity** (`ui/index.html`, `ui/agent-ui.css`, `assets/` emblem/logo/favicon) → keep
     the bronze "lunar" identity per `.claude/CLAUDE.md`: take upstream's **behavior/structure**
     only, and resolve every **color / palette / branding / emblem / favicon / brand-word** hunk
     as **OURS** (palette tokens incl. `--green` = Moon Gold `#d5bc70`, `--accent` = Lunar Bronze,
     brand word `XenomoonForge`). NEVER let a sync reintroduce upstream's green alien-head emblem
     or alien-green palette. Runbook: `docs/whitelabel/SEAMS.md`. After resolving, spot-check the
     merged tree: `rtk git grep -niE 'alien' -- ui` (must be empty) and confirm `--green` is
     unchanged from HEAD.
   - **A genuine local framework bug-fix** you intend to keep (e.g. an ENOENT guard the
     framework lacks) → keep ours for that hunk, and note it so it gets filed upstream — a
     consumer-local patch that never goes up will re-conflict every sync.
   - Anything **project-specific** that crept into a tracked framework file → strip it; it
     belongs in the project's own `CLAUDE.md`.
     Show the human the conflict list and your per-file decision, then `rtk git commit` to
     finish the merge.

5. **Agnostic gate (deterministic — run it, read the result, don't eyeball it).**
   `bash scripts/check-spine-agnostic.sh` (add `--project <name>` if given). It exits non-zero
   and prints offenders if game/godot identity or the project's name leaked into the spine. If
   it fails, that's a resolution mistake from step 4 — fix those files (take theirs / remove the
   project string) and re-run until clean. Never route around it.

6. **Validate (deterministic — must pass).** `rtk npm run validate`. If it fails, fix what the
   merge broke before handing off.

7. **Report + hand off (STOP — never push, never fast-forward the trunk).** Summarize: how
   many commits pulled, which conflicts and how you resolved each, gate = clean, validate =
   green. Tell the human the `sync-framework-<branch>` branch is ready and THEY merge it into
   the trunk and publish. This command's authority ends at the sync branch.

## Never

- **Never push** and never fast-forward/merge into the trunk branch — your output is the sync
  branch for the human to review. Publishing is theirs.
- **Never blanket `-X theirs`/`-X ours`.** Resolve conflicts file-by-file with visible
  reasoning — that analysis is the whole point of using a command here.
- **Never resolve a spine/pack conflict as OURS** to preserve a consumer's flavor — that
  re-forks the agnostic framework. Theirs wins; project facts live in the project's CLAUDE.md.
  (Identity color/branding is the deliberate exception above — OURS by the CLAUDE.md rule.)
- **Never silence the gate** (no skipping `check-spine-agnostic.sh`, no `--no-validate` hack) —
  if it fails, scrub the leak.
- **Never bake project specifics into a tracked framework file.**
