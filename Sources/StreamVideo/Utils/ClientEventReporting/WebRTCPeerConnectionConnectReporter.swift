//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Observes a single peer connection's connection state and reports the
/// matching ``ClientEventStage/peerConnectionConnect`` `initiated` / `completed`
/// pair through a ``ClientEventReporting``.
///
/// A `PeerConnectionConnect` `initiated` event is emitted when the connection
/// starts negotiating, and the `completed` event is emitted when it reaches a
/// terminal state (`connected` → success, `failed` → failure). A peer
/// connection that never leaves `new` (for example the publisher of a
/// subscribe-only viewer) emits nothing, which the backend correctly treats as
/// "not attempted".
final class WebRTCPeerConnectionConnectReporter: @unchecked Sendable {

    private let reporter: ClientEventReporting
    private let peerConnection: ClientEventPeerConnection
    private let details: ClientEventStageDetails
    private let disposableBag = DisposableBag()
    private var continuation: AsyncStream<RTCPeerConnectionState>.Continuation?

    /// Starts observing a peer connection.
    ///
    /// - Parameters:
    ///   - peerConnectionType: The internal peer-connection type, mapped to the
    ///     wire `publish` / `subscribe` value.
    ///   - statePublisher: The connection-state stream to observe.
    ///   - reporter: The reporter that delivers the events.
    ///   - wasPreviouslyConnected: Whether the ICE connection had been
    ///     established earlier in the same session (a reconnect).
    ///   - details: Stage-specific identifiers (sfu id, session ids) included
    ///     on every emitted event.
    init(
        peerConnectionType: PeerConnectionType,
        statePublisher: AnyPublisher<RTCPeerConnectionState, Never>,
        reporter: ClientEventReporting,
        wasPreviouslyConnected: Bool,
        details: ClientEventStageDetails
    ) {
        self.reporter = reporter
        peerConnection = .init(peerConnectionType)
        self.details = details.merging(.init(wasPreviouslyConnected: wasPreviouslyConnected))

        var capturedContinuation: AsyncStream<RTCPeerConnectionState>.Continuation?
        let stream = AsyncStream<RTCPeerConnectionState> { continuation in
            capturedContinuation = continuation
            let cancellable = statePublisher.sink { continuation.yield($0) }
            continuation.onTermination = { _ in cancellable.cancel() }
        }
        continuation = capturedContinuation

        Task(disposableBag: disposableBag) { [weak self] in
            await self?.consume(stream)
            // Tear down the underlying subscription once the connection
            // resolves so it does not keep buffering state changes.
            self?.continuation?.finish()
        }
    }

    /// Stops observing without reporting a completion.
    func stop() {
        continuation?.finish()
        disposableBag.removeAll()
    }

    // MARK: - Private

    private func consume(_ stream: AsyncStream<RTCPeerConnectionState>) async {
        var attempt: ClientEventStageAttempt?

        func begin() async -> ClientEventStageAttempt {
            if let attempt {
                return attempt
            }
            let new = await reporter.beginStage(
                .peerConnectionConnect,
                peerConnection: peerConnection,
                details: details
            )
            attempt = new
            return new
        }

        for await state in stream {
            switch state {
            case .connecting:
                _ = await begin()

            case .connected:
                let attempt = await begin()
                await reporter.completeStage(
                    attempt,
                    outcome: .success,
                    retryCount: 0,
                    details: .init(iceState: .connected),
                    failure: nil
                )
                return

            case .failed:
                let attempt = await begin()
                await reporter.completeStage(
                    attempt,
                    retryCount: 0,
                    details: .init(iceState: .failed),
                    failure: .init(code: .iceConnectivityFailed)
                )
                return

            default:
                // `.new`, `.disconnected`, `.closed` are transient or teardown
                // states and do not resolve the connect attempt.
                break
            }
        }
    }
}
