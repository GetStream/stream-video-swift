# Repository guidance

This repository contains Stream's Swift Video SDK and sample apps.
Use the [repository map](README.md#working-in-this-repository) to locate modules and tools.
These shared rules apply to every workflow below.

On the `v2` branch, also follow [v2 (SDK 2.0)](#v2-sdk-20).

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

## v2 (SDK 2.0)

The `v2` branch is the SDK 2.0 development line. On `v2`, these rules apply in addition to the shared rules above.
v2 may break public UI configuration where the design-token migration requires it. Do not break the calling/media client casually.

### Branches, pull requests and changelog

- Feature branches for SDK 2.0 start from `v2` and open their pull requests against `v2`, not `develop`.
- Name branches with a descriptive kebab-case prefix, e.g. `v2-design-fonts`, `v2-design-tokens`.
- After a release, `# Upcoming` holds only an empty `### 🔄 Changed` placeholder. When adding the first entry, remove that empty placeholder, unless the new entry belongs under `### 🔄 Changed`.

### Public API

- Design-system types (`VideoAppearance`, token access) may be source-breaking on this branch. Prefer deprecation for unrelated public API.

### v2 design system

v2 introduces a **shared design-token system** so Chat and Video can reskin from one source. Shared color, layout, and typography tokens live in **StreamCoreUI** (`DesignSystemTokens`). Each product SDK owns its own appearance type and its own product tokens. Icons and images stay on each SDK for now.

#### Types and ownership

- **`DesignSystemTokens`** (Core, class): `tokens.colors` (semantic colors plus `tokens.colors.palette` for brand/chrome ramps), `tokens.layout` (spacing, radii, strokes, elevations), and `tokens.fonts` (shared SwiftUI typography). Override color ramps **before the first read**. Colors stay on UIKit `UIColor`; fonts stay on SwiftUI `Font`. UIKit `UIFont` faces stay on product UIKit SDKs (for example StreamChatUI).
- **`VideoAppearance`**: Video’s only appearance type. Holds `tokens: DesignSystemTokens`, `colors: VideoAppearance.Colors` (Video-only colors from `tokens/video`, plus read-only `@dynamicMemberLookup` access to every shared `tokens.colors` member), `images: Images` (Video’s own icons, mirroring Chat’s `appearance.images`), and `sounds: Sounds` (incoming/outgoing call sounds). `VideoAppearance.localizationProvider` overrides SDK string lookup. Video owns **no** layout or font tokens; layout and shared fonts come from `tokens`. Labels and other shared semantics live on `tokens.colors`.
- The legacy `Appearance`, `Colors`, and `Fonts` types and the `\.appearance` key were removed in v2. Do not reintroduce them. `\.colors`, `\.images`, `\.sounds`, `\.fonts`, and `\.layout` now resolve through `VideoAppearance` (see below).

Product prefix is **Video**, not Call. Use `VideoAppearance` / `VideoAppearance.Colors`.

```swift
let tokens = DesignSystemTokens()
tokens.colors.palette.brand500 = .red
tokens.layout.spacingMd = 16

let videoAppearance = VideoAppearance(tokens: tokens)
videoAppearance.colors.indicatorSoundIndicatorSpeaking = .green
videoAppearance.images.hangup = Image("custom_hangup")
videoAppearance.sounds.incomingCallSound = "custom_ringtone.m4a"

StreamVideoUI(streamVideo: streamVideo, videoAppearance: videoAppearance)
```

Injected keys (all backed by `\.videoAppearance`):

| Key | Type | Reads |
|---|---|---|
| `\.colors` | `VideoAppearance.Colors` | Video-only colors plus every shared color (`colors.textPrimary`, `colors.palette.brand500`) |
| `\.images` | `Images` | `videoAppearance.images` |
| `\.sounds` | `Sounds` | `videoAppearance.sounds` |
| `\.fonts` | `DesignSystemTokens.Fonts` | `videoAppearance.tokens.fonts` |
| `\.layout` | `DesignSystemTokens.Layout` | `videoAppearance.tokens.layout` |
| `\.videoAppearance` | `VideoAppearance` | the whole appearance |

Views in a Video-only file, inside the SDK and in DemoApp, inject only the keys they read:

```swift
@Injected(\.colors) var colors
@Injected(\.images) var images
@Injected(\.sounds) var sounds
@Injected(\.fonts) var fonts
@Injected(\.layout) var layout
```

- Read shared and Video-only colors from the same `colors` (`colors.textPrimary`, `colors.controlAcceptCallButtonBackground`).
- Do not add computed helpers such as `private var tokens: DesignSystemTokens { videoAppearance.tokens }`, or `View` / `ButtonStyle` / `ViewModifier` extensions that expose tokens.
- Inject `\.videoAppearance` only when the type needs the whole appearance (for example to pass it on).
- If a type already has a member named `colors`, `images`, `sounds`, `fonts`, or `layout` (for example `LayoutMenuItem.layout`), inject under another name: `@Injected(\.layout) private var layoutTokens`.
- Outside a type (default arguments, static presets, free functions), read `InjectedValues[\.colors]`, `InjectedValues[\.layout]`, and so on.

The shared-color forwarding is generated by `design-system-tokens` (`productColorsOutput` in `config/post-processing/ios-post-processing.js`). The generator fails if a product color reuses a Core color name, because the product member would silently hide the shared one. Forwarding is read-only: write shared colors on `tokens.colors`, not through `colors`.

`VideoAppearance.Colors.init` defaults to `DesignSystemTokens()`, so `Colors()` works without supplying tokens.

Token ownership lives in `design-system-tokens`. Video consumes Core plus `tokens/video` (`VideoAppearance.Colors`). Do not add Chat tokens to this SDK.

#### Mixed Chat + Video apps

`InjectedValues` is a StreamCore type. Chat is expected to publish the same short keys (`colors`, `images`, `sounds`, `fonts`, `layout`), so in a file that imports **both** SDKs those keys are ambiguous. Files that use only one SDK keep the short keys. Chat UIKit keeps local `UIFont` faces.

In a file that imports both SDKs, use the root appearance or nested key paths:

```swift
@Injected(\.videoAppearance.colors) var videoColors        // Video-only + shared colors
@Injected(\.videoAppearance.tokens.colors) var colors
@Injected(\.videoAppearance.tokens.fonts) var fonts
@Injected(\.videoAppearance.tokens.layout) var layout
```

`VideoAppearance` is a class, so these paths stay writable. Do not use the nested form in Video-only files; it exists for mixed files.

Intended customer API for a mixed file (Chat will mirror this when it adopts):

```swift
struct InboxHeader: View {
    @Injected(\.videoAppearance) private var videoAppearance
    @Injected(\.chatAppearance) private var chatAppearance

    var body: some View {
        HStack(spacing: videoAppearance.tokens.layout.spacingMd) {
            Label("3 missed", systemImage: "phone.down.fill")
                .background(Color(videoAppearance.colors.controlAcceptCallButtonBackground))
            Label("2 unread", systemImage: "message.fill")
                .foregroundColor(Color(chatAppearance.tokens.colors.textPrimary))
        }
        .font(videoAppearance.tokens.fonts.body)
    }
}
```

Pass the **same** `DesignSystemTokens` instance into both appearances so brand/layout/fonts stay in sync. If the customer constructed Chat and Video with different token instances, each surface must read `tokens` from **its own** appearance; they are no longer interchangeable.

`StreamVideoUI(..., videoAppearance:)` wires `@Injected(\.videoAppearance)`.

#### Design refresh (token migration)

The v2 UI refresh is a **token swap**, not a Figma rebuild. Figma is the source for *which* semantic tokens a surface should use. The existing SwiftUI structure, copy, assets, and control hierarchy stay unless a follow-up explicitly asks for a layout redesign.

Do:

- Switch the view to the short keys (`@Injected(\.colors)`, `\.fonts`, `\.layout`, `\.images`) and read colors, fonts, spacing, and radii from them.
- Use Figma variable names as a lookup (`core/button/secondary/bg` → `tokens.colors.buttonSecondaryBackground`, `typography` styles → `tokens.fonts.*`).
- Replace hardcoded numbers *and* implicit SwiftUI defaults: bare `.padding()` is 16pt (`tokens.layout.spacingMd`). Give `VStack` / `HStack` an explicit spacing token instead of relying on the system default.
- Replace legacy `CallIconStyle.primary` / `.transparent` (hardcoded white/black) with a `CallIconStyle` built from the tokens Figma assigns to that control (lobby mic/camera use secondary button bg/text).
- Read icons from `images` (`@Injected(\.images)`); never inline `Image(systemName:)` in a migrated view.
- Re-record **existing** snapshots that cover the state you restyled before adding new ones; a shared control change (badges, `CallIconStyle`) reaches every suite that renders it.
- Keep snapshot tests for the screen; record with `-configuration Test` (the `STREAM_TESTS` flag lives only on Test). Prefer updating existing snapshot filenames so Git shows a before/after image diff.

Do not:

- Restyle the screen to match Figma frames (new headers, globe icons, aspect ratios, CTA copy, removed participant cards, and so on).
- Add Figma-only assets or L10n keys that the current layout does not use.
- Use `tokens.layout.spacingNone` for zero spacing; write `spacing: 0`.
- Invent Core avatar/size tokens from this SDK. If no public token matches, use the nearest public layout token (`buttonVisualHeightMd` / `Lg`, `spacing*`, `radius*`) rather than a magic number. Do not reach into StreamCoreUI’s internal `size64` / `size80` primitives.
- Use iOS 14-only a11y modifiers (`.accessibilityLabel`, `.accessibilityHidden`); deployment is still iOS 13 in this module — use `.accessibility(label:)` / `.accessibility(hidden:)`.

Typical substitutions from the lobby pass:

| Legacy / literal | Token |
|---|---|
| `colors.text` | `tokens.colors.textPrimary` |
| `colors.textLowEmphasis` | `tokens.colors.textSecondary` |
| `colors.lobbyBackground` | `tokens.colors.backgroundCoreApp` |
| `colors.lobbySecondaryBackground` | `tokens.colors.backgroundCoreSurfaceDefault` |
| `colors.primaryButtonBackground` / `.white` | `tokens.colors.buttonPrimaryBackground` / `buttonPrimaryTextOnAccent` |
| `.font(.title)` / `.body` / `.headline` / `.caption` | `tokens.fonts.title` / `.body` / `.headline` / `.caption1` |
| `16` padding or corner radius | `tokens.layout.spacingMd` / `radiusXl` |
| `32` stack spacing | `tokens.layout.spacing2xl` |

### ViewFactory options

Every `ViewFactory` method takes a single `options:` argument:

```swift
func makeCallView(options: CallViewOptions) -> some View {
    CustomCallView(viewModel: options.viewModel)
}

viewFactory.makeCallView(options: .init(viewModel: viewModel))
```

- Options types live in `Sources/StreamVideoSwiftUI/ViewFactory/Options/` and are `public final class …Options` with `public let` properties and a public `init`.
- Conform to `Sendable` only when every stored property is `Sendable` (no `Binding`, closures, or non-Sendable models such as `ScreenSharingSession`).
- New inputs for a slot go on its options type, not as new method parameters.
- When an override forwards to `DefaultViewFactory`, pass `options` through instead of rebuilding it.

### Linking

- `StreamVideo` depends on StreamCore.
- `StreamVideoSwiftUI` depends on StreamVideo + **StreamCoreUI** (for tokens). Do not also link StreamCore into the SwiftUI or UIKit product targets; StreamCoreUI’s target already depends on StreamCore (`log`), and an extra link duplicates `StreamCore.o` into the SwiftUI dylib (size bot).
- `StreamVideoUIKit` depends on StreamVideo + StreamVideoSwiftUI + StreamCore (UIKit exposes SwiftUI types that reference StreamCore models).
- Tests may link StreamCore explicitly.

### v2 constraints

- CoreUI’s `UIColor(light:dark:)` stays internal; Chat already has a public one.
- Icons and images stay on each SDK until a follow-up.
