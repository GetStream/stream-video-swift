//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

final class WebRTCStatsCollector: @unchecked Sendable {

    @Published private(set) var report: CallStatsReport?

    /// The publisher peer connection from which to collect statistics.
    var publisher: RTCPeerConnectionCoordinator?

    /// The subscriber peer connection from which to collect statistics.
    var subscriber: RTCPeerConnectionCoordinator?

    /// The SFU adapter used to send collected statistics.
    ///
    /// Setting this property triggers a reset of the collection and delivery processes.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The interval at which statistics are collected, in seconds. Defaults to 2.
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

    /// Schedules the periodic collection of statistics.
    ///
    /// - Parameter interval: The interval at which to collect statistics, in seconds.
    private func scheduleCollection(with interval: TimeInterval) {
        guard interval > 0 else {
            log.warning("Collection interval should be greater than 0.", subsystems: .webRTC)
            collectionCancellable?.cancel()
            return
        }

        collectionCancellable?.cancel()
        collectionCancellable = Foundation
            .Timer
            .publish(every: interval, on: .main, in: .default)
            .autoconnect()
            .log(.debug, subsystems: .webRTC) { _ in "Will collect stats." }
            .sink { [weak self] _ in self?.collectStats() }

        log.debug(
            "Stats collection is now scheduled with interval:\(interval).",
            subsystems: .webRTC
        )
    }

    /// Collects statistics from the publisher and subscriber peer connections.
    ///
    /// This method creates a new task for collecting stats, cancelling any existing collection task.
    private func collectStats() {
        activeCollectionTask?.cancel()
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
    }

    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        activeCollectionTask?.cancel()
        collectionCancellable?.cancel()

        guard sfuAdapter != nil else {
            return
        }

        scheduleCollection(with: interval)
    }
}
