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

    @Published public private(set) var state: ProcessInfo.ThermalState = .nominal {
        didSet {
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
            log.log(
                logLevel,
                message: "Thermal state changed \(oldValue) → state",
                subsystems: .thermalState,
                error: nil
            )
        }
    }

    private var notificationCenterCancellable: AnyCancellable?

    private init() {
        notificationCenterCancellable = NotificationCenter
            .default
            .publisher(for: ProcessInfo.thermalStateDidChangeNotification)
            .receive(on: DispatchQueue.global(qos: .utility))
            .map { _ in ProcessInfo.processInfo.thermalState }
            .receive(on: DispatchQueue.main)
            .assign(to: \.state, on: self)
    }
}
