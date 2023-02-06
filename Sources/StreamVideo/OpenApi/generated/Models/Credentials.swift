//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct Credentials: Codable, JSONEncodable, Hashable {

    internal var iceServers: [ICEServer]?
    internal var server: SFUResponse?
    internal var token: String?

    internal init(iceServers: [ICEServer]? = nil, server: SFUResponse? = nil, token: String? = nil) {
        self.iceServers = iceServers
        self.server = server
        self.token = token
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case iceServers = "ice_servers"
        case server
        case token
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(iceServers, forKey: .iceServers)
        try container.encodeIfPresent(server, forKey: .server)
        try container.encodeIfPresent(token, forKey: .token)
    }
}
