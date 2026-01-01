//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A class responsible for collecting and reporting WebRTC statistics.
///
/// This class manages the periodic collection of statistics from WebRTC peer connections
/// and sends these statistics to an SFU (Selective Forwarding Unit) adapter.
///
final class WebRTCStatsReporter: WebRTCStatsReporting, @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    struct Input: @unchecked Sendable {
        var sessionID: String
        var unifiedSessionID: String
        var report: CallStatsReport
        var peerConnectionTraces: [WebRTCTrace]
        var encoderPerformanceStats: [Stream_Video_Sfu_Models_PerformanceStats]
        var decoderPerformanceStats: [Stream_Video_Sfu_Models_PerformanceStats]
        var onError: (Error) -> Void
    }

    /// The interval at which statistics are collected and reported, in seconds.
    ///
    /// Setting this property automatically reschedules the delivery timer.
    var interval: TimeInterval { didSet { scheduleDelivery(with: interval) } }

    /// The SFU adapter used to send collected statistics.
    ///
    /// Setting this property triggers a reset of the collection and delivery processes.
    var sfuAdapter: SFUAdapter? { willSet { didUpdate(newValue) } }

    private let provider: () -> Input?

    /// Cancellable for the delivery subscription.
    private var deliveryCancellable: AnyCancellable?

    /// The currently active task for delivering statistics.
    private var activeDeliveryTask: Task<Void, Never>?

    /// Initializes a new WebRTCStatsReporter.
    ///
    /// - Parameters:
    ///   - collectionInterval: The interval at which we collect statistics, in seconds. Defaults to 2.
    ///   - deliveryInterval: The interval at which we report statistics, in seconds. Defaults to 5.
    ///   5 seconds.
    ///   - sessionID: The session ID associated with this reporter.
    ///   - tracesAdapter: The adapter to be used to get access on enqueued traces
    init(
        interval: TimeInterval = 5,
        provider: @escaping () -> Input?
    ) {
        self.interval = interval
        self.provider = provider
    }

    deinit {
        sfuAdapter = nil
        // Cancel all active tasks and subscriptions
        deliveryCancellable?.cancel()
        activeDeliveryTask?.cancel()
    }

    // MARK: - Manual trigger

    func triggerDelivery() {
        guard
            let input = provider()
        else {
            return
        }
        deliverStats(input)
    }

    // MARK: - Private helpers

    /// Updates the reporter's state when a new SFU adapter is set.
    ///
    /// This method cancels any existing tasks and subscriptions, and sets up new ones if an adapter
    /// is provided.
    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        activeDeliveryTask?.cancel()
        activeDeliveryTask = nil

        guard sfuAdapter != nil else {
            return
        }

        scheduleDelivery(with: interval)
        log.debug("Delivery scheduled on hostname:\(sfuAdapter?.hostname) with interval:\(interval) seconds.")
    }

    private func scheduleDelivery(with interval: TimeInterval) {
        deliveryCancellable?.cancel()
        deliveryCancellable = nil

        guard interval > 0 else {
            log.warning("Delivery interval should be greater than 0.", subsystems: .webRTC)
            return
        }

        deliveryCancellable = DefaultTimer
            .publish(every: interval)
            .compactMap { [weak self] _ in self?.provider() }
            .sink { [weak self] in self?.deliverStats($0) }
    }

    /// Delivers the collected statistics to the SFU adapter.
    ///
    /// - Parameter report: The statistics report to deliver.
    private func deliverStats(_ input: Input) {
        guard activeDeliveryTask == nil else {
            return
        }

        log.debug(
            "Will deliver stats report timestamp:\(input.report.timestamp) on hostname: \(sfuAdapter?.host)",
            subsystems: .webRTC
        )

        activeDeliveryTask?.cancel()
        // swiftlint:disable discourage_task_init
        activeDeliveryTask = Task { [weak self] in
            do {
                guard let self, let sfuAdapter else {
                    throw ClientError("Unable to deliver stats while SFU is unavailable.")
                }

                try Task.checkCancellation()

                let tracesData = try JSONEncoder
                    .stream
                    .encode(input.peerConnectionTraces)
                let traces = String(data: tracesData, encoding: .utf8)

                try Task.checkCancellation()

                try await sfuAdapter.sendStats(
                    input.report,
                    for: input.sessionID,
                    unifiedSessionId: input.unifiedSessionID,
                    traces: traces,
                    thermalState: thermalStateObserver.state,
                    encodeStats: input.encoderPerformanceStats,
                    decodeStats: input.decoderPerformanceStats
                )
            } catch {
                input.onError(error)
                log.error(error, subsystems: .webRTC)
            }
            self?.activeDeliveryTask = nil
        }
        // swiftlint:enable discourage_task_init
    }
}
