//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// CallIngressResponse is the payload for ingress settings
public final class CallIngressResponse: @unchecked Sendable, Decodable {
    /// RTMP input settings
    public var rtmp: RTMPIngress
    public var srt: SRTIngress
    public var whip: WHIPIngress

    public init(rtmp: RTMPIngress, srt: SRTIngress, whip: WHIPIngress) {
        self.rtmp = rtmp
        self.srt = srt
        self.whip = whip
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.rtmp = try container.decode(RTMPIngress.self, forKey: .rtmp)
        self.srt = try container.decode(SRTIngress.self, forKey: .srt)
        self.whip = try container.decode(WHIPIngress.self, forKey: .whip)
    }
}

extension CallIngressResponse: Hashable {
    public static func == (lhs: CallIngressResponse, rhs: CallIngressResponse) -> Bool {
        lhs.rtmp == rhs.rtmp &&
            lhs.srt == rhs.srt &&
            lhs.whip == rhs.whip
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(rtmp)
        hasher.combine(srt)
        hasher.combine(whip)
    }
}
