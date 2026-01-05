//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class EgressResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var broadcasting: Bool
    public var hls: EgressHLSResponse?
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
    
    public static func == (lhs: EgressResponse, rhs: EgressResponse) -> Bool {
        lhs.broadcasting == rhs.broadcasting &&
            lhs.hls == rhs.hls &&
            lhs.rtmps == rhs.rtmps
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(broadcasting)
        hasher.combine(hls)
        hasher.combine(rtmps)
    }
}
