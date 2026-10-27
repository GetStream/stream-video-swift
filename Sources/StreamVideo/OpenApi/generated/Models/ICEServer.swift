//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// ICE server configuration for WebRTC connections
public final class ICEServer: @unchecked Sendable, Codable, JSONEncodable {
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

    public enum CodingKeys: String, CodingKey {
        case password
        case urls
        case username
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
