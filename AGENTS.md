# Repository guidance

This repository contains Stream's Swift Video SDK and sample apps.
Use the [repository map](README.md#working-in-this-repository) to locate modules and tools.
These shared rules apply to every workflow below.

## Select a workflow

Follow [optional skill setup](skills/setup.md) when work starts.
Read only the relevant skills. Open `SKILL.md` directly if automatic discovery is unavailable.
These workflows require no agent plugin. Resolve command paths from the repository root.

| Task | Skill |
| --- | --- |
| Implement or fix behavior | [development](skills/development/SKILL.md) |
| Add tests, run checks, or diagnose CI | [test](skills/test/SKILL.md) |
| Review changes or PR comments | [review](skills/review/SKILL.md) |
| Assess or prepare a release | [release](skills/release/SKILL.md) |
| Measure performance, size, or hangs | [profile](skills/profile/SKILL.md) |

## Start with current evidence

1. Check the checkout, revision, requested scope, and working changes. Preserve unrelated work.
2. Read relevant source and automation. Use `Package.swift` for package requirements,
   `StreamVideo.xcodeproj` for targets, and `fastlane/Fastfile` and `.github/` for automation.
3. Discover tools, versions, destinations, and required access before use.
   Do not assume a toolchain, simulator, plugin, sibling checkout, or account exists.
   Use available indexes and search tools. Report unavailable capabilities precisely.
4. Inspect setup commands before execution. Stay within authorization for installations,
   global settings, and live services. Check current Apple documentation when API contracts are uncertain.

## Related repositories

Use related repositories to investigate shared behavior and dependencies.
Compare affected contracts, events, defaults, and lifecycle assumptions for alignment.

| Repository | Use for |
| --- | --- |
| [JavaScript SDK](https://github.com/GetStream/stream-video-js) | Client behavior, API alignment, and implementation references. |
| [Android SDK](https://github.com/GetStream/stream-video-android) | Client behavior, API alignment, and platform differences. |
| [WebRTC fork](https://github.com/GetStream/webrtc) | Native media behavior, fixes, and performance investigations. |
| [Swift Core](https://github.com/GetStream/stream-core-swift) | Shared Swift functionality and dependency behavior. |
| [Swift WebRTC wrapper](https://github.com/GetStream/stream-video-swift-webrtc) | Swift integration, packaging, and native version mapping. |

Use an available checkout or authorized remote access. Record relevant revisions or tags.
Explain intentional platform differences before proposing alignment changes. Keep edits within the task's repository scope.

The SFU implementation and documentation source repositories are private.
When the task needs either repository, prompt the user for its URL or local path and required access.
Reuse details already supplied for the task. Do not guess private repository locations.
If access remains unavailable, report the missing comparison and continue independent work.

## Shared boundaries

- Apply the [TDD gate](skills/development/SKILL.md#tdd-gate) to code edits from every workflow.
  Complete [tests](skills/test/SKILL.md) and [review](skills/review/SKILL.md) before a code PR handoff.
- Keep secrets, personal paths, device IDs, and raw private logs out of tracked files.
  Use local credentials, redact evidence, use TLS, and respect backend TURN/ICE configuration.
- Commit, push, publish, merge, or send messages only with explicit authorization.
  When authorized, use focused commits with imperative subjects.

## Comments

Keep comments light, short, clear, and direct, with lines of at most 80 characters.
Explain non-obvious reasons or constraints. Avoid repeating the code.
Use DocC (`///`) for public and internal API documentation.

## Communicate clearly

Apply available `i-have-adhd` for structure and `asd-ste100` for clear wording in every user-facing message.
This includes progress, questions, explanations, and final reports.
Check each message before sending it. Respect user requests to change style.
Apply available `ponytail` guidance to keep implementation changes small.

If helpers are unavailable or declined, use these defaults:
Lead with the result or next action. Number bounded steps and limit visible lists to five items.
Use short sentences, consistent terms, and one instruction per sentence. Preserve conditions and uncertainty.
Report changes, completed checks, and remaining limits separately.
Distinguish builds, tests, and observed runtime behavior. Never present old runs or retry passes as broader acceptance.

## Maintain the skills

Update the affected skill when verified evidence or a user correction exposes missing or incorrect guidance.
Do this during the task without waiting for another request.
For read-only tasks, propose the exact correction and target path instead.
Check for missed updates before the final response.

1. Check the lesson against source, a repeatable check, or observed behavior.
2. Amend the existing instruction. Remove obsolete or duplicate guidance.
3. Keep lessons portable. Exclude temporary failures, private history, and machine-specific settings.
   Keep core steps in `SKILL.md` and conditional detail in a linked reference.
4. Check frontmatter, relative links, and command accuracy. Report the changed path and reason.

If no durable lesson emerged, leave the skills unchanged.
