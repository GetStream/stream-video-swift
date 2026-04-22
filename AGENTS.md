# Repository Guidelines

Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repository hosts Stream’s Swift Video/Calling SDK for Apple platforms. It provides the real‑time audio/video client, call state & signaling, and SwiftUI/UI kit components to build 1:1 and group calls with chat integration.

Agents should optimize for media quality, API stability, backwards compatibility, and high test coverage.

### Tech & toolchain
- Language: Swift
- UI frameworks: SwiftUI first; UIKit components may also be present
- Media stack: WebRTC/AVFoundation under the hood
- Primary distribution: Swift Package Manager (SPM)
- Secondary (if applicable): CocoaPods
- Xcode: 15.x or newer (Apple Silicon supported)
- Platforms / deployment targets: Use the values set in Package.swift/podspecs; do not lower without approval
- CI: GitHub Actions (assume PR validation for build + tests + lint)
- Apple docs helper: Use https://sosumi.ai/ (MCP or direct) for up-to-date
  Apple platform APIs, Swift/Objective-C references, and UI design guidance.
- Xcode MCP: Agents may use the Xcode MCP to build, test, and interact with
  apps on simulators and real devices. See
  `https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode`.

## Project Structure & Module Organization
- Root: `Package.swift` (SPM entry).
- Sources: `Sources/StreamVideo/`, `Sources/StreamVideoSwiftUI/`, `Sources/StreamVideoUIKit/`.
- Tests: `StreamVideoTests/`, `StreamVideoSwiftUITests/`, `StreamVideoUIKitTests/` .
- Demos: `DemoApp/` and `DemoAppUIKit` samples.
- Documentation tests: `DocumentationTests/DocumentationTests/`.
- Mirror nearby module patterns; keep file names aligned with the primary type (e.g., `CallViewModel.swift`).

### New files & target membership
- When creating new source or resource files, add them to the correct Xcode target(s). Update the project (e.g. project.pbxproj) so each new file is included in the appropriate target's "Compile Sources" (or "Copy Bundle Resources" for assets). Match the target(s) used by sibling files in the same directory (e.g. Sources/StreamVideo/ → StreamVideo; Sources/StreamVideoSwiftUI/ → StreamVideoSwiftUI; Sources/StreamVideoUIKit/ → StreamVideoUIKit; Tests/StreamVideoTests/ → StreamVideoTests; Tests/StreamVideoSwiftUITests/ → StreamVideoSwiftUITests; Tests/StreamVideoUIKitTests/ → StreamVideoUIKitTests). Omitting target membership will cause build failures or unused files.

## Build, Test, and Development Commands
- Open in Xcode 15+ via `Package.swift` and build for an iOS Simulator (e.g., iPhone 15).
- Build (CLI):
  - `xcodebuild -scheme StreamVideo -destination 'platform=iOS Simulator,name=iPhone 15' -configuration Debug build`
- Tests (CLI):
  - `bundle exec fastlane test`
  - `bundle exec fastlane test_swiftui`
  - `bundle exec fastlane test_uikit`
- Lint: `bundle exec fastlane run_swift_format strict:true` (respect `fastlane/Fastfile`).

### Public API & SemVer
- Follow semantic versioning across public modules.
- Any public API change must include updated docs and migration notes.
- Avoid source‑breaking changes; if unavoidable, deprecate first with a transition path.

### Performance & quality
  • Avoid heavy work on the main thread; keep rendering/state updates efficient.
  • Monitor frame rate, bitrate adaptation, and CPU/GPU usage; prefer hardware‑accelerated codecs when available.
  • Be careful with retain cycles in capture/render pipelines; audit async capture lists.
  • Consider adaptive UI for low‑bandwidth scenarios (thumbnail modes, audio‑only fallback).

## Coding Style & Naming Conventions
- Swift (SPM-first). Indentation: 4 spaces; avoid trailing whitespace.
- Naming: Types/protocols `UpperCamelCase`; methods/variables `lowerCamelCase`; constants `lowerCamelCase`.
- Structure large files with `// MARK:` and add `///` docs for public APIs.
- Do not add new third-party deps without discussion.

## Testing Guidelines
- Framework: XCTest with async/await and expectations; avoid time-based sleeps.
- Use existing `Mockable` protocol to mock dependencies.
- Place tests under the corresponding `…Tests` target and mirror folder structure.
- Name new test files with the pattern `…_Tests.swift`.
- Name new test methods with the pattern `test_<given>_<when>_<then>_()`. The words given, when, then should be omitted.
- Keep tests as simple as possible. Keep their scope as small as possible.
- If you see a pattern in test cases, group the testing logic in a method and use this in the test cases that need it.
- Use `subject` as the name of the subject under test.
- Prefer instance properties that are explicitly unwrapped which you nullify on tearDown.
- Add/extend tests for call lifecycle, state/view models, media toggles, and SwiftUI layout logic (use fakes/mocks).
- Run both `StreamVideo` and `StreamVideoSwiftUI` tests locally; keep/raise coverage.
- Only add tests for .swift files.
- Do not test private methods or add test-only hooks to expose them; test through public or internal behavior instead.
- Integration tests in `StreamVideoTests/IntegrationTests/Call_IntegrationTests`:
  - Purpose: end-to-end call-path validation using real Stream API responses.
  - Layout:
    - `Call_IntegrationTests.swift`: scenarios.
    - `Components/Call_IntegrationTests+CallFlow.swift`: flow DSL.
    - `Components/Call_IntegrationTests+Assertions.swift`: async and eventual assertions.
    - `Components/Helpers/*`: auth, client setup, permissions, users, configuration.
  - Base flow:
    - Keep `private var helpers: Call_IntegrationTests.Helpers! = .init()`.
    - Build each scenario from `helpers.callFlow(...)`.
    - Chain with `.perform`, `.performWithoutValueOverride`,
      `.performWithErrorExpectation`, `.map`, `.tryMap`, `.assert`,
      `.assertEventually`, and actor-specific variants.
  - `defaultTimeout` is defined in `StreamVideoTests/TestUtils/AssertAsync.swift` and is used
    by eventual assertions.
  - Assertions:
    - Use `.assert` for immediate checks.
    - Use `.assertEventually` for event/state propagation and async streams.
    - For expected failures, use `performWithErrorExpectation`,
      cast through `APIError`, then check `code`/`message`.
  - IDs and payloads:
    - Use `String.unique` for call IDs, users, call types, and random values.
    - Use `helpers.users.knownUser*` only when test logic requires stable identities.
  - Permissions:
    - Use `helpers.permissions.setMicrophonePermission(...)` and
      `setCameraPermission(...)` for permission-gated flow setup.
  - Concurrency:
    - When testing multi-participant flows, use separate `callFlow` instances and
      `withThrowingTaskGroup` to keep participant behavior explicit.
    - For `memberIds` that use generated users (`String.unique`), first create each
      participant `callFlow` first so their users are initialized before call creation:
      - `let user1Flow = try await helpers.callFlow(..., userId: user1)`
      - `let user2Flow = try await helpers.callFlow(..., userId: user2)`
      - `let callFlowAfterCreate = try await user1Flow.perform { try await $0.call.create(memberIds: [user1, user2]) }`
    - Prefer `.perform { ... }` for operations when the returned value should stay in
      the chain for downstream assertions; use
      `.performWithoutValueOverride` only when the returned value is intentionally
      discarded.
  - Event streams:
    - Prefer `subscribe(for:)` + `.assertEventually` for event assertions.
    - For end-to-end teardown coverage, you can also assert `call.streamVideo.state.activeCall == nil`
      to confirm the participant instance has left when the call is ended by creator.
    - Avoid arbitrary fixed sleeps except when explicitly stabilizing UI/test timing.
  - Cleanup:
    - Keep `helpers.dismantle()` in async `tearDown`.
    - This disconnects clients and waits for call termination/audiostore cleanup.
  - Environment/auth:
    - `TestsAuthenticationProvider` calls `https://pronto.getstream.io/api/auth/create-token`.
    - Default environment is `pronto`.
    - Use `environment: "demo"` for livestream and audio room scenarios that are
      fixture-backed.
  - Execution:
    - Target only this suite:
      `xcodebuild -project StreamVideo.xcodeproj -scheme StreamVideo -testPlan StreamVideo test -only-testing:StreamVideoTests/Call_IntegrationTests`
    - Full suite remains `bundle exec fastlane test`.

## Comments
- Use docC for non-private APIs.
- Use `///` for doc comments.
- Use `// MARK:` to group code.
- Use `// MARK: - <Group Name>` to group code.
- Use 80 characters as the maximum line length.
- Keep comments as simple as possible.
- Avoid stating the obvious e.g. `var isActive: Bool // A variable that indicates if the view is active`.
- Read around the APIs you are documenting and add context to make the comments more useful.

### Compatibility & dependencies
  • Maintain compatibility with deployment targets in Package.swift.
  • Avoid adding new third‑party deps without discussion.
  • Validate SPM integration in a fresh sample app when changing module boundaries.

## Commit & Pull Request Guidelines
- Commits: small, focused, imperative subject lines ("Fix crash in renderer").
- Before opening a PR: build all affected schemes, run tests, `bundle exec fastlane run_swift_format strict:true`.
- PRs must include: clear description, linked issues, CHANGELOG updates for user-visible changes, and screenshots/screencasts for UI changes. No new warnings.

## Security & Configuration Tips
- Never commit API keys or user data; use env/xcconfig with placeholders.
- Redact tokens in logs; use TLS; respect backend-provided TURN/ICE config.
- Shared Codex worktree config lives in `.codex/environments/environment.toml`
  and `.codex/scripts/*.sh`; keep those files repo-relative and free of secrets.
- Do not hardcode tokens, usernames, emails, local absolute paths, or other
  machine-specific values in tracked `.codex` files.
- Run `./Scripts/check_codex_shared_config.sh` after updating tracked `.codex`
  files.

### Media & permissions checklist
- Request & handle camera and microphone permissions gracefully.
- Handle foreground/background transitions; pause/resume capture appropriately.
- Support device rotation and multi‑orientation previews.
- Validate CallKit integration (if present) and ensure correct audio session categories/modes.
- Ensure PushKit/VoIP notifications are optional and documented if supported.
