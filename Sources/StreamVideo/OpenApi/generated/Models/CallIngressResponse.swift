//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallIngressResponse is the payload for ingress settings
public final class CallIngressResponse: @unchecked Sendable, Codable, JSONEncodable {
    /// RTMP input settings
    public var rtmp: RTMPIngress

    public init(rtmp: RTMPIngress) {
        self.rtmp = rtmp
    }

    public enum CodingKeys: String, CodingKey {
        case rtmp
    }
}

extension CallIngressResponse: Hashable {
    public static func == (lhs: CallIngressResponse, rhs: CallIngressResponse) -> Bool {
        lhs.rtmp == rhs.rtmp
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rtmp)
    }
}
