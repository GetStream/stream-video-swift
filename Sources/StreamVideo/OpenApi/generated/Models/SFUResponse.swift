//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct SFUResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
}
