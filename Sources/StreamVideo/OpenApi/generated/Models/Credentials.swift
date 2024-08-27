//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct Credentials: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var iceServers: [ICEServer]
    public var server: SFUResponse
    public var token: String

    public init(iceServers: [ICEServer], server: SFUResponse, token: String) {
        self.iceServers = iceServers
        self.server = server
        self.token = token
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case iceServers = "ice_servers"
        case server
        case token
    }
}
