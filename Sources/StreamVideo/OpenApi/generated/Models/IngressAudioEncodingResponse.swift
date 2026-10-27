//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressAudioEncodingResponse: @unchecked Sendable, Decodable {
    public var bitrate: Int
    public var channels: Int
    public var enableDtx: Bool

    public init(bitrate: Int, channels: Int, enableDtx: Bool) {
        self.bitrate = bitrate
        self.channels = channels
        self.enableDtx = enableDtx
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.bitrate = try container.decode(Int.self, forKey: .bitrate)
        self.channels = try container.decode(Int.self, forKey: .channels)
        self.enableDtx = try container.decode(Bool.self, forKey: .enableDtx)
    }
}

extension IngressAudioEncodingResponse: Hashable {
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
