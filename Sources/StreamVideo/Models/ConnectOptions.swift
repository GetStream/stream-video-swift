//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
@preconcurrency import WebRTC

public struct ConnectOptions: Sendable {
    let rtcConfiguration: RTCConfiguration
    
    public init(iceServers: [ICEServerConfig]) {
        rtcConfiguration = RTCConfiguration.makeConfiguration(with: iceServers)
    }
}

public struct ICEServerConfig {
    public let urls: [String]
    public let username: String?
    public let password: String?
    
    public init(urls: [String], username: String? = nil, password: String? = nil) {
        self.urls = urls
        self.username = username
        self.password = password
    }
}

extension Stream_Video_ICEServer {
    
    func toICEServerConfig() -> ICEServerConfig {
        ICEServerConfig(urls: urls, username: username, password: password)
    }
}
