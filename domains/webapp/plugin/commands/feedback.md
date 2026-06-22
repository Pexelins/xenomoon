---
description: Turn raw feedback notes into a well-formed GitHub issue (optionally triage it)
argument-hint: "<freeform notes> [--triage]"
allowed-tools: Bash, Agent
---

Intake trigger: convert raw feedback (from a tester or from me) into a clean,
triage-ready GitHub issue on `Coghatch-ai/lexflow`.

Raw notes: `$ARGUMENTS`

## Steps

1. **Set identity:** `gh auth switch --user arthur-coghatch` (stop and tell me if it fails).

2. **Restructure the notes** into a clean issue. Don't invent facts — only use what's
   in the notes; leave a field out if it isn't there.
   - **Title:** short, specific, imperative-ish (e.g. "Stats page shows blank after answering a session").
   - **Body** (markdown):

     ```
     **What happened:** …
     **Expected:** …            (only if implied)
     **Steps to reproduce:**    (only if given)
     1. …
     **Account / area:** …      (e.g. signed-in student, OAB questions, stats)
     **Env:** …                 (prod my.probius.app / local dev — only if given)

     > Filed via /feedback from raw notes.
     ```

   - **Label:** `bug` if it describes something broken; otherwise `feedback`.
   - If the notes clearly contain **several distinct problems**, create **one issue per
     problem** rather than a single muddled issue.

3. **Create the issue(s):**
   `gh issue create -R Coghatch-ai/lexflow --title "<title>" --body-file /tmp/feedback-<n>.md --label "<bug|feedback>"`
   Echo each new issue's number and URL.

4. **Optional chain:** if `--triage` is present in the args, immediately spawn the
   `bug-triage` agent (Agent tool, `subagent_type: "bug-triage"`) for each newly
   created issue, then summarize its findings. Otherwise, suggest I run `/triage <#>`
   when I want it investigated.

## Notes

- Keep titles/bodies faithful to the reporter — this is clean-up and structuring, not
  embellishment.
- This command only files issues; the `bug-triage` agent is what investigates code.
