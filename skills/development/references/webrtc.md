# Working with WebRTC

Use this development reference for WebRTC integration, performance, negotiation, media, and cleanup.
Apply only the relevant sections.

## Establish the API contract

1. Identify the wrapper version in `Package.swift` and the framework actually linked by the target.
   Locate matching sources through the [related repositories](../../../AGENTS.md#related-repositories).
   Find the native source root containing `sdk/objc/`. Do not assume a checkout path.
2. Start with the owning code in `Sources/StreamVideo/WebRTC/` or `Sources/StreamVideo/Utils/AudioSession/`.
   Inspect exported Objective-C headers and the Swift module interface for exact names and behavior.
   Avoid private headers and native internals in SDK integration code.
3. Check optional fork APIs against the linked framework, including AudioEngine and Stream rendering extensions.
   After a native patch, rebuild and select the replacement framework before testing its effect.
   Check package and workspace resolutions and the loaded binary identity. Match symbols to that binary.
4. Use AppRTCMobile as a flow reference. Do not copy its signaling service or application architecture.
   Preserve existing SDK owners for signaling, permissions, lifecycle, and UI policy.

Native paths below start at the discovered WebRTC source root.

| Area | Inspect |
| --- | --- |
| Peer connections, SDP, ICE, RTP, data channels | `sdk/objc/api/peerconnection/` |
| Frames, capture, rendering, codecs | `sdk/objc/base/` and `sdk/objc/components/` |
| Audio and dispatch | `sdk/objc/components/audio/`, `sdk/objc/api/peerconnection/RTCAudioDeviceModule.h`, `sdk/objc/helpers/RTCDispatcher.h` |
| Threading and native ownership | `api/g3doc/threading_design.md` and `pc/g3doc/peer_connection.md` |
| Behavioral references | `sdk/objc/unittests/` and `examples/objc/AppRTCMobile/` |

## Negotiation and concurrency

1. Serialize operations through the existing owner of each `RTCPeerConnection`.
   Keep publisher and subscriber state separate, with the call owner coordinating shared transitions.
   Treat callbacks as non-main-thread unless the contract proves otherwise.
2. Keep callbacks fast. Enqueue work on the responsible owner before mutating state or calling WebRTC again.
   Keep UI and renderer-view ownership on `MainActor`. Do not assume WebRTC objects are `Sendable`.
   Pass values across ownership boundaries and resume continuations exactly once.
3. Guard the whole SDP negotiation across asynchronous suspension points.
   An actor can accept other work during `await`. Track the operation and generation explicitly.
   Coalesce or reject overlapping negotiations. Discard completions from closed or replaced generations.
4. Use Unified Plan, transceivers, and completion-handler APIs for new work.
   For an offer, create SDP, set the local description successfully, then signal it.
   For an answer, accept remote SDP before creating and setting the local answer, then signal it.
   Handle errors from SDP creation, description changes, and ICE application.
5. Route remote ICE by call, peer role, session, and ICE generation.
   Buffer candidates until the matching remote description succeeds, then apply them in arrival order.
  Drop stale candidates after restart or replacement.

## Resource ownership and overlapping calls

- Preserve existing factory ownership and hardware lifetimes.
  For overlapping calls, coordinate audio, camera, and screen capture through the existing resource owners.
  Change factory sharing across calls only as part of an explicitly scoped architecture change.
- Keep each call's desired mute, publication, route, and capture settings separate from effective hardware state.
  Use explicit acquisition, transfer, suspension, and release when calls compete for a device.
  Default to one active call lease per physical device unless product policy supports sharing.
- Serialize ownership changes and return failures to the initiating call.
  Respect server capabilities, permissions, and explicit user choices. Never silently replace another call's ownership.
- Preserve resource ownership through reconnect, rejoin, and migration when the call still needs the resource.
  Replacing peer connections must not duplicate acquisition or release another generation's resources.
  Hold or detach preserves desired settings for resume. Ending one call must not stop another call's media.

## Audio and CallKit

- Prepare the real publisher/subscriber transports before starting capture.
  Avoid disposable peer connections for warm-up. Creating transports after capture can restart the running audio engine.
  Set initial category and mode only when no call owns audio. Reuse the prepared transports for media setup.
  Configure and activate the audio session before native recording, subject to CallKit activation.
- On iOS, configure audio through the existing coordinator and `RTCAudioSession`.
  Serialize configuration on the audio-session dispatcher. Pair `lockForConfiguration` with `unlockForConfiguration`, including error paths.
  Do not synchronously reenter configuration from callbacks that may hold the audio-session lock.
- Balance each successful activation with its owner's deactivation.
  Forward CallKit activation and deactivation to WebRTC through the coordinator.
  If manual audio applies, set its policy before media starts and update `isAudioEnabled` from actual call requirements.
  Base recovery on current system activation. Preserve mute intent without overriding an intervening system deactivation.
- Read the actual route after route changes, interruptions, and media-server resets.
  Resume only when product state and system permission allow it.
  AudioEngine device lists do not establish the active iOS route.
  On macOS, inspect the available audio device module and CoreAudio APIs instead of assuming iOS audio-session behavior.
- Use AudioEngine-specific APIs only when the linked framework exports them and the factory selects that audio device module.
  Return success from engine callbacks unless intentionally aborting the operation.
  Check voice processing, gain control, mute, stereo, and ducking interactions together.
  Keep audio-processing buffers within their callback lifetime.

## Capture and rendering

- Check camera and microphone permissions before capture. Preserve required usage descriptions and product background behavior.
  Select supported capture formats and frame rates. Handle start/stop errors and await completion before releasing resources.
  Do not assume simulator camera access.
- Connect capturers to `RTCVideoSource` and renderers to `RTCVideoTrack`.
  Check external sample buffers, rotation, and timestamps before delivering frames.
  Detach only attachments that the retiring coordinator still owns.
  Guard deferred attachment and first-frame callbacks with track identity and registration generation.
  Resetting and adding the same track must invalidate the old registration. Clear retired delegates.
- Keep layout and geometry updates independent of native signaling queues. Use cached metadata on the main thread.
  Schedule native attachment, detachment, and final track/frame release through existing media owners.
  Keep the required objects alive until cleanup finishes. Preserve operation order.
- Check availability before using Metal, picture-in-picture, or optional Stream rendering APIs.
  Set frame-buffer policy through one owner before media starts when consistent formats matter.
  A mid-call change can leave mixed formats in flight.
  Trace the actual CVPixelBuffer/NV12/I420 path before claiming zero-copy behavior.
  Buffer pools reduce allocations, but conversions can still copy pixels. Measure allocation and copy costs separately.
  Distinguish retained pool capacity from live frame ownership when investigating memory growth.

## Tuning, data, and diagnostics

- Choose supported codecs and sender encoding parameters through exported APIs.
  Use stats to justify bitrate, frame-rate, or resolution changes. Avoid SDP string edits when supported APIs suffice.
- Centralize field-trial and metrics initialization. Check required ordering before other WebRTC calls.
  Prefer factory configuration over deprecated global setup when the linked API supports it.
- Bound data-channel queues using channel state and `bufferedAmount`.
  Choose ordering and reliability deliberately. Surface send failures.
- Preserve security defaults. When product policy requires frame encryption, attach matching cryptors and keys before media starts.
  Keep credentials, key material, full SDP, and private network data out of routine logs.
- Treat log interpolation and `description` as work. Avoid native getters that synchronously cross queues.
  Prefer identifiers, counts, and outcomes. Check severity before expensive formatting.
  Native capture thresholds and SDK destination filters are separate. Check both.
  Remove redundant diagnostic loops at their source while preserving validation failures and useful trace events.
- Bound recent log storage and avoid copying the full history for each entry.
  Refresh viewer snapshots at a bounded rate only while visible. Keep file writes and exports off the main thread.
  Use bounded stats, RTC event logs, or audio dumps only when needed.
- Protect the whole stats comparison and previous-report update as one serialized operation.
  Avoid concurrent lazy initialization. A mutating struct method can race before it acquires an internal lock.
  Use the existing synchronized reference owner.
  Race safety does not establish responsiveness. Measure lock waits and compression time separately.
  Keep raw native reports out of published UI reports when consumers do not need them.
  Stop polling and discard stale deliveries after teardown. Preserve any required final stats delivery before clearing its owner.

## Performance evidence

Use the [profile workflow](../../profile/SKILL.md) for captures and comparisons.
Separate cold first join, warm rejoin, and sustained reconnect load.
Measure signaling delay, audio startup, and main-thread hangs separately.
Background task duration does not measure a UI freeze.
Inspect SwiftUI layout, image generation, PiP setup, and diagnostic sinks when the measured stack points there.
A passing regression test does not establish a latency or thermal improvement.

## Teardown and validation

Make teardown idempotent. Invalidate the call generation before accepting further callbacks.
Cancel timers, stats polling, and pending work. Detach renderers and close call-owned peer connections.
Release only that call's resource claims. Balance audio ownership and await capture cleanup.
Late callbacks must not restore closed state or reacquire resources.

Follow the [test workflow](../../test/SKILL.md).
Use existing mocks and injected transports, clocks, resource owners, and capture sources.
Use synthetic media for deterministic checks when available.

| Changed area | Focused cases |
| --- | --- |
| Negotiation | Early ICE, overlapping offers, SDP failure, restart, close, and stale completions. |
| Call ownership | Hold/resume, competing calls, failed transfers, rejoin, migration, and repeated leave. |
| Audio | Activation balance, manual audio, speaker/headset/Bluetooth routes, interruptions, and background recovery. |
| Capture/rendering | Permission denial, invalid frames, blocked native queues, reused renderers, late first-frame callbacks, and final release. |
| Stats/logging | Concurrent compression, blocked native getters, stale delivery, bounded storage, and hidden-viewer work. |
| Data/security | Queue pressure, send failures, required encryption, and missing keys. |

Report source revisions, public versus fork-specific APIs, executed checks, and untested runtime behavior.
Use the [release workflow](../../release/SKILL.md) for wrapper updates or distribution work.
