//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

#if canImport(UIKit)
import UIKit
#endif
import Combine

final class ProximityMonitor: ObservableObject, @unchecked Sendable {

    enum State: Hashable {
        case near, far
        init(_ value: Bool) { self = value ? .near : .far }
    }

    private var isEnabledObservationCancellable: AnyCancellable?
    private var stateObservationCancellable: AnyCancellable?

    @Published var isEnabled: Bool = false {
        didSet { didUpdate(isEnabled) }
    }

    @Published var state: State = .far

    // MARK: - Private helpers

    private func observeUpdates() {
        #if canImport(UIKit)
        isEnabledObservationCancellable?.cancel()
        isEnabledObservationCancellable = NotificationCenter
            .default
            .publisher(for: UIDevice.proximityStateDidChangeNotification)
            .map { _ in () }
            .sinkTask { @MainActor [weak self] _ in
                self?.isEnabled = UIDevice.current.isProximityMonitoringEnabled
            }
        #endif
    }

    private func didUpdate(_ isEnabled: Bool) {
        #if canImport(UIKit)
        Task { @MainActor in
            guard
                UIDevice.current.isProximityMonitoringEnabled != isEnabled
            else { return }

            UIDevice.current.isProximityMonitoringEnabled = isEnabled

            if isEnabled, stateObservationCancellable == nil {
                stateObservationCancellable = UIDevice
                    .current
                    .publisher(for: \.proximityState)
                    .map { State($0) }
                    .assign(to: \.state, onWeak: self)
            } else {
                stateObservationCancellable?.cancel()
                stateObservationCancellable = nil
                state = .far
            }
        }
        #endif
    }
}
