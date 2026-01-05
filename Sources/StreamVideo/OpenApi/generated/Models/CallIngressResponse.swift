//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallIngressResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var rtmp: RTMPIngress

    public init(rtmp: RTMPIngress) {
        self.rtmp = rtmp
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case rtmp
    }
    
    public static func == (lhs: CallIngressResponse, rhs: CallIngressResponse) -> Bool {
        lhs.rtmp == rhs.rtmp
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rtmp)
    }
}
