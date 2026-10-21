---
name: development
description: >-
  Implement or fix Stream Video Swift SDK, UI, or demo behavior.
  Use test-driven development for features, bug fixes, and refactors.
---

# Development

Apply [shared rules](../../AGENTS.md).

## TDD gate

Use test-driven development (TDD) for every code change.
Write the behavior test first and observe its expected failure before implementing the change.
For new APIs, add only declarations needed to compile the written test before observing that failure.
For behavior-preserving refactors, establish a passing baseline and add missing coverage before production edits.
Skipped tests, unrelated compilation errors, and infrastructure failures do not satisfy the gate.
If the runner or required environment is unavailable, stop before production edits and report the blocker.
For prose-only changes, use structural and link checks.

## Workflow

1. Define expected behavior and affected callers. Read the owning type.
   Check shared contracts and dependencies against [related repositories](../../AGENTS.md#related-repositories).
   For WebRTC APIs, signaling, media, threading, or teardown, read [Working with WebRTC](references/webrtc.md).
2. Complete the TDD gate with the smallest test at the responsible component.
   Follow the [test design rules](../test/SKILL.md#test-design).
3. Make the smallest change that passes the test.
   Rerun the same test without weakening its assertions.
   Reuse existing helpers and dependencies. Fix the shared owner once.
   Check cancellation, stale completions, teardown, and error paths when
   asynchronous state changes.
4. Update affected callers, behavior tests, and target membership.
   Place custom request behavior in `Utils/`, outside `OpenApi/`, so API
   regeneration cannot remove it. Prefer existing middleware hooks.
   Change generator inputs or templates when the generated request contract
   itself must change.
   Match sibling membership in `StreamVideo.xcodeproj/project.pbxproj`.
   Check `Package.swift` for package resources and module changes.
   Follow the [documentation decision](#public-interface-documentation) for public interface changes.
5. Refactor only while the relevant tests pass. Rerun them after refactoring.
   Use the [test skill](../test/SKILL.md) for repeated runs and broader checks.

## Public interface documentation

For changes to public symbols, signatures, defaults, or documented behavior, ask whether to update documentation and documentation tests together.
Identify affected DocC comments, guides, migration notes, and `DocumentationTests/` examples. Explain why updates are likely required.
Use the [repository access procedure](../../AGENTS.md#related-repositories) when external guides need the private docs repository.
Reuse explicit instructions already given for this task.
With approval, update the material and follow [documentation tests](../test/SKILL.md#documentation-tests).
Otherwise, report pending updates and continue independent work, including TDD checks.

## Changelog

Update `CHANGELOG.md` only for added or updated public interfaces or bugs fixed in this change.
Internal refactors, tests, tooling, and documentation alone do not qualify.
Place every entry under `# Upcoming`, before the first released version heading.
Never add or edit entries under a released version.
Include a real, relevant URL in every entry, preferably its pull request or issue.
If no URL is available, ask the user and leave the entry pending. Never invent links or use placeholders.
Describe the user-visible change briefly.

## Binary size

Avoid unnecessary binary growth from code, dependencies, or resources. Keep test assets outside shipping targets.
When size can change, compare Release artifacts from the same SDK target or representative consumer app.
Match architecture, toolchain, optimization, stripping, and packaging.
Report binary and resource sizes separately: baseline, candidate, and delta in bytes and percent.
Explain necessary growth and alternatives. Preserve behavior, compatibility, security, and accessibility.
If measurement cannot run, report size impact as unverified.

## Repository conventions

- Use four spaces and nearby naming patterns. Use `// MARK: - Group` for sections.
- Preserve deployment targets, media quality, and public API compatibility.
  Follow semantic versioning and deprecate breaking APIs with a transition path.
  Discuss new dependencies or breaking changes before implementation.

## Result

Include the failing test and its passing result after the change.
For behavior-preserving refactors, report baseline and final test results.
