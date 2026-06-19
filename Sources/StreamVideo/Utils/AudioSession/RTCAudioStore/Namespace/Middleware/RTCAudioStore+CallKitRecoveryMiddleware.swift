//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Restores ADM playout and microphone capture after CallKit hands the
    /// audio session to the app.
    ///
    /// With CallKit joins the answer action is fulfilled only once the call
    /// has joined, so the WebRTC layer configures the peer connections (and
    /// may start ADM recording) while the AVAudioSession is still inactive.
    /// In that window the recording is initialised but the engine input
    /// never actually starts. When CallKit later activates the session,
    /// `CallKitReducer` only forwards the activation and flips `isActive`;
    /// nothing restarts the stalled recording, leaving the microphone dead
    /// while the state reports recording. This middleware closes that gap by
    /// replaying the same recovery `InterruptionsEffect` uses: stop and start
    /// recording, then re-apply the current microphone mute state.
    ///
    /// The same activation window can also leave playout in a stale state:
    /// WebRTC may report `isPlaying == true` even after its audio engine
    /// failed to start against a temporarily unavailable output route. The
    /// middleware therefore forces a playout restart before applying any
    /// recording-specific recovery.
    final class CallKitRecoveryMiddleware: Middleware<RTCAudioStore.Namespace>,
        @unchecked Sendable {

        /// Forces playout to restart when CallKit activates the audio session.
        ///
        /// If recording was already on, this also dispatches the existing
        /// recording restart sequence so the microphone recovers against the
        /// now-active audio session.
        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                case .callKit(.activate) = action,
                let audioDeviceModule = state.audioDeviceModule
            else {
                return
            }
            
            audioDeviceModule.resetPlayout()

            if state.isRecording {
                // The follow-up actions are enqueued on the store's serial
                // processing queue, so they execute after `CallKitReducer` has
                // forwarded the activation to the WebRTC session. The restart
                // therefore runs against an active audio session.
                var actions: [Namespace.Action] = [
                    .setRecording(false),
                    .setRecording(true),
                    .setMicrophoneMuted(state.isMicrophoneMuted)
                ]
                dispatcher?.dispatch(actions.map(\.box))
            }
        }
    }
}
