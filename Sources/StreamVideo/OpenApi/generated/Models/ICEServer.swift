//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// ICE server configuration for WebRTC connections
public final class ICEServer: @unchecked Sendable, Decodable {
    /// ICE server password
    public var password: String
    /// ICE server URLs
    public var urls: [String]
    /// ICE server username
    public var username: String

    public init(password: String, urls: [String], username: String) {
        self.password = password
        self.urls = urls
        self.username = username
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.password = try container.decode(String.self, forKey: .password)
        self.urls = try container.decode([String].self, forKey: .urls)
        self.username = try container.decode(String.self, forKey: .username)
    }
}

extension ICEServer: Hashable {
    public static func == (lhs: ICEServer, rhs: ICEServer) -> Bool {
        lhs.password == rhs.password &&
            lhs.urls == rhs.urls &&
            lhs.username == rhs.username
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(password)
        hasher.combine(urls)
        hasher.combine(username)
    }
}
