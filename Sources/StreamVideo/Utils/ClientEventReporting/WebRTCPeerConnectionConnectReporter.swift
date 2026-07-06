//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// Observes a single peer connection's connection and ICE state and reports the
/// matching ``ClientEventStage/peerConnectionConnect`` `initiated` / `completed`
/// pair through a ``ClientEventReporting``.
///
/// A `PeerConnectionConnect` `initiated` event is emitted when either state
/// starts progressing. The `completed` event succeeds only after both the
/// connection and ICE states are connected, and fails as soon as either state
/// fails. A raw ICE failure carries `ICE_CONNECTIVITY_FAILED`; aggregate
/// peer-connection failures without raw ICE failure are completed without a
/// specific failure code until a precise non-ICE signal is available.
/// A peer connection that never leaves `new` (for example the publisher of a
/// subscribe-only viewer) emits nothing, which the backend correctly treats as
/// "not attempted".
final class WebRTCPeerConnectionConnectReporter: @unchecked Sendable {

    private let reporter: ClientEventReporting
    private let peerConnection: ClientEventPeerConnection
    private let details: ClientEventStageDetails
    private let retryCount: Int
    private let disposableBag = DisposableBag()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)
    private var attempt: ClientEventStageAttempt?
    private var didResolve = false

    /// Starts observing a peer connection.
    ///
    /// - Parameters:
    ///   - peerConnectionType: The internal peer-connection type, mapped to the
    ///     wire `publish` / `subscribe` value.
    ///   - statePublisher: The connection-state stream to observe.
    ///   - iceStatePublisher: The ICE-state stream to observe.
    ///   - reporter: The reporter that delivers the events.
    ///   - wasPreviouslyConnected: Whether the ICE connection had been
    ///     established earlier in the same session (a reconnect).
    ///   - retryCount: Retry count to attach to the completion event.
    ///   - details: Stage-specific identifiers (sfu id, session ids) included
    ///     on every emitted event.
    init(
        peerConnectionType: PeerConnectionType,
        statePublisher: AnyPublisher<RTCPeerConnectionState, Never>,
        iceStatePublisher: AnyPublisher<RTCIceConnectionState, Never>,
        reporter: ClientEventReporting,
        wasPreviouslyConnected: Bool,
        retryCount: Int = 0,
        details: ClientEventStageDetails
    ) {
        self.reporter = reporter
        peerConnection = .init(peerConnectionType)
        self.details = details.merging(.init(wasPreviouslyConnected: wasPreviouslyConnected))
        self.retryCount = retryCount

        Publishers.CombineLatest(
            statePublisher.prepend(.new),
            iceStatePublisher.prepend(.new)
        )
        .removeDuplicates { $0 == $1 }
        .sinkTask(queue: processingQueue) { [weak self] in
            await self?.consume(connectionState: $0, iceConnectionState: $1)
        }
        .store(in: disposableBag)
    }

    /// Stops observing without reporting a completion.
    func stop() {
        disposableBag.removeAll()
    }

    // MARK: - Private

    private func consume(
        connectionState: RTCPeerConnectionState,
        iceConnectionState: RTCIceConnectionState
    ) async {
        guard !didResolve else { return }

        if connectionState == .failed || iceConnectionState == .failed {
            await complete(
                outcome: .failure,
                connectionState: connectionState,
                iceConnectionState: iceConnectionState
            )
            return
        }

        if connectionState == .connected && (iceConnectionState == .connected || iceConnectionState == .completed) {
            await complete(
                outcome: .success,
                connectionState: connectionState,
                iceConnectionState: iceConnectionState
            )
        } else if connectionState.isConnecting || iceConnectionState.isConnecting {
            let attempt = await begin()
            // Keep the pending attempt's ICE state current so a completion
            // forced by an abort (user leave / backend end) mid-connect still
            // reports the last observed ICE state instead of omitting it.
            await reporter.updateStage(
                attempt,
                details: .init(iceState: ClientEventICEState(iceConnectionState))
            )
        }
    }

    private func begin() async -> ClientEventStageAttempt {
        if let attempt {
            return attempt
        }

        let attempt = await reporter.beginStage(
            .peerConnectionConnect,
            peerConnection: peerConnection,
            details: details
        )
        self.attempt = attempt
        return attempt
    }

    private func complete(
        outcome: ClientEventOutcome,
        connectionState: RTCPeerConnectionState,
        iceConnectionState: RTCIceConnectionState
    ) async {
        didResolve = true

        let attempt = await begin()
        let clientEventICEState = ClientEventICEState(iceConnectionState)

        let failure: ClientEventFailure? = {
            guard outcome == .failure else {
                return nil
            }
            if iceConnectionState == .failed {
                return .init(code: .iceConnectivityFailed)
            } else {
                return nil
            }
        }()

        await reporter.completeStage(
            attempt,
            outcome: outcome,
            retryCount: retryCount,
            details: .init(iceState: clientEventICEState),
            failure: failure
        )
        stop()
    }
}

private extension RTCPeerConnectionState {
    var isConnecting: Bool {
        switch self {
        case .connecting, .connected:
            return true
        default:
            return false
        }
    }
}

private extension RTCIceConnectionState {
    var isConnecting: Bool {
        switch self {
        case .checking, .connected, .completed:
            return true
        default:
            return false
        }
    }
}

private extension ClientEventICEState {
    init(_ source: RTCIceConnectionState) {
        switch source {
        case .new:
            self = .notConnected
        case .checking:
            self = .notConnected
        case .connected:
            self = .connected
        case .completed:
            self = .connected
        case .failed:
            self = .failed
        case .disconnected:
            self = .failed
        case .closed:
            self = .failed
        case .count:
            self = .notConnected
        @unknown default:
            self = .notConnected
        }
    }
}
