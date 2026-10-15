---
name: release
description: >-
  Assess or prepare a Stream Video Swift release or WebRTC dependency update.
  Use for release readiness and explicitly authorized publication steps.
---

# Release

Apply [shared rules](../../AGENTS.md).

## Workflow

1. Resolve the last shipped version and candidate to exact revisions.
   Check the intended version and requested stage.
   Read `fastlane/Fastfile`, `Gemfile`, and relevant release workflows before
   executing automation. Check imported actions for hidden side effects.
2. Review the full diff with the [review skill](../review/SKILL.md), including API compatibility, documentation, and changelog checks.
   Check package metadata, dependency versions, and migrations against [related repositories](../../AGENTS.md#related-repositories).
3. Use the [test skill](../test/SKILL.md) for validation.
   Compare shipped binary and resource sizes with the previous release using
   the [binary size procedure](../development/SKILL.md#binary-size).
4. Define manual QA for each changed runtime feature and high-risk path.
   Include prerequisites, actions, expected behavior, and failure signals.
   Separate established regressions from suspected risks.
5. Report readiness with exact revisions and unresolved gates.
   Check remote results after each authorized publication step.

## Repository automation

| Workflow | Purpose and boundary |
| --- | --- |
| `release-start.yml` | Triggers integration testing and runs `release` to create a release PR. |
| `release-merge.yml` | Runs `merge_release` to merge the release and start publication. |
| `release-publish.yml` | Runs `publish_release`, triggers integration tests, and runs `merge_main` in a separate job. |

Workflow paths are relative to `.github/workflows/`.
Lane names refer to `fastlane/Fastfile`.
These workflows require authorization for their PR, merge, or publication effects. They are not preview commands.
Running a lane alone does not execute the workflow's other steps or jobs.

## Local WebRTC update

Check the requested tag in the Swift wrapper repository from `Package.swift`.
A native WebRTC release alone does not prove that the wrapper tag exists.
If the wrapper tag is unavailable, stop the update and report the blocker.

When compatible Bundler dependencies exist, use `update_webrtc` with `skip_pr:true` to avoid creating a PR.
Otherwise, inspect the lane's transformations before a manual edit. Preserve each file's version format.
Check matching versions in `Package.swift`, `project.pbxproj`, and
`Sources/StreamVideo/Generated/SystemEnvironment+Version.swift`.

## Result

Report preparation, review, tests, manual QA, and publication separately.
For demo distribution, distinguish upload, processing, and tester availability.
Do not repeat an uncertain publication until checking whether it succeeded.
