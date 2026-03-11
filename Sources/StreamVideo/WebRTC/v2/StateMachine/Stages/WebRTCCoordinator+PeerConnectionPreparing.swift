//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates the stage that waits briefly for publisher and subscriber peer
    /// connections to report `.connected` before the join call completes.
    static func peerConnectionPreparing(
        _ context: Context,
        timeout: TimeInterval
    ) -> WebRTCCoordinator.StateMachine.Stage {
        PeerConnectionPreparingStage(
            context,
            timeout: timeout
        )
    }
}

extension WebRTCCoordinator.StateMachine.Stage {

    /// Delays join completion until both peer connections are ready, or until
    /// the timeout is reached.
    final class PeerConnectionPreparingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {

        private let disposableBag = DisposableBag()
        private let timeout: TimeInterval

        /// Initializes a new instance of `PeerConnectionPreparingStage`.
        init(
            _ context: Context,
            timeout: TimeInterval
        ) {
            self.timeout = timeout
            super.init(id: .peerConnectionPreparing, context: context)
        }

        /// Performs the transition from `joining` into the peer-connection
        /// preparation stage.
        /// - Parameter previousStage: The stage from which the transition is
        ///   occurring.
        /// - Returns: This `PeerConnectionPreparingStage` instance if the
        ///   transition is
        ///   valid, otherwise `nil`.
        /// - Note: Valid transition from: `.joining`
        override func transition(
            from previousStage: WebRTCCoordinator.StateMachine.Stage
        ) -> Self? {
            switch previousStage.id {
            case .joining:
                Task(disposableBag: disposableBag) { [weak self] in
                    await self?.execute()
                }
                return self
            default:
                return nil
            }
        }

        // MARK: - Private Helpers

        private func execute() async {
            guard
                let publisher = await context.coordinator?.stateAdapter.publisher,
                let subscriber = await context.coordinator?.stateAdapter.subscriber
            else {
                return
            }

            async let publisherIsReady = try await publisher
                .connectionStatePublisher
                .filter { $0 == .connected }
                .nextValue(timeout: timeout)
            async let subscriberIsReady = try await subscriber
                .connectionStatePublisher
                .filter { $0 == .connected }
                .nextValue(timeout: timeout)

            do {
                _ = try await [publisherIsReady, subscriberIsReady]
            } catch {
                log.warning(
                    "Publisher or subscriber weren't ready in \(timeout) seconds. We continue joining and the connections should be ready after completing.",
                    subsystems: .webRTC
                )
            }

            reportJoinCompletion()

            transitionOrDisconnect(.joined(context))
        }
    }
}
