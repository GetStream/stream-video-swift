//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

extension LogSubsystem {
    public static let thermalState = Self(rawValue: 1 << 6)
}

public final class ThermalStateObserver: ObservableObject {
    public static let shared = ThermalStateObserver()

    /// Published property to observe the thermal state
    @Published public private(set) var state: ProcessInfo.ThermalState {
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
                message: "Thermal state changed \(oldValue) → state",
                subsystems: .thermalState,
                error: nil
            )
        }
    }

    /// Cancellable object to manage notifications
    private var notificationCenterCancellable: AnyCancellable?
    private var thermalStateProvider: () -> ProcessInfo.ThermalState

    convenience init() {
        self.init { ProcessInfo.processInfo.thermalState }
    }
    

    init(thermalStateProvider: @escaping () -> ProcessInfo.ThermalState) {
        // Initialize the thermal state with the current process's thermal state
        self.state = thermalStateProvider()
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

    /// Depending on the Device's thermal state we adapt the request participants resolution.
    public var scale: CGFloat {
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
