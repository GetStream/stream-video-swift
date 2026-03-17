//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates the stage that waits briefly for publisher and subscriber peer
    /// connections to report `.connected` before the join call completes.
    ///
    /// - Parameters:
    ///   - context: The state machine context for the pending join flow.
    ///   - telemetryReporter: Reports telemetry after the stage finishes.
    static func peerConnectionPreparing(
        _ context: Context,
        telemetryReporter: JoinedStateTelemetryReporter
    ) -> WebRTCCoordinator.StateMachine.Stage {
        PeerConnectionPreparingStage(
            context,
            telemetryReporter: telemetryReporter
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
        private let timeout: TimeInterval = WebRTCConfiguration.timeout.peerConnectionReadiness
        private let telemetryReporter: JoinedStateTelemetryReporter

        /// Initializes a new instance of `PeerConnectionPreparingStage`.
        ///
        /// - Parameters:
        ///   - context: The state machine context for the pending join flow.
        ///   - telemetryReporter: Reports telemetry after the stage finishes.
        init(
            _ context: Context,
            telemetryReporter: JoinedStateTelemetryReporter
        ) {
            self.telemetryReporter = telemetryReporter
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
                let coordinator = context.coordinator,
                let sfuAdapter = await coordinator.stateAdapter.sfuAdapter,
                let publisher = await coordinator.stateAdapter.publisher,
                let subscriber = await coordinator.stateAdapter.subscriber
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

            await telemetryReporter.reportTelemetry(
                sessionId: await coordinator.stateAdapter.sessionID,
                unifiedSessionId: coordinator.stateAdapter.unifiedSessionId,
                sfuAdapter: sfuAdapter
            )

            reportJoinCompletion()

            transitionOrDisconnect(.joined(context))
        }
    }
}
