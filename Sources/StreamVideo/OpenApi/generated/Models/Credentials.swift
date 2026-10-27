//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class Credentials: @unchecked Sendable, Decodable {
    public var iceServers: [ICEServer]
    public var server: SFUResponse
    public var token: String

    public init(iceServers: [ICEServer], server: SFUResponse, token: String) {
        self.iceServers = iceServers
        self.server = server
        self.token = token
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.iceServers = try container.decode([ICEServer].self, forKey: .iceServers)
        self.server = try container.decode(SFUResponse.self, forKey: .server)
        self.token = try container.decode(String.self, forKey: .token)
    }
}

extension Credentials: Hashable {
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
