//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import Combine

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

    /// Depending on the Device's thermal state we adapt the request participants resolution.
    public var scale: CGFloat {
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
