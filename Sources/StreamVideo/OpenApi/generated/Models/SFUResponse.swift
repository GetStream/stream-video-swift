//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class SFUResponse: @unchecked Sendable, Decodable {
    public var edgeName: String
    public var url: String
    public var wsEndpoint: String

    public init(edgeName: String, url: String, wsEndpoint: String) {
        self.edgeName = edgeName
        self.url = url
        self.wsEndpoint = wsEndpoint
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.edgeName = try container.decode(String.self, forKey: .edgeName)
        self.url = try container.decode(String.self, forKey: .url)
        self.wsEndpoint = try container.decode(String.self, forKey: .wsEndpoint)
    }
}

extension SFUResponse: Hashable {
    public static func == (lhs: SFUResponse, rhs: SFUResponse) -> Bool {
        lhs.edgeName == rhs.edgeName &&
            lhs.url == rhs.url &&
            lhs.wsEndpoint == rhs.wsEndpoint
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(edgeName)
        hasher.combine(url)
        hasher.combine(wsEndpoint)
    }
}
