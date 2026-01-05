//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

extension BatteryStore.Namespace {

    /// Snapshot of the battery monitoring configuration and readings.
    struct StoreState: Equatable {
        var isMonitoringEnabled: Bool
        var state: BatteryState
        var level: Int
    }
}

extension BatteryStore.Namespace.StoreState {

    /// Represents the high-level battery state emitted by `UIDevice`.
    enum BatteryState: CustomStringConvertible {
        case unknown
        case unplugged
        case charging
        case full

        var description: String {
            switch self {
            case .unknown:
                return ".unknown"
            case .unplugged:
                return ".unplugged"
            case .charging:
                return ".charging"
            case .full:
                return ".full"
            }
        }

        #if canImport(UIKit)
        /// Creates a battery state from the UIKit battery representation.
        init(_ rawValue: UIDevice.BatteryState) {
            switch rawValue {
            case .unknown:
                self = .unknown
            case .unplugged:
                self = .unplugged
            case .charging:
                self = .charging
            case .full:
                self = .full
            @unknown default:
                self = .unknown
            }
        }
        #endif
    }
}

extension BatteryStore.Namespace.StoreState: Encodable {}

extension BatteryStore.Namespace.StoreState.BatteryState: Encodable {
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .unknown:
            try container.encode("unknown")
        case .unplugged:
            try container.encode("unplugged")
        case .charging:
            try container.encode("charging")
        case .full:
            try container.encode("full")
        }
    }
}
