//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressAudioEncodingOptionsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public enum IngressAudioEncodingOptionsRequestChannels: String, Sendable, Codable, CaseIterable {
        case _1 = "1"
        case _2 = "2"
        case unknown = "_unknown"

        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let decodedValue = try? container.decode(String.self),
                let value = Self(rawValue: decodedValue) {
                self = value
            } else {
                self = .unknown
            }
        }
    }
    public var bitrate: Int
    public var channels: IngressAudioEncodingOptionsRequestChannels
    public var enableDtx: Bool?

    public init(bitrate: Int, channels: IngressAudioEncodingOptionsRequestChannels, enableDtx: Bool? = nil) {
        self.bitrate = bitrate
        self.channels = channels
        self.enableDtx = enableDtx
    }

public enum CodingKeys: String, CodingKey, CaseIterable {
    case bitrate
    case channels
    case enableDtx = "enable_dtx"
}

    public static func == (lhs: IngressAudioEncodingOptionsRequest, rhs: IngressAudioEncodingOptionsRequest) -> Bool {
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
