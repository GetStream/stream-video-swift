//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// An adapter that observes ICE connection state changes from the WebRTC peer
/// connection and schedules reconnection attempts when necessary.
final class ICEConnectionStateAdapter {

    /// The peer connection coordinator to observe for ICE state changes.
    weak var peerConnectionCoordinator: RTCPeerConnectionCoordinator? {
        didSet { didUpdate(peerConnectionCoordinator) }
    }

    /// A cancellable for the ICE state subscription.
    private var peerConnectionICEStateCancellable: AnyCancellable?

    /// A cancellable for the scheduled ICE restart timer.
    private var scheduledRestartICECancellable: AnyCancellable?

    /// The interval after which to restart ICE when disconnected.
    private let scheduleICERestartInterval: TimeInterval

    /// A serial queue for processing ICE state events.
    private let processingQueue = DispatchQueue(
        label: "io.getstream.ICEConnectionStateAdapter"
    )

    /// Creates a new ICEConnectionStateAdapter instance.
    ///
    /// - Parameter scheduleICERestartInterval: The time interval after a
    ///   disconnection to schedule an ICE restart. Default is 3 seconds.
    init(scheduleICERestartInterval: TimeInterval = 3) {
        self.scheduleICERestartInterval = scheduleICERestartInterval
    }

    /// Responds to ICE connection state changes and performs the appropriate
    /// action depending on the new state.
    ///
    /// - Parameter state: The current ICE connection state.
    ///   - If the state is `.failed`, ICE will be restarted immediately.
    ///   - If the state is `.disconnected`, ICE will be scheduled to restart
    ///     after a short delay.
    ///   - If the state is `.connected`, any pending restart will be cancelled.
    private func didUpdate(_ state: RTCIceConnectionState) {
        switch state {
        case .failed:
            restartICE()

        case .disconnected:
            scheduledRestartICECancellable = DefaultTimer
                .publish(every: scheduleICERestartInterval)
                .sink { [weak self] _ in self?.restartICE() }

        case .connected:
            scheduledRestartICECancellable?.cancel()
            scheduledRestartICECancellable = nil

        default:
            break
        }
    }

    /// Cancels any scheduled ICE restart and restarts ICE immediately.
    private func restartICE() {
        scheduledRestartICECancellable?.cancel()
        scheduledRestartICECancellable = nil
        peerConnectionCoordinator?.restartICE()
    }

    /// Subscribes to ICE connection state events from the coordinator and
    /// cancels previous subscriptions when the coordinator changes.
    ///
    /// - Parameter peerConnectionCoordinator: The coordinator to observe.
    private func didUpdate(
        _ peerConnectionCoordinator: RTCPeerConnectionCoordinator?
    ) {
        guard let peerConnectionCoordinator else {
            peerConnectionICEStateCancellable?.cancel()
            peerConnectionICEStateCancellable = nil

            scheduledRestartICECancellable?.cancel()
            scheduledRestartICECancellable = nil

            return
        }

        peerConnectionICEStateCancellable = peerConnectionCoordinator
            .eventPublisher
            .compactMap { $0 as? StreamRTCPeerConnection.ICEConnectionChangedEvent }
            .map(\.state)
            .receive(on: processingQueue)
            .removeDuplicates()
            .log(.debug) { "ICE connection state changed to: \($0)" }
            .sink { [weak self] in self?.didUpdate($0) }
    }
}
