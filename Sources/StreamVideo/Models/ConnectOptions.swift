//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

public struct ConnectOptions: @unchecked Sendable {
    let rtcConfiguration: RTCConfiguration

    public init(iceServers: [ICEServer]) {
        rtcConfiguration = RTCConfiguration.makeConfiguration(with: iceServers)
    }
}
