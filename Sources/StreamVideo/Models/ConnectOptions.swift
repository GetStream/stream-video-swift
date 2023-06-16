//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

public struct ConnectOptions: Sendable {
    let rtcConfiguration: RTCConfiguration
    
    public init(iceServers: [ICEServer]) {
        rtcConfiguration = RTCConfiguration.makeConfiguration(with: iceServers)
    }
}
