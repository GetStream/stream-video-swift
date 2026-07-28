//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import Network

extension Notification.Name {
    /// Posted when any the Internet connection update is detected (including quality updates).
    static let internetConnectionStatusDidChange = Self("io.getstream.StreamChat.internetConnectionStatus")

    /// Posted only when the Internet connection availability is changed (excluding quality updates).
    static let internetConnectionAvailabilityDidChange = Self("io.getstream.StreamChat.internetConnectionAvailability")
}

extension Notification {
    static let internetConnectionStatusUserInfoKey = "internetConnectionStatus"

    var internetConnectionStatus: InternetConnectionStatus? {
        userInfo?[Self.internetConnectionStatusUserInfoKey] as? InternetConnectionStatus
    }
}

/// StreamVideo's internet connection monitor.
///
/// StreamVideo retains this implementation instead of using
/// `StreamCore.InternetConnection` directly to preserve its existing delivery
/// semantics:
///
/// - Monitor updates are serialized onto `DispatchQueue.main` before `status`
///   changes.
/// - `statusPublisher` debounces updates by 100 milliseconds so brief path
///   changes do not trigger reconnection work.
/// - Status and availability changes use StreamVideo's historical notification
///   names.
///
/// StreamCore exposes the same status model and `NWPathMonitor`-based
/// monitoring, but updates status on the monitor's queue, does not debounce its
/// publisher, and posts different notification names.
final class VideoInternetConnection: @unchecked Sendable {
    /// The current Internet connection status.
    @Published private(set) var status: InternetConnectionStatus {
        didSet {
            postNotification(.internetConnectionStatusDidChange, with: status)

            guard oldValue.isAvailable != status.isAvailable else { return }

            postNotification(.internetConnectionAvailabilityDidChange, with: status)
        }
    }

    private let subject: PassthroughSubject<InternetConnectionStatus, Never> = .init()
    private var processingCancellable: AnyCancellable?

    /// The notification center that posts notifications when connection state changes..
    let notificationCenter: NotificationCenter

    /// A specific Internet connection monitor.
    private var monitor: InternetConnectionMonitor

    /// Creates a `InternetConnection` with a given monitor.
    /// - Parameter monitor: an Internet connection monitor. Use nil for a default `InternetConnectionMonitor`.
    init(
        notificationCenter: NotificationCenter = .default,
        monitor: InternetConnectionMonitor
    ) {
        self.notificationCenter = notificationCenter
        self.monitor = monitor
        self.status = monitor.status

        processingCancellable = subject
            .removeDuplicates()
            .log(.debug) { "Internet Connection: \($0)" }
            .receive(on: DispatchQueue.main)
            .assign(to: \.status, onWeak: self)

        monitor.delegate = self
        monitor.start()
    }

    deinit {
        monitor.stop()
    }
}

extension VideoInternetConnection: InternetConnectionDelegate {
    func internetConnectionStatusDidChange(status: InternetConnectionStatus) {
        subject.send(status)
    }
}

private extension VideoInternetConnection {
    func postNotification(_ name: Notification.Name, with status: InternetConnectionStatus) {
        notificationCenter.post(
            name: name,
            object: self,
            userInfo: [Notification.internetConnectionStatusUserInfoKey: status]
        )
    }
}

// MARK: - Internet Connection Monitors

/// A delegate to receive Internet connection events.
protocol InternetConnectionDelegate: AnyObject {
    /// Calls when the Internet connection status did change.
    /// - Parameter status: an Internet connection status.
    func internetConnectionStatusDidChange(status: InternetConnectionStatus)
}

/// A protocol for Internet connection monitors.
protocol InternetConnectionMonitor: AnyObject {
    /// A delegate for receiving Internet connection events.
    var delegate: InternetConnectionDelegate? { get set }

    /// The current status of Internet connection.
    var status: InternetConnectionStatus { get }

    /// Start Internet connection monitoring.
    func start()
    /// Stop Internet connection monitoring.
    func stop()
}

// MARK: - Internet Connection Monitor

extension VideoInternetConnection {
    /// The default Internet connection monitor for iOS 12+.
    /// It uses Apple Network API.
    class Monitor: InternetConnectionMonitor, @unchecked Sendable {
        private var monitor: NWPathMonitor?
        private let queue = DispatchQueue(label: "io.getstream.internet-monitor")

        weak var delegate: InternetConnectionDelegate?

        var status: InternetConnectionStatus {
            if let path = monitor?.currentPath {
                return status(from: path)
            }

            return .unknown
        }

        func start() {
            guard monitor == nil else { return }

            monitor = createMonitor()
            monitor?.start(queue: queue)
        }

        func stop() {
            monitor?.cancel()
            monitor = nil
        }

        private func createMonitor() -> NWPathMonitor {
            let monitor = NWPathMonitor()

            // We should be able to do `[weak self]` here, but it seems `NWPathMonitor` sometimes calls the handler
            // event after `cancel()` has been called on it.
            monitor.pathUpdateHandler = { [weak self] in
                self?.updateStatus(with: $0)
            }
            return monitor
        }

        private func updateStatus(with path: NWPath) {
            log.info("Internet Connection info: \(path.debugDescription)", subsystems: .httpRequests)
            delegate?.internetConnectionStatusDidChange(status: status(from: path))
        }

        private func status(from path: NWPath) -> InternetConnectionStatus {
            guard path.status == .satisfied else {
                return .unavailable
            }

            let quality: InternetConnectionQuality
            quality = path.isConstrained ? .constrained : (path.isExpensive ? .expensive : .great)

            return .available(quality)
        }

        deinit {
            stop()
        }
    }
}

extension VideoInternetConnection: InternetConnectionProtocol {
    /// A publisher that emits the current internet connection status.
    ///
    /// This implementation uses a published property wrapper and erases the
    /// type to `AnyPublisher`.
    ///
    /// - Note: The publisher won't publish any duplicates.
    /// - Important: Unlike `StreamCore.InternetConnection`, status updates are
    ///   debounced by 100 milliseconds to ignore brief connectivity changes
    ///   before StreamVideo starts reconnection work.
    public var statusPublisher: AnyPublisher<InternetConnectionStatus, Never> {
        $status
            .debounce(for: .seconds(0.1), scheduler: DispatchQueue.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

extension VideoInternetConnection: InjectionKey {
    /// The current value of the internet connection monitor.
    ///
    /// This property provides a default implementation of the
    /// `InternetConnection` with a default monitor.
    public nonisolated(unsafe) static var currentValue: InternetConnectionProtocol = VideoInternetConnection(
        monitor: VideoInternetConnection.Monitor()
    )
}

extension InjectedValues {
    /// The current value of the internet connection monitor as a protocol type.
    ///
    /// This property allows for dependency injection using the protocol type,
    /// providing more flexibility in testing and modular design.
    public var internetConnectionObserver: InternetConnectionProtocol {
        get { Self[VideoInternetConnection.self] }
        set { Self[VideoInternetConnection.self] = newValue }
    }
}
