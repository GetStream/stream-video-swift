# Repository Guidelines

Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repository hosts Stream’s Swift Video SDK for Apple platforms. It provides the real‑time audio/video client, call state & signaling, and SwiftUI/UIKit components to build 1:1 and group calls with chat integration.

The current development line is **v2** (SDK 2.0). Feature work on this branch targets the `v2` base, not `develop`. v2 is allowed to break public UI configuration where the design-token migration requires it; do not break the calling/media client casually.

Agents should optimize for media quality, API stability, backwards compatibility of the call path, and high test coverage.

## v2 design system

v2 introduces a **shared design-token system** so Chat and Video can reskin from one source. Shared color, layout, and typography tokens live in **StreamCoreUI** (`DesignSystemTokens`). Each product SDK owns its own appearance type and its own product tokens. Icons and images stay on each SDK for now.

### Types and ownership

- **`DesignSystemTokens`** (Core, class): `tokens.colors` (semantic colors plus `tokens.colors.palette` for brand/chrome ramps), `tokens.layout` (spacing, radii, strokes, elevations), and `tokens.fonts` (shared SwiftUI typography). Override color ramps **before the first read**. Colors stay on UIKit `UIColor`; fonts stay on SwiftUI `Font`. UIKit `UIFont` faces stay on product UIKit SDKs (for example StreamChatUI).
- **`VideoAppearance`**: Video’s design-system type. Holds `tokens: DesignSystemTokens` and `colors: VideoAppearance.Colors` (14 Video-only colors). No images or sounds. Video owns **no** layout or font tokens; layout and shared fonts come from `tokens`.
- **`Appearance`** (legacy): existing SwiftUI `Colors` struct plus images, fonts, and sounds. `@Injected(\.appearance)` / `@Injected(\.fonts)` and `StreamVideoUI(..., appearance:)` still take this type. Shared typography lives on `videoAppearance.tokens.fonts`. **Do not migrate existing views** onto `VideoAppearance` or `tokens.fonts` unless the task explicitly asks.

Product prefix is **Video**, not Call. Use `VideoAppearance` / `VideoAppearance.Colors`.

```swift
let tokens = DesignSystemTokens()
tokens.colors.palette.brand500 = .red
tokens.layout.spacingMd = 16

let videoAppearance = VideoAppearance(tokens: tokens)
videoAppearance.colors.indicatorSpeaking = .green

// Existing views, until they migrate:
let appearance = Appearance(colors: colors, images: images, fonts: fonts, sounds: sounds)
StreamVideoUI(streamVideo: streamVideo, appearance: appearance)
```

Access paths on `VideoAppearance`:

- Shared: `videoAppearance.tokens.colors.accentPrimary`, `videoAppearance.tokens.layout.spacingMd`, `videoAppearance.tokens.fonts.body`
- Video-only: `videoAppearance.colors.controlAcceptCallBackground`

`VideoAppearance.Colors.init` defaults to `DesignSystemTokens()`, so `Colors()` works without supplying tokens.

Token split and re-sync rules live in Core: `Sources/StreamCoreUI/DesignSystem/TokenScope.md`. Do not add Chat (`chat*`) tokens to this SDK.

### Mixed Chat + Video apps

`InjectedValues` is a StreamCore type. Both SDKs must not publish the same key names (`appearance`, `colors`, `fonts`, `images`, `tokens`) or a customer file that imports both will not compile. Video views still inject `fonts` from legacy `Appearance`; Chat UIKit keeps local `UIFont` faces.

Intended customer API (Chat will mirror this when it adopts):

```swift
struct InboxHeader: View {
    @Injected(\.videoAppearance) private var videoAppearance
    @Injected(\.chatAppearance) private var chatAppearance

    var body: some View {
        HStack(spacing: videoAppearance.tokens.layout.spacingMd) {
            Label("3 missed", systemImage: "phone.down.fill")
                .background(Color(videoAppearance.colors.controlAcceptCallBackground))
            Label("2 unread", systemImage: "message.fill")
                .foregroundColor(Color(chatAppearance.tokens.colors.textPrimary))
        }
        .font(videoAppearance.tokens.fonts.body)
    }
}
```

Pass the **same** `DesignSystemTokens` instance into both appearances so brand/layout/fonts stay in sync. If the customer constructed Chat and Video with different token instances, each surface must read `tokens` from **its own** appearance; they are no longer interchangeable.

This injection split is the destination API. It is **not** wired on Video yet: views still use `@Injected(\.appearance)` → legacy `Appearance`. Do not add `videoAppearance` to `InjectedValues` or rename the existing keys unless the task asks.

### Linking

- `StreamVideo` depends on StreamCore.
- `StreamVideoSwiftUI` depends on StreamVideo + **StreamCoreUI** (for tokens). Do not also link StreamCore into the SwiftUI or UIKit product targets; StreamCoreUI’s target already depends on StreamCore (`log`), and an extra link duplicates `StreamCore.o` into the SwiftUI dylib (size bot).
- `StreamVideoUIKit` depends on StreamVideo + StreamVideoSwiftUI + StreamCore (UIKit exposes SwiftUI types that reference StreamCore models).
- Tests may link StreamCore explicitly.

### Constraints for this work

- CoreUI’s `UIColor(light:dark:)` stays internal; Chat already has a public one.
- Icons and images stay on each SDK until a follow-up.
- Danger `commit_lint` fails commit subjects that end with a period.
- Do not change `CHANGELOG.md` or `README.md` unless explicitly asked.
- Local simulator used for this work: `platform=iOS Simulator,name=iPhone 17,OS=26.5`.

### Tech & toolchain

- Language: Swift 5.10 (`swift-tools-version:5.10` in `Package.swift`)
- UI frameworks: SwiftUI first; UIKit components may also be present
- Media stack: WebRTC/AVFoundation under the hood
- Primary distribution: Swift Package Manager (SPM)
- Project file: `StreamVideo.xcodeproj` (used for builds and tests)
- Xcode: 15.x or newer (Apple Silicon supported); CI also validates on older Xcode
- Platforms / deployment targets: Use the values set in `Package.swift`; do not lower without approval
- CI: GitHub Actions + Fastlane (see `.github/workflows/smoke-checks.yml`)
- Linting: SwiftLint (v0.59.1) — config in `.swiftlint.yml`
- Formatting: SwiftFormat (v0.58.2) — config in `.swiftformat`
- Git hooks: lefthook (`lefthook.yml`) — runs SwiftLint fix + SwiftFormat on pre-commit
- Tool versions are pinned in `Githubfile`
- Apple docs helper: Use https://sosumi.ai/ (MCP or direct) for up-to-date Apple platform APIs
- Xcode MCP: Agents may use the Xcode MCP to build, test, and interact with apps on simulators and real devices. See `https://developer.apple.com/documentation/xcode/giving-agentic-coding-tools-access-to-xcode`.

### Dependencies

- **StreamCore** / **StreamCoreUI** from [`stream-core-swift`](https://github.com/GetStream/stream-core-swift.git) (revision pin until tokens ship in a tag)
- **swift-protobuf** (exact 1.30.0)
- **stream-video-swift-webrtc** (exact 145.15.0)

Do not add new third-party deps without discussion.

## Project Structure & Module Organization

```
Sources/
  StreamVideo/              # Core client: API, models, WebRTC, call state
  StreamVideoSwiftUI/       # SwiftUI components, appearance, design system
    DesignSystem/           # VideoAppearance product tokens
  StreamVideoUIKit/         # UIKit wrappers around SwiftUI
StreamVideoTests/           # Unit + integration tests for StreamVideo
StreamVideoSwiftUITests/    # SwiftUI snapshot & unit tests
StreamVideoUIKitTests/      # UIKit tests
DemoApp/                    # Primary SwiftUI demo app
DemoAppUIKit/               # UIKit demo app
DocumentationTests/         # DocC documentation tests
Scripts/                    # Helper scripts (bootstrap, codex checks)
fastlane/                   # Fastlane lanes for CI
```

- Mirror nearby module patterns; keep file names aligned with the primary type (e.g., `CallViewModel.swift`).

### New files & target membership

When creating new source or resource files, add them to the correct Xcode target(s). Update the project (e.g. `project.pbxproj`) so each new file is included in the appropriate target's "Compile Sources" (or "Copy Bundle Resources" for assets). Match the target(s) used by sibling files in the same directory (e.g. `Sources/StreamVideo/` → StreamVideo; `Sources/StreamVideoSwiftUI/` → StreamVideoSwiftUI; `Sources/StreamVideoUIKit/` → StreamVideoUIKit; `Tests/StreamVideoTests/` → StreamVideoTests; `Tests/StreamVideoSwiftUITests/` → StreamVideoSwiftUITests; `Tests/StreamVideoUIKitTests/` → StreamVideoUIKitTests). Omitting target membership will cause build failures or unused files.

### Local setup (SPM)

1. Open the repository in Xcode (root contains `Package.swift` and `StreamVideo.xcodeproj`).
2. Resolve packages.
3. Choose an iOS Simulator (e.g., iPhone 17 Pro) and Build.

Optional: run `Scripts/bootstrap.sh` to install pinned versions of SwiftLint, SwiftFormat, and SwiftGen, and to set up lefthook git hooks.

### Demo app

The `DemoApp` target is a fully functional sample app. Prefer running it to validate UI changes. Keep demo configs free of credentials and use placeholders like `YOUR_STREAM_KEY`.

### Schemes

Available shared schemes (under `StreamVideo.xcodeproj/xcshareddata/xcschemes/`):

- `StreamVideo` — builds the core framework
- `StreamVideoSwiftUI` — builds the SwiftUI framework
- `StreamVideoUIKit` — builds the UIKit framework
- `DemoApp` — builds and runs the SwiftUI demo app
- `DemoAppUIKit` — builds and runs the UIKit demo app

Agents must query existing schemes before invoking xcodebuild.

## Build, Test, and Development Commands

Prefer Xcode for day-to-day work; use CLI for CI parity & automation.

Build (Debug):

```
xcodebuild \
  -project StreamVideo.xcodeproj \
  -scheme StreamVideo \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -configuration Debug build
```

Run tests:

```
bundle exec fastlane test
bundle exec fastlane test_swiftui
bundle exec fastlane test_uikit
```

If the device is not available, use one of the active booted devices:

```
xcodebuild \
  -project StreamVideo.xcodeproj \
  -scheme StreamVideo \
  -destination "platform=iOS Simulator,OS=any,name=$(xcrun simctl list devices booted | grep '(Booted)' | head -1 | sed 's/ (.*)//')" \
  -configuration Debug test
```

### Linting & formatting

SwiftFormat (strict):

```
bundle exec fastlane run_swift_format strict:true
```

Respect `.swiftlint.yml` and `.swiftformat` rules. Do not broadly disable rules; scope exceptions and justify in PRs.

### CI overview

CI is driven by Fastlane (see `fastlane/Fastfile`). Key lanes:

- `test` — runs StreamVideo unit tests
- `test_swiftui` — runs StreamVideoSwiftUI tests
- `test_uikit` — runs StreamVideoUIKit tests
- `test_e2e` — runs E2E tests
- `build_swiftui_demo` / `build_uikit_demo` — builds demo apps
- `run_swift_format` — runs SwiftFormat validation
- `validate_public_interface` — checks for unintended public API changes

The `smoke-checks.yml` workflow is the primary PR gate.

### Public API & SemVer

- Follow semantic versioning across public modules.
- This branch is **2.0**: design-system types (`VideoAppearance`, token access) may be source-breaking. Prefer deprecation for unrelated public API.
- Any public API change must include updated docs and migration notes.

### Performance & quality

- Avoid heavy work on the main thread; keep rendering/state updates efficient.
- Monitor frame rate, bitrate adaptation, and CPU/GPU usage; prefer hardware‑accelerated codecs when available.
- Be careful with retain cycles in capture/render pipelines; audit async capture lists.
- Consider adaptive UI for low‑bandwidth scenarios (thumbnail modes, audio‑only fallback).

## Coding Style & Naming Conventions

- Swift (SPM-first). Indentation: 4 spaces; avoid trailing whitespace.
- Naming: Types/protocols `UpperCamelCase`; methods/variables `lowerCamelCase`; constants `lowerCamelCase`.
- Structure large files with `// MARK:` and add `///` docs for public APIs.

### Development guidelines

Code documentation

- Write doc comments (`///`) only for `public` declarations — types, methods, and properties that are part of the SDK's public API.
- Do not add doc comments to `internal`, `private`, or test code.
- Keep doc comments concise: a one-line summary; add parameter/return docs only when they are not obvious from the signature.
- Do not add inline comments narrating what the code or a change does; comment only non-obvious constraints or reasoning.

Accessibility & UI quality

- Ensure SwiftUI and UIKit components have accessibility labels, traits, and dynamic type support.
- Support both light/dark mode.
- Use the Appearance system for theming and configuration.

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

- Maintain compatibility with deployment targets in Package.swift.
- Avoid adding new third‑party deps without discussion.
- Validate SPM integration in a fresh sample app when changing module boundaries.

### Branching & changelog

- The v2 integration branch is `v2`. Feature branches for SDK 2.0 merge into `v2`, not `develop`.
- Name branches with a descriptive kebab-case prefix, e.g. `v2-design-fonts`, `v2-design-tokens`.
- Update `CHANGELOG.md` under the `# Upcoming` section when making client-facing changes (follow the Keep a Changelog format).
- Only update `CHANGELOG.md` **after the PR has been opened**, so the entry can include the PR link. Push the changelog update as a follow-up commit on the same branch.
- Keep changelog entries short and user-visible; do not explain implementation details.

## Commit & Pull Request Guidelines

- Commits: small, focused, imperative subject lines ("Fix crash in renderer").
- Start commit subject lines with a capital letter.
- Do not end the subject with a period; Danger `commit_lint` fails the Automated Code Review job.
- Keep the subject line concise (ideally under 72 characters); put additional context in the body separated by a blank line.
- Do **not** include ticket IDs or Linear issue keys in commit subjects. Link tickets from the PR instead.
- Before opening a PR: build all affected schemes, run tests, `bundle exec fastlane run_swift_format strict:true`.
- PRs must include: clear description, linked issues, CHANGELOG updates for user-visible changes, and screenshots/screencasts for UI changes. No new warnings.
- Use the GitHub CLI to create a PR and use the Linear MCP to link the relevant issue.
- When creating a PR for v2 work, the base branch should be `v2`.
- Do not use `gh pr edit` (GraphQL `projectCards` deprecation). Patch the body with `gh api repos/.../pulls/N -X PATCH`.
- Do not write "Made with Cursor" in the PR description.

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
