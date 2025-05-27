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
actor WebRTCStatsReporter: @unchecked Sendable {

    @Injected(\.thermalStateObserver) private var thermalStateObserver
    @Injected(\.timers) private var timers

    /// The session ID associated with this reporter.
    var sessionID: String

    /// The publisher peer connection from which to collect statistics.
    var publisher: RTCPeerConnectionCoordinator?

    /// The subscriber peer connection from which to collect statistics.
    var subscriber: RTCPeerConnectionCoordinator?

    /// The interval at which statistics are collected and reported, in seconds.
    ///
    /// Setting this property automatically reschedules the delivery timer.
    var deliveryInterval: TimeInterval { didSet { scheduleDelivery(with: deliveryInterval) } }

    /// The SFU adapter used to send collected statistics.
    ///
    /// Setting this property triggers a reset of the collection and delivery processes.
    var sfuAdapter: SFUAdapter? { didSet { didUpdate(sfuAdapter) } }

    /// The interval at which statistics are collected, in seconds. Defaults to 2.
    private var collectionInterval: TimeInterval { didSet { scheduleCollection(with: collectionInterval) } }

    /// Cancellable for the collection timer.
    private var collectionCancellable: AnyCancellable?

    /// Cancellable for the delivery subscription.
    private var deliveryCancellable: AnyCancellable?

    /// A helper object for building call statistics reports.
    private lazy var callStatisticsReporter = StreamCallStatisticsReporter()

    /// A subject for publishing the latest collected statistics report.
    private let latestReportSubject = CurrentValueSubject<CallStatsReport?, Never>(nil)

    private let disposableBag = DisposableBag()

    private let executor: DispatchQueueExecutor
    nonisolated var unownedExecutor: UnownedSerialExecutor { .init(ordinary: executor) }

    /// A publisher for the latest statistics report.
    nonisolated var latestReportPublisher: AnyPublisher<CallStatsReport, Never> {
        latestReportSubject
            .compactMap { $0 }
            .eraseToAnyPublisher()
    }

    /// Initializes a new WebRTCStatsReporter.
    ///
    /// - Parameters:
    ///   - collectionInterval: The interval at which we collect statistics, in seconds. Defaults to 2.
    ///   - deliveryInterval: The interval at which we report statistics, in seconds. Defaults to 5.
    ///   5 seconds.
    ///   - sessionID: The session ID associated with this reporter.
    init(
        collectionInterval: TimeInterval = 2,
        deliveryInterval: TimeInterval = 5,
        sessionID: String
    ) {
        self.executor = .init()
        self.collectionInterval = collectionInterval
        self.deliveryInterval = deliveryInterval
        self.sessionID = sessionID
    }

    deinit {
        sfuAdapter = nil
        // Cancel all active tasks and subscriptions
        collectionCancellable?.cancel()
        deliveryCancellable?.cancel()
        disposableBag.removeAll()
    }

    func set(deliveryInterval: TimeInterval) {
        self.deliveryInterval = deliveryInterval
    }

    func set(sfuAdapter: SFUAdapter?) {
        self.sfuAdapter = sfuAdapter
    }

    func configure(
        deliveryInterval: TimeInterval,
        publisher: RTCPeerConnectionCoordinator?,
        subscriber: RTCPeerConnectionCoordinator?,
        sfuAdapter: SFUAdapter?
    ) {
        self.deliveryInterval = deliveryInterval
        self.publisher = publisher
        self.subscriber = subscriber
        self.sfuAdapter = sfuAdapter
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

        scheduleCollection(with: collectionInterval)
        scheduleDelivery(with: deliveryInterval)
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
        collectionCancellable = timers
            .timer(for: interval)
            .log(.debug, subsystems: .webRTC) { _ in "Will collect stats." }
            .sinkTask(storeIn: disposableBag) { [weak self] _ in await self?.collectStats() }

        log.debug(
            "Stats collection is now scheduled with interval:\(interval).",
            subsystems: .webRTC
        )
    }

    private func scheduleDelivery(with interval: TimeInterval) {
        guard interval > 0 else {
            log.warning("Delivery interval should be greater than 0.", subsystems: .webRTC)
            deliveryCancellable?.cancel()
            return
        }

        deliveryCancellable?.cancel()
        deliveryCancellable = timers
            .timer(for: interval)
            .compactMap { [weak self] _ in self?.latestReportSubject.value }
//            .log(.debug, subsystems: .webRTC) { [weak self] in
//                "Will deliver stats report (timestamp:\($0.timestamp)) on \(self?.sfuAdapter?.hostname ?? "-")."
//            }
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.deliverStats(report: $0) }
    }

    /// Collects statistics from the publisher and subscriber peer connections.
    ///
    /// This method creates a new task for collecting stats, cancelling any existing collection task.
    private func collectStats() async {
        guard
            let hostname = sfuAdapter?.hostname
        else {
            return
        }

        do {
            try Task.checkCancellation()

            let report = callStatisticsReporter.buildReport(
                publisherReport: try await publisher?.statsReport() ?? .init(nil),
                subscriberReport: try await subscriber?.statsReport() ?? .init(nil),
                datacenter: hostname
            )

            try Task.checkCancellation()
            latestReportSubject.send(report)
        } catch {
            log.error(error, subsystems: .webRTC)
        }
    }

    /// Delivers the collected statistics to the SFU adapter.
    ///
    /// - Parameter report: The statistics report to deliver.
    private func deliverStats(report: CallStatsReport) async {
        do {
            try Task.checkCancellation()
            try await sfuAdapter?.sendStats(
                report,
                for: sessionID,
                thermalState: thermalStateObserver.state
            )
        } catch {
            log.error(error, subsystems: .webRTC)
        }
    }
}

extension StreamRTCStatisticsReport: @unchecked Sendable {}
