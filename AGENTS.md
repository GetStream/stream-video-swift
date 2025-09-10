# Repository Guidelines

## Project Structure & Module Organization
- Root: `Package.swift` (SPM entry).
- Sources: `Sources/StreamVideo/`, `Sources/StreamVideoSwiftUI/`, `Sources/StreamVideoUIKit/`.
- Tests: `StreamVideoTests/`, `StreamVideoSwiftUITests/`, `StreamVideoUIKitTests/` .
- Demos: `DemoApp/` and `DemoAppUIKit` samples.
- Documentation tests: `DocumentationTests/DocumentationTests/`.
- Mirror nearby module patterns; keep file names aligned with the primary type (e.g., `CallViewModel.swift`).

## Build, Test, and Development Commands
- Open in Xcode 15+ via `Package.swift` and build for an iOS Simulator (e.g., iPhone 15).
- Build (CLI):
  - `xcodebuild -scheme StreamVideo -destination 'platform=iOS Simulator,name=iPhone 15' -configuration Debug build`
- Tests (CLI):
  - `bundle exec fastlane test`
  - `bundle exec fastlane test_swiftui`
  - `bundle exec fastlane test_uikit`
- Lint: `bundle exec fastlane run_swift_format strict:true` (respect `fastlane/Fastfile`).

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

## Comments
- Use docC for non-private APIs.
- Use `///` for doc comments.
- Use `// MARK:` to group code.
- Use `// MARK: - <Group Name>` to group code.
- Use 80 characters as the maximum line length.
- Keep comments as simple as possible.
- Avoid stating the obvious e.g. `var isActive: Bool // A variable that indicates if the view is active`.
- Read around the APIs you are documenting and add context to make the comments more useful.

## Commit & Pull Request Guidelines
- Commits: small, focused, imperative subject lines ("Fix crash in renderer").
- Before opening a PR: build all affected schemes, run tests, `bundle exec fastlane run_swift_format strict:true`.
- PRs must include: clear description, linked issues, CHANGELOG updates for user-visible changes, and screenshots/screencasts for UI changes. No new warnings.

## Security & Configuration Tips
- Never commit API keys or user data; use env/xcconfig with placeholders.
- Redact tokens in logs; use TLS; respect backend-provided TURN/ICE config.
