Guidance for AI coding agents (Copilot, Cursor, Aider, Claude, etc.) working in this repository. Human readers are welcome, but this file is written for tools.

### Repository purpose

This repository hosts Stream’s Swift Video/Calling SDK for Apple platforms. It provides the real‑time audio/video client, call state & signaling, and SwiftUI/UI kit components to build 1:1 and group calls with chat integration.

Agents should optimize for media quality, API stability, backwards compatibility, and high test coverage.

### Tech & toolchain
  • Language: Swift
  • UI frameworks: SwiftUI first; UIKit components may also be present
  • Media stack: WebRTC/AVFoundation under the hood
  • Primary distribution: Swift Package Manager (SPM)
  • Secondary (if applicable): CocoaPods
  • Xcode: 15.x or newer (Apple Silicon supported)
  • Platforms / deployment targets: Use the values set in Package.swift/podspecs; do not lower without approval
  • CI: GitHub Actions (assume PR validation for build + tests + lint)
  • Linters & docs: SwiftLint via Mint (if configured), Vale for prose (if configured), DocC/Jazzy for API docs where applicable

### Project layout (high level)

Package.swift
Sources/
  StreamVideo/            # Core client, call model, signaling, media engine wrappers
  StreamVideoSwiftUI/     # SwiftUI call UI (prebuilt views, theming)
  StreamVideoUIKit/       # UIKit components (if present)
Tests/
  StreamVideoTests/
  StreamVideoSwiftUITests/
DemoApp/                  # sample app(s)

Mirror the conventions of the closest module when editing. Query actual target/product names from Package.swift.

### Local setup (SPM)
  1.  Open the repo root in Xcode (Package.swift present) and resolve packages.
  2.  Select an iOS Simulator (e.g., iPhone 15) and build.
  3.  For camera/microphone features, test on a real device when necessary.

### Optional: sample/demo app

If a sample app exists, use it to validate UI & media flows. Don’t hardcode credentials—use placeholders like YOUR_STREAM_KEY and configure via environment or xcconfig.

### Schemes

Typical scheme names include:
  • StreamVideo
  • StreamVideoSwiftUI
  • StreamVideoUIKit (if present)
  • Corresponding …Tests schemes

Agents must query existing schemes before invoking xcodebuild.

### Build & test commands (CLI)

Prefer Xcode for day‑to‑day work; use CLI for CI parity & automation.

Build (Debug):

```
xcodebuild \
  -scheme StreamVideo \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug build
```

Run tests:

```
xcodebuild \
  -scheme StreamVideo \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug test
```

```
xcodebuild \
  -scheme StreamVideoSwiftUI \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -configuration Debug test
```

If a Makefile or scripts exist (e.g., make build, make test, ./scripts/lint.sh), prefer those to keep parity with CI. Discover with make help and ls scripts/.

Linting & formatting
  • SwiftLint (strict) when configured:

swiftlint --strict

  • Respect .swiftlint.yml and repo rules. Scope any disabled rules narrowly and justify in PRs.

### Public API & SemVer
  • Follow semantic versioning across public modules.
  • Any public API change must include updated docs and migration notes.
  • Avoid source‑breaking changes; if unavoidable, deprecate first with a transition path.

### Media & permissions checklist
  • Request & handle camera and microphone permissions gracefully.
  • Handle foreground/background transitions; pause/resume capture appropriately.
  • Support device rotation and multi‑orientation previews.
  • Validate CallKit integration (if present) and ensure correct audio session categories/modes.
  • Ensure PushKit/VoIP notifications are optional and documented if supported.

### Networking & security
  • Never commit API keys or user/customer data.
  • Redact tokens and sensitive headers in logs.
  • Use secure defaults (TLS); respect backend‑provided TURN/ICE config.
  • Fail closed if required env vars/config are missing in scripts or sample apps.

### Performance & quality
  • Avoid heavy work on the main thread; keep rendering/state updates efficient.
  • Monitor frame rate, bitrate adaptation, and CPU/GPU usage; prefer hardware‑accelerated codecs when available.
  • Be careful with retain cycles in capture/render pipelines; audit async capture lists.
  • Consider adaptive UI for low‑bandwidth scenarios (thumbnail modes, audio‑only fallback).

### Testing policy
  • Add/extend tests under Tests/ for:
  • Call lifecycle (join/leave, reconnect, error paths)
  • State machines/view models
  • Media settings toggles (mute/camera flip) using fakes/mocks where possible
  • Layout/rendering logic in SwiftUI/UI components
  • Prefer async/await and expectations; avoid time‑based sleeps.

### Documentation & examples
  • Update inline /// docs and examples when changing public APIs.
  • Keep sample code compilable; provide minimal, copy‑pasteable snippets.
  • Use // MARK: to structure large files.

### Compatibility & dependencies
  • Maintain compatibility with deployment targets in Package.swift.
  • Avoid adding new third‑party deps without discussion.
  • Validate SPM integration in a fresh sample app when changing module boundaries.

### PR conventions
  • Keep PRs small and focused; include tests.
  • Update CHANGELOG for user‑visible changes.
  • No new warnings in build logs.
  • For visible UI changes, attach screenshots/screen recordings.
  • Mention relevant CODEOWNERS for affected areas.

### When in doubt
  • Mirror existing patterns in the closest module.
  • Prefer additive changes and minimize public API churn.
  • Ask maintainers via PR mentions when uncertain.

### Quick agent checklist (per commit/PR)
  • Build StreamVideo and affected UI modules for iOS Simulator
  • Run tests and ensure green
  • Run swiftlint --strict (and vale . if docs changed)
  • Update docs/migration notes for any public API change
  • Update CHANGELOG for user‑visible changes
  • Attach UI screenshots/recordings for visible changes
  • No new warnings in build logs

End of machine guidance. Keep human‑facing details in README.md/docs; refine agent behavior here over time.