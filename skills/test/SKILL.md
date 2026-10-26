---
name: test
description: >-
  Add or run Stream Video Swift tests and diagnose local or CI failures.
  Use for regressions, test isolation, snapshots, and live-call validation.
---

# Test

Apply [shared rules](../../AGENTS.md).
For real API scenarios, read [integration tests](references/integration-tests.md).

## Workflow

1. Choose the behavior to prove. Check the scheme, test plan, exclusions,
   available destination, and credentials required by that scenario.
   Read `fastlane/Fastfile` before choosing a lane.
   Check client/server expectations against [related repositories](../../AGENTS.md#related-repositories).
2. Follow the [development TDD gate](../development/SKILL.md#tdd-gate).
   Preserve event ordering and concurrency. Assert expected effects and forbidden side effects separately.
3. Use XCTest and existing `Mockable` helpers. Name the tested instance
   `subject`. Prefer unwrapped fixture properties that teardown clears.
   Await cleanup of tasks, observers, audio, and shared injected state.
   Prefer expectations or eventual assertions over fixed sleeps.
4. Run focused tests first. For code changes, also run the configured
   StreamVideo and StreamVideoSwiftUI suites. Include UIKit when affected.
   Check [test reliability](#test-reliability) for added or changed tests.
   Check parallel execution when shared state or isolation changes.
   Before a code PR handoff, build affected schemes and run strict formatting for Swift changes.
   Introduce no new warnings. Check a fresh SPM integration when module boundaries change.
   Inspect visual changes directly and include screenshots in UI PRs.
5. Read the result bundle and logs. Record counts, exclusions, retries,
   destination, toolchain, and revision. Compare unexplained failures with
   the actual base under equivalent conditions.

## Test entry points

Use these commands when compatible Xcode, Ruby, Bundler, and project gems are available.
Select an available simulator with `device:` when needed.
Otherwise, use Xcode or `xcodebuild` with equivalent settings.

| Scope | Command |
| --- | --- |
| SDK | `bundle exec fastlane test` |
| SwiftUI | `bundle exec fastlane test_swiftui` |
| UIKit | `bundle exec fastlane test_uikit` |
| Demo UI end-to-end | `bundle exec fastlane test_e2e` |
| Swift formatting | `bundle exec fastlane run_swift_format strict:true` |

The formatting lane can edit files. Inspect its implementation and resulting diff.

For focused execution, use `xcodebuild` with `-only-testing:Target/TestCase`.
Select the project, scheme, test plan, and destination from current metadata.
Preserve the command's exit status when filtering its output.
Fastlane can skip suites or retry failures. Check actual test execution.

### CI automation

Check workflow expressions with `actionlint` and shell scripts with `shellcheck`.
Use `RUNNER_ENVIRONMENT` in shell scripts and `runner.environment` in action conditions.
Check the latest action releases at their source, including their minimum runner version.
Verify major references before use. Some actions use a branch or only publish exact tags.
A local check does not prove a GitHub Actions run or a Slack delivery.
Check simulator availability before installing runtimes or creating devices.
Match the requested runtime and device model. Preserve existing simulator data.

## Documentation tests

After approval through the [documentation decision](../development/SKILL.md#public-interface-documentation),
inspect the project and scheme under `DocumentationTests/`.
Update and compile affected examples. Run executable tests if the scheme provides them.
Report compilation, executed tests, and unavailable checks separately.

## Test reliability

Require consistent passes from new and changed tests.
After the first pass, check supported flags with `xcodebuild -help`.
Add `-test-iterations 10 -run-tests-until-failure` to the focused command.
This requests ten iterations, stopping at the first failure. Increase the count for rare failures.
Use the same process by default to expose leaked state between iterations.
Report any scenario that requires a fresh process for each iteration.
See Apple's [test repetition guidance](https://developer.apple.com/videos/play/wwdc2021/10296/).

Check that each selected test executed all requested iterations without failure.
Do not use `-retry-tests-on-failure` as evidence of stability.
Resolve failures or cancellations before repeating the full check.
Report the command, iteration counts, failures, and process mode. Mark unavailable repetition as unverified.
Passing repetitions provide evidence only for the tested conditions.

## Test design

- Add tests for Swift behavior through public or internal APIs.
  Do not expose private methods for tests.
- Use `Type_Tests.swift` and `test_scenario_action_result_()` names.
- Centralize setup reused across test functions or test cases in existing fixtures
  or small named helpers. Keep scenario-specific inputs and assertions visible.
  Keep test bodies short and readable. Split unrelated scenarios into separate tests.
  Avoid large helpers with flags that hide the behavior under test.
- Use a distinct observable effect to prove timer cancellation.
  Duplicate state assignments can hide a timer that still fires.
- Change snapshot references only for an intended visual change.
  Inspect visual differences before accepting new references.

## Result

In the chat handoff, separate assertion failures, infrastructure failures, and canceled tests.
State untested live behavior, including CallKit, audible ringing, and media.
For PR descriptions, follow the [template and content rules](../review/SKILL.md#pr-descriptions).
Use Manual Testing Notes for reproducible manual steps and expected results, not local validation reports.
