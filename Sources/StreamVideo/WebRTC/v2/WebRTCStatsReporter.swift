//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

import Combine
import Foundation

/// A class responsible for collecting and reporting WebRTC statistics.
///
/// This class manages the periodic collection of statistics from WebRTC peer connections
/// and sends these statistics to an SFU (Selective Forwarding Unit) adapter.
///
final class WebRTCStatsReporter: @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver

    /// The session ID associated with this reporter.
    var sessionID: String

    /// The publisher peer connection from which to collect statistics.
    var publisher: RTCPeerConnectionCoordinator?

    /// The subscriber peer connection from which to collect statistics.
    var subscriber: RTCPeerConnectionCoordinator?

    /// The interval at which statistics are collected and reported, in seconds.
    ///
    /// Setting this property automatically reschedules the collection timer.
    var interval: TimeInterval { didSet { scheduleCollection(with: interval) } }

    /// The SFU adapter used to send collected statistics.
    ///
    /// Setting this property triggers a reset of the collection and delivery processes.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// Cancellable for the collection timer.
    private var collectionCancellable: AnyCancellable?

    /// Cancellable for the delivery subscription.
    private var deliveryCancellable: AnyCancellable?

    /// The currently active task for collecting statistics.
    private var activeCollectionTask: Task<Void, Never>?

    /// The currently active task for delivering statistics.
    private var activeDeliveryTask: Task<Void, Never>?

    /// A helper object for building call statistics reports.
    private lazy var callStatisticsReporter = StreamCallStatisticsReporter()

    /// A subject for publishing the latest collected statistics report.
    private let latestReportSubject = PassthroughSubject<CallStatsReport, Never>()

    /// A publisher for the latest statistics report.
    var latestReportPublisher: AnyPublisher<CallStatsReport, Never> {
        latestReportSubject.eraseToAnyPublisher()
    }

    /// Initializes a new WebRTCStatsReporter.
    ///
    /// - Parameters:
    ///   - interval: The interval at which to collect and report statistics, in seconds. Defaults to
    ///   5 seconds.
    ///   - sessionID: The session ID associated with this reporter.
    init(
        interval: TimeInterval = 5,
        sessionID: String
    ) {
        self.interval = interval
        self.sessionID = sessionID
    }

    deinit {
        sfuAdapter = nil
        // Cancel all active tasks and subscriptions
        activeCollectionTask?.cancel()
        collectionCancellable?.cancel()
        deliveryCancellable?.cancel()
        activeDeliveryTask?.cancel()
    }

    // MARK: - Private helpers

    /// Updates the reporter's state when a new SFU adapter is set.
    ///
    /// This method cancels any existing tasks and subscriptions, and sets up new ones if an adapter
    /// is provided.
    private func didUpdate(_ sfuAdapter: SFUAdapter?) {
        activeDeliveryTask?.cancel()
        deliveryCancellable?.cancel()
        activeCollectionTask?.cancel()
        collectionCancellable?.cancel()

        guard sfuAdapter != nil else {
            return
        }

        scheduleCollection(with: interval)
        deliveryCancellable = latestReportSubject
            .sink { [weak self] in self?.deliverStats(report: $0) }
    }

    /// Schedules the periodic collection of statistics.
    ///
    /// - Parameter interval: The interval at which to collect statistics, in seconds.
    private func scheduleCollection(with interval: TimeInterval) {
        guard interval > 0 else {
            log.warning("Collection interval should be greater than 0.")
            collectionCancellable?.cancel()
            return
        }

        collectionCancellable?.cancel()
        collectionCancellable = Foundation
            .Timer
            .publish(every: interval, on: .main, in: .default)
            .autoconnect()
            .sink { [weak self] _ in self?.collectStats() }

        log.debug("Stats collection is now scheduled with interval:\(interval).")
    }

    /// Collects statistics from the publisher and subscriber peer connections.
    ///
    /// This method creates a new task for collecting stats, cancelling any existing collection task.
    private func collectStats() {
        activeCollectionTask?.cancel()
        activeCollectionTask = Task { [weak self] in
            guard let self, let hostname = sfuAdapter?.hostname else { return }
            do {
                async let statsPublisher = publisher?.statsReport()
                async let statsSubscriber = subscriber?.statsReport()

                try Task.checkCancellation()
                let result = try await [statsPublisher, statsSubscriber]

                let report = callStatisticsReporter.buildReport(
                    publisherReport: .init(result[safe: 0] ?? nil),
                    subscriberReport: .init(result[safe: 1] ?? nil),
                    datacenter: hostname
                )

                try Task.checkCancellation()
                latestReportSubject.send(report)
            } catch {
                log.error(error)
            }
        }
    }

    /// Delivers the collected statistics to the SFU adapter.
    ///
    /// - Parameter report: The statistics report to deliver.
    private func deliverStats(report: CallStatsReport) {
        activeDeliveryTask?.cancel()
        activeDeliveryTask = Task { [weak self] in
            do {
                guard let self else { return }

                try Task.checkCancellation()
                try await sfuAdapter?.sendStats(
                    report,
                    for: sessionID,
                    thermalState: thermalStateObserver.state
                )
            } catch {
                log.error(error)
            }
        }
    }
}
