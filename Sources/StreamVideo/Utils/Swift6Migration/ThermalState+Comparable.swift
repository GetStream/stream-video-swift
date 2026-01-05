//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

#if compiler(>=6.0)
extension ProcessInfo.ThermalState: @retroactive Comparable {
    public static func < (
        lhs: ProcessInfo.ThermalState,
        rhs: ProcessInfo.ThermalState
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
#else
extension ProcessInfo.ThermalState: Comparable {
    public static func < (
        lhs: ProcessInfo.ThermalState,
        rhs: ProcessInfo.ThermalState
    ) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
#endif
