//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class SFUResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var edgeName: String
    public var url: String
    public var wsEndpoint: String

    public init(edgeName: String, url: String, wsEndpoint: String) {
        self.edgeName = edgeName
        self.url = url
        self.wsEndpoint = wsEndpoint
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case edgeName = "edge_name"
        case url
        case wsEndpoint = "ws_endpoint"
    }
    
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
