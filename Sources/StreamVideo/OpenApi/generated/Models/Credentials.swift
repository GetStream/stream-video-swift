//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class Credentials: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
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
    
    public static func == (lhs: Credentials, rhs: Credentials) -> Bool {
        lhs.iceServers == rhs.iceServers &&
            lhs.server == rhs.server &&
            lhs.token == rhs.token
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(iceServers)
        hasher.combine(server)
        hasher.combine(token)
    }
}
