//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

extension WebRTCCoordinator.StateMachine.Stage {

    /// Creates the stage that waits briefly for the publisher peer connection
    /// to report `.connected` before the join call completes.
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

    /// Delays join completion while waiting for the publisher peer connection
    /// to report `.connected`.
    final class PeerConnectionPreparingStage:
        WebRTCCoordinator.StateMachine.Stage,
        @unchecked Sendable {

        /// Defines which peer connections must report `.connected` before this
        /// stage proceeds with join completion.
        ///
        /// The selected configuration controls the readiness strategy in
        /// `perform(for:)`, including whether readiness checks run for one or
        /// both peer connections.
        private enum Configuration {
            /// Wait only for the publisher peer connection.
            ///
            /// This keeps join completion fast and guarantees the publishing
            /// path is ready before transitioning to `.joined`.
            case publisherOnly
            /// Wait for both publisher and subscriber peer connections.
            ///
            /// Both readiness checks run concurrently and the stage proceeds
            /// only after both have completed (or timed out).
            case publisherAndSubscriber
        }

        private let disposableBag = DisposableBag()
        private let timeout: TimeInterval = WebRTCConfiguration.timeout.peerConnectionReadiness
        private let telemetryReporter: JoinedStateTelemetryReporter
        private let configuration: Configuration

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
            self.configuration = .publisherOnly
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

        /// Waits for publisher peer-connection readiness, reports join telemetry, then
        /// transitions to `.joined`.
        ///
        /// The stage tolerates readiness timeouts by logging warnings and
        /// continuing join completion.
        private func execute() async {
            guard
                context.coordinator != nil
            else {
                transitionDisconnectOrError(ClientError())
                return
            }

            await perform(for: configuration)

            await reportTelemetryAndCompletion()

            transitionOrDisconnect(.joined(context))
        }

        private func perform(for configuration: Configuration) async {
            guard
                let coordinator = context.coordinator,
                let publisher = await coordinator.stateAdapter.publisher,
                let subscriber = await coordinator.stateAdapter.subscriber
            else {
                return
            }

            switch configuration {
            case .publisherOnly:
                await waitForPeerConnectionToBePrepared(
                    publisher,
                    subsystem: .peerConnectionPublisher,
                    timeout: timeout
                )
            case .publisherAndSubscriber:
                await withTaskGroup(of: Void.self) { [timeout] group in
                    group.addTask { [weak self] in
                        await self?.waitForPeerConnectionToBePrepared(
                            publisher,
                            subsystem: .peerConnectionPublisher,
                            timeout: timeout
                        )
                    }

                    group.addTask { [weak self] in
                        await self?.waitForPeerConnectionToBePrepared(
                            subscriber,
                            subsystem: .peerConnectionSubscriber,
                            timeout: timeout
                        )
                    }

                    await group.waitForAll()
                }
            }
        }

        private func waitForPeerConnectionToBePrepared(
            _ peerConnection: RTCPeerConnectionCoordinator,
            subsystem: LogSubsystem,
            timeout: TimeInterval
        ) async {
            do {
                _ = try await peerConnection
                    .connectionStatePublisher
                    .log(.debug, subsystems: subsystem) { "PeerConnection transitioned to \($0)" }
                    .filter { $0 == .connected }
                    .nextValue(timeout: timeout)
            } catch {
                log.warning(
                    "PeerConnection wasn't ready in \(timeout) seconds. We continue joining and the connections should be ready after completing.",
                    subsystems: subsystem
                )
            }
        }

        private func reportTelemetryAndCompletion() async {
            guard
                let coordinator = context.coordinator,
                let sfuAdapter = await coordinator.stateAdapter.sfuAdapter
            else {
                return
            }

            let sessionID = await coordinator.stateAdapter.sessionID
            let unifiedSessionId = coordinator.stateAdapter.unifiedSessionId

            // We dispatch to a task to avoid blocking the call transition
            // while the telemetry is being reported.
            Task { [sessionID, unifiedSessionId, sfuAdapter] in
                await telemetryReporter.reportTelemetry(
                    sessionId: sessionID,
                    unifiedSessionId: unifiedSessionId,
                    sfuAdapter: sfuAdapter
                )
            }

            reportJoinCompletion()
        }
    }
}
