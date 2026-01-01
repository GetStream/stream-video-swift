//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
import Combine

/// Represents the proximity state of a device's sensor.
public enum ProximityState: Hashable, Sendable {
    /// Device is close to user (e.g., near ear during call)
    case near
    /// Device is far from user
    case far
    init(_ value: Bool) { self = value ? .near : .far }
}

/// Protocol defining the interface for proximity monitoring functionality.
public protocol ProximityProviding {
    /// Current proximity state of the device
    var state: ProximityState { get }
    /// Publisher that emits proximity state changes
    var statePublisher: AnyPublisher<ProximityState, Never> { get }
    /// Whether proximity monitoring is currently active
    var isActive: Bool { get }

    /// Starts monitoring device proximity state
    @MainActor
    func startObservation()

    /// Stops monitoring device proximity state
    func stopObservation()
}

/// Monitors device proximity state using the device's proximity sensor.
/// Only available on iOS devices with proximity sensor capability.
final class ProximityMonitor: ProximityProviding, ObservableObject, @unchecked Sendable {
    @Injected(\.currentDevice) private var currentDevice

    private var stateObservationCancellable: AnyCancellable?

    /// Current proximity state of the device
    @Published public private(set) var state: ProximityState = .far
    /// Publisher that emits proximity state changes
    var statePublisher: AnyPublisher<ProximityState, Never> {
        $state.eraseToAnyPublisher()
    }

    /// Whether proximity monitoring is currently active
    var isActive: Bool { stateObservationCancellable != nil }

    init() {}

    /// Starts monitoring device proximity state.
    /// Only activates on iPhone devices and if not already monitoring.
    @MainActor
    func startObservation() {
        #if canImport(UIKit)
        guard currentDevice.deviceType == .phone, !isActive else {
            return
        }
        currentDevice.isProximityMonitoringEnabled = true

        stateObservationCancellable = NotificationCenter
            .default
            .publisher(for: UIDevice.proximityStateDidChangeNotification)
            .map { _ in ProximityState(UIDevice.current.proximityState) }
            .removeDuplicates()
            .log(.debug, subsystems: .audioSession) { "Proximity state updated \($0)." }
            .assign(to: \.state, onWeak: self)
        #endif
    }

    /// Stops monitoring device proximity state.
    /// No-op if monitoring is not active.
    func stopObservation() {
        guard isActive else {
            return
        }
        stateObservationCancellable?.cancel()
        stateObservationCancellable = nil
    }
}

/// Injection key for the proximity monitor dependency
enum ProximityProviderKey: InjectionKey {
    public nonisolated(unsafe) static var currentValue: ProximityProviding = ProximityMonitor()
}

extension InjectedValues {
    /// Provides access to the shared proximity monitor instance.
    /// Used to monitor device proximity state changes.
    public internal(set) var proximityMonitor: ProximityProviding {
        get { Self[ProximityProviderKey.self] }
        set { Self[ProximityProviderKey.self] = newValue }
    }
}
