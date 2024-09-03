//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct EgressResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var broadcasting: Bool
    public var hls: EgressHLSResponse? = nil
    public var rtmps: [EgressRTMPResponse]

    public init(broadcasting: Bool, hls: EgressHLSResponse? = nil, rtmps: [EgressRTMPResponse]) {
        self.broadcasting = broadcasting
        self.hls = hls
        self.rtmps = rtmps
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case broadcasting
        case hls
        case rtmps
    }
}
