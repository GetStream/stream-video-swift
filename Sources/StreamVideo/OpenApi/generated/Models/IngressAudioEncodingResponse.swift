//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressAudioEncodingResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var bitrate: Int
    public var channels: Int
    public var enableDtx: Bool

    public init(bitrate: Int, channels: Int, enableDtx: Bool) {
        self.bitrate = bitrate
        self.channels = channels
        self.enableDtx = enableDtx
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case bitrate
        case channels
        case enableDtx = "enable_dtx"
    }

    public static func == (lhs: IngressAudioEncodingResponse, rhs: IngressAudioEncodingResponse) -> Bool {
        lhs.bitrate == rhs.bitrate &&
        lhs.channels == rhs.channels &&
        lhs.enableDtx == rhs.enableDtx
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(bitrate)
        hasher.combine(channels)
        hasher.combine(enableDtx)
    }
}
