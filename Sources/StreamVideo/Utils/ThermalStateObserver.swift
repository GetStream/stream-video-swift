//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A protocol representing an observer of a device's thermal state.
///
/// This protocol is designed to provide both the current thermal state of the device and a publisher
/// for monitoring changes to that state. Additionally, it provides a scaling factor to adapt the behavior
/// or appearance of certain features based on the device's thermal condition.
public protocol ThermalStateObserving: ObservableObject {

    /// The current thermal state of the device.
    var state: ProcessInfo.ThermalState { get }

    /// A publisher emitting updates when the thermal state changes.
    var statePublisher: AnyPublisher<ProcessInfo.ThermalState, Never> { get }

    /// A scaling factor derived from the device's thermal state.
    ///
    /// This scale can be used to adapt functionalities, such as adjusting the resolution of streaming content,
    /// to ensure optimal performance under varying thermal conditions.
    var scale: CGFloat { get }
}

/// A concrete implementation of `ThermalStateObserving` that observes and reacts to changes in the device's thermal state.
///
/// `ThermalStateObserver` monitors the device's thermal state and provides both immediate access to the current state
/// and a publisher for tracking state changes over time. It also offers a derived scaling factor to help adapt app behavior
/// or features based on the current thermal conditions.
final class ThermalStateObserver: ObservableObject, ThermalStateObserving {

    /// Published property to observe the thermal state
    @Published private(set) var state: ProcessInfo.ThermalState {
        didSet {
            // Determine the appropriate log level based on the thermal state
            let logLevel: LogLevel
            switch state {
            case .nominal, .fair:
                logLevel = .debug
            case .serious:
                logLevel = .warning
            case .critical:
                logLevel = .error
            @unknown default:
                logLevel = .debug
            }
            // Log the thermal state change with the calculated log level
            log.log(
                logLevel,
                message: "Thermal state changed \(oldValue) → \(state).",
                subsystems: .thermalState,
                error: nil
            )
        }
    }

    var statePublisher: AnyPublisher<ProcessInfo.ThermalState, Never> { $state.eraseToAnyPublisher() }

    /// Cancellable object to manage notifications
    private var notificationCenterCancellable: AnyCancellable?
    private var thermalStateProvider: () -> ProcessInfo.ThermalState

    convenience init() {
        self.init { ProcessInfo.processInfo.thermalState }
    }

    init(thermalStateProvider: @escaping () -> ProcessInfo.ThermalState) {
        // Initialize the thermal state with the current process's thermal state
        state = thermalStateProvider()
        self.thermalStateProvider = thermalStateProvider

        // Set up a publisher to monitor thermal state changes
        notificationCenterCancellable = NotificationCenter
            .default
            .publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { [thermalStateProvider] _ in thermalStateProvider() }
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
    }

    /// Depending on the Device's thermal state, we adapt the request participants resolution.
    ///
    /// The scale factor is derived from the current thermal state and is designed to adjust the resolution
    /// or other performance-related factors of certain features to ensure optimal performance and user experience.
    var scale: CGFloat {
        // Determine the appropriate scaling factor based on the thermal state
        switch state {
        case .nominal:
            return 1
        case .fair:
            return 1.5
        case .serious:
            return 2
        case .critical:
            return 4
        @unknown default:
            return 1
        }
    }
}

/// Provides the default value of the `Appearance` class.
enum ThermalStateObserverKey: InjectionKey {
    nonisolated(unsafe) static var currentValue: any ThermalStateObserving = ThermalStateObserver()
}

extension InjectedValues {

    public var thermalStateObserver: any ThermalStateObserving {
        get {
            Self[ThermalStateObserverKey.self]
        }
        set {
            Self[ThermalStateObserverKey.self] = newValue
        }
    }
}
