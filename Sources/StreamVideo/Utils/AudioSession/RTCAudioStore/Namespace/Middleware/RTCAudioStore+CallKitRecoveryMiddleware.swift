//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

extension RTCAudioStore {

    /// Restores microphone capture after CallKit hands the audio session to
    /// the app.
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
    /// Playout needs no equivalent treatment: WebRTC restarts its audio unit
    /// when the activation is forwarded through `audioSessionDidActivate`,
    /// and the deferred policy application re-issues `setAudioEnabled`,
    /// which maps to `setPlayout` on the ADM.
    final class CallKitRecoveryMiddleware: Middleware<RTCAudioStore.Namespace>,
        @unchecked Sendable {

        /// Dispatches a recording restart when CallKit activates the audio
        /// session while recording was already on. Activations with recording
        /// off are left untouched.
        override func apply(
            state: RTCAudioStore.StoreState,
            action: RTCAudioStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            guard
                case .callKit(.activate) = action,
                state.audioDeviceModule != nil,
                state.isRecording
            else {
                return
            }

            // The follow-up actions are enqueued on the store's serial
            // processing queue, so they execute after `CallKitReducer` has
            // forwarded the activation to the WebRTC session. The restart
            // therefore runs against an active audio session.
            let actions: [Namespace.Action] = [
                .setRecording(false),
                .setRecording(true),
                .setMicrophoneMuted(state.isMicrophoneMuted)
            ]
            dispatcher?.dispatch(actions.map(\.box))
        }
    }
}
