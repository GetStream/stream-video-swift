---
name: review
description: >-
  Review Stream Video Swift changes or check PR comments against source.
  Use for local diffs, pull requests, and checks before a code PR handoff.
---

# Review

Apply [shared rules](../../AGENTS.md). Review alone does not authorize fixes.

## Workflow

1. Record the scope, candidate revision, and actual base revision.
   Include working changes for local review. Read the current base and head for a PR.
2. List every changed file. Read each diff with its callers and tests.
   Include new files, deleted files, resources, and project membership.
   Record skipped files with reasons. Distinguish existing defects from
   regressions introduced by the candidate.
3. Check behavior, API compatibility, ownership, concurrency, and cleanup.
   Follow stale completion, cancellation, reconnect, and teardown paths
   where affected. Prefer the smallest complete fix over added abstractions.
   Check review comments independently against the current source.
   Check affected contracts against [related repositories](../../AGENTS.md#related-repositories).
   Check the [comment rules](../../AGENTS.md#comments), [test design](../test/SKILL.md#test-design),
   [repeated-run evidence](../test/SKILL.md#test-reliability), and [binary size](../development/SKILL.md#binary-size).
   For WebRTC changes, check the [integration rules](../development/references/webrtc.md).
   For public interface changes, follow the [documentation decision](../development/SKILL.md#public-interface-documentation).
   Check [changelog rules](../development/SKILL.md#changelog) for qualifying changes and every edited entry.
   Report missing updates or validation.
4. Run each requested review workflow when available.
   Use a separate reviewer for an independent pass when available.
   Report unavailable workflows and manual coverage accurately.
   A file-selection command alone does not complete a review.
5. Report actionable findings by severity with file and line references.
   Explain the trigger, impact, and correction. Include coverage and
   validation limits. If none remain, say so without implying runtime proof.

## Open Code Review

For code reviews, use host-agent delegation when `ocr` is available.
Use OCR-managed model execution only when explicitly requested and configured.
For local changes, run `ocr delegate preview --format json`.
For a PR, add `--from <actual-base-ref> --to <candidate-sha>`.
Resolve those placeholders before execution.

Fetch rules with `ocr delegate rule --format json <paths...>`.
Read the selected files and apply the rules yourself.
Manually cover exclusions, including tests and test plans.
If OCR is unavailable, disclose the limit and complete the manual review.
Delegation requires no separate model provider.

## Handoff

### PR descriptions

For every PR description you create or edit, read the current [GitHub template](../../.github/PULL_REQUEST_TEMPLATE.md).
Preserve its headings, order, required sections, and checklist wording. Keep checklist states truthful.
Keep the description focused on the problem, fix, and manual testing steps:

- Use Goal for the problem and its user impact.
- Use Summary for the fix and resulting behavior.
- Use Implementation only for technical details needed to understand the fix or a relevant design decision.
  Exclude implementation-process details, such as work chronology, TDD steps, agent activity, and review workflow.
- Use Manual Testing Notes for prerequisites, numbered actions, and expected results.
  Describe steps a reviewer can follow. Do not imply that unperformed manual testing passed.
  If manual testing does not apply, state that briefly.
- Include relevant issue links and visual evidence in their template sections.

Exclude local validation reports: build commands, test counts, pass/fail logs, toolchain details, and local environment failures.
Report validation evidence and pending checks in the chat handoff, separate from the PR description.
Before publication or update, compare the complete description with the current template and these content rules.
Keep the PR draft while required checks or acceptance remain pending.
