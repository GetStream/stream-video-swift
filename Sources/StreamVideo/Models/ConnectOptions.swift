//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import StreamWebRTC

public struct ConnectOptions: Sendable {
    let rtcConfiguration: RTCConfiguration
    
    public init(iceServers: [ICEServer]) {
        rtcConfiguration = RTCConfiguration.makeConfiguration(with: iceServers)
    }
}
