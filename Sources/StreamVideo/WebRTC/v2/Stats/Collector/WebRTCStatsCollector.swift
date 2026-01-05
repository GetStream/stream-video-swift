//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

/// A collector responsible for gathering WebRTC call statistics.
///
/// This class collects metrics from publisher and subscriber peer
/// connections at a configurable interval and generates a unified
/// `CallStatsReport`. The report is built using the
/// `StreamCallStatisticsReporter` and includes audio/video track mappings.
///
/// The collected stats are published to subscribers via the `report`
/// property. The collector can be configured with an `SFUAdapter` and
/// will start periodic collection upon setting it.
final class WebRTCStatsCollector: WebRTCStatsCollecting, @unchecked Sendable {

    /// The most recent `CallStatsReport` generated from collected stats.
    ///
    /// Observers can subscribe to this publisher to receive updates.
    @Published private(set) var report: CallStatsReport?
    var reportPublisher: AnyPublisher<CallStatsReport?, Never> { $report.eraseToAnyPublisher() }

    /// The peer connection used for publishing local media.
    ///
    /// Stats from this connection contribute to the outbound part of the report.
    var publisher: RTCPeerConnectionCoordinator?

    /// The peer connection used for receiving remote media.
    ///
    /// Stats from this connection contribute to the inbound part of the report.
    var subscriber: RTCPeerConnectionCoordinator?

    /// The adapter responsible for forwarding metrics to the SFU.
    ///
    /// Setting this property automatically starts or resets the periodic
    /// collection process.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The interval in seconds at which statistics are collected.
    ///
    /// Changing this property will reschedule the timer used for stat collection.
    var interval: TimeInterval { didSet { scheduleCollection(with: interval) } }

    private let trackStorage: WebRTCTrackStorage

    /// Cancellable for the collection timer.
    private var collectionCancellable: AnyCancellable?

    /// The currently active task for collecting statistics.
    private var activeCollectionTask: Task<Void, Never>?

    /// A helper object for building call statistics reports.
    private lazy var callStatisticsReporter = StreamCallStatisticsReporter()

    init(
        interval: TimeInterval = 2,
        trackStorage: WebRTCTrackStorage
    ) {
        self.interval = interval
        self.trackStorage = trackStorage
    }

    /// Configures a repeating timer to trigger statistics collection.
    ///
    /// - Parameter interval: The frequency in seconds at which to collect stats.
    ///   If 0 or less, the timer is cancelled and no collection occurs.
    private func scheduleCollection(with interval: TimeInterval) {
        guard interval > 0 else {
            log.warning("Collection interval should be greater than 0.", subsystems: .webRTC)
            collectionCancellable?.cancel()
            return
        }

        collectionCancellable?.cancel()
        collectionCancellable = DefaultTimer
            .publish(every: interval)
            .receive(on: DispatchQueue.global(qos: .utility))
            .log(.debug, subsystems: .webRTC) { _ in "Will collect stats." }
            .sink { [weak self] _ in self?.collectStats() }

        log.debug(
            "Stats collection is now scheduled with interval:\(interval).",
            subsystems: .webRTC
        )
    }

    /// Starts a new async task to gather statistics from both peer connections.
    ///
    /// Cancels any existing task before starting a new one. If both connections
    /// are available, the task gathers stats, generates a report, and publishes it.
    private func collectStats() {
        activeCollectionTask?.cancel()
        // swiftlint:disable discourage_task_init
        activeCollectionTask = Task { [weak self] in
            guard
                let self,
                let hostname = sfuAdapter?.hostname
            else {
                return
            }

            do {
                async let statsPublisher = publisher?.statsReport() ?? .init(nil)
                async let statsSubscriber = subscriber?.statsReport() ?? .init(nil)

                try Task.checkCancellation()
                let result: [StreamRTCStatisticsReport] = try await [statsPublisher, statsSubscriber]

                let report = callStatisticsReporter.buildReport(
                    publisherReport: result.first ?? .init(nil),
                    subscriberReport: result.last ?? .init(nil),
                    datacenter: hostname,
                    trackToKindMap: trackStorage.snapshot
                )

                try Task.checkCancellation()
                self.report = report
            } catch {
                log.error(error, subsystems: .webRTC)
            }
        }
        // swiftlint:enable discourage_task_init
    }

    /// Resets collection when the SFU adapter is updated.
    ///
    /// Cancels existing tasks and timers, then restarts collection if needed.
    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        activeCollectionTask?.cancel()
        collectionCancellable?.cancel()

        guard sfuAdapter != nil else {
            return
        }

        scheduleCollection(with: interval)
    }
}
