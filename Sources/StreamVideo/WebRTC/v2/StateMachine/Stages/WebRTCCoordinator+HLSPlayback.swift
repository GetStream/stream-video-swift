//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates and returns an HLS playback stage for the WebRTC coordinator
    /// state machine.
    /// - Parameter context: The context for the HLS playback stage.
    /// - Returns: An `HLSPlaybackStage` instance.
    static func hlsPlayback(
        _ context: Context
    ) -> WebRTCCoordinator.StateMachine.Stage {
        HLSPlaybackStage(context)
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Represents a call that the backend routed to HLS playback.
    ///
    /// The client never connects to an SFU in this stage. The stage completes
    /// the pending join and then waits for the call to end. It never moves to
    /// a reconnection stage, because there is no SFU connection to recover.
    final class HLSPlaybackStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {

        /// Initializes a new instance of `HLSPlaybackStage`.
        /// - Parameter context: The context for the HLS playback stage.
        init(_ context: Context) {
            super.init(id: .hlsPlayback, context: context)
        }

        /// Performs the transition from a previous stage to this stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `HLSPlaybackStage` instance if the transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.connecting`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .connecting:
                // Reported inline: no task means no late report after a leave.
                reportJoinCompletion()
                return self
            default:
                return nil
            }
        }
    }
}
