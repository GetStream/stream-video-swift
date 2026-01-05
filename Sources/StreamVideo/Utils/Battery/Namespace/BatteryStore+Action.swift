//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension BatteryStore.Namespace {
    /// Actions that drive battery monitoring state transitions.
    ///
    /// These actions mirror updates from `UIDevice` and user controlled
    /// monitoring preferences.
    enum StoreAction: Sendable, Equatable, StoreActionBoxProtocol {
        case setMonitoringEnabled(Bool)
        case setLevel(Float)
        case setState(StoreState.BatteryState)
    }
}
