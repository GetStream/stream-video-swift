//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Signal_SendStatsRequest.OneOf_DeviceState {
    init(_ thermalState: ProcessInfo.ThermalState?) {
        var appleState = Stream_Video_Sfu_Models_AppleState()
        if let thermalState {
            appleState.thermalState = .init(thermalState)
        }
        self = .apple(appleState)
    }

    var thermalState: Stream_Video_Sfu_Models_AppleThermalState {
        switch self {
        case .android:
            return .UNRECOGNIZED(0)
        case let .apple(state):
            return state.thermalState
        }
    }
}

extension Stream_Video_Sfu_Models_AppleThermalState {
    init(_ thermalState: ProcessInfo.ThermalState) {
        switch thermalState {
        case .nominal:
            self = .nominal
        case .fair:
            self = .fair
        case .serious:
            self = .serious
        case .critical:
            self = .critical
        @unknown default:
            self = .unspecified
        }
    }
}
