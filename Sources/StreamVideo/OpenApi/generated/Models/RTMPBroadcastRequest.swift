//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// RTMPBroadcastRequest is the payload for starting an RTMP broadcast.
public final class RTMPBroadcastRequest: @unchecked Sendable, Codable, JSONEncodable {
    
    public enum RTMPBroadcastRequestQuality: String, Sendable, Codable, CaseIterable {
        case _1080p = "1080p"
        case _1440p = "1440p"
        case _360p = "360p"
        case _480p = "480p"
        case _720p = "720p"
        case portrait1080x1920 = "portrait-1080x1920"
        case portrait1440x2560 = "portrait-1440x2560"
        case portrait360x640 = "portrait-360x640"
        case portrait480x854 = "portrait-480x854"
        case portrait720x1280 = "portrait-720x1280"
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

    public var layout: LayoutSettings?
    /// Name identifier for RTMP broadcast, must be unique in call
    public var name: String
    /// If provided, will override the call's RTMP settings quality. One of: 360p, 480p, 720p, 1080p, 1440p, portrait-360x640, portrait-480x854, portrait-720x1280, portrait-1080x1920, portrait-1440x2560
    public var quality: RTMPBroadcastRequestQuality?
    /// If provided, will be appended at the end of stream_url
    public var streamKey: String?
    /// URL for the RTMP server to send the call to
    public var streamUrl: String

    public init(
        layout: LayoutSettings? = nil,
        name: String,
        quality: RTMPBroadcastRequestQuality? = nil,
        streamKey: String? = nil,
        streamUrl: String
    ) {
        self.layout = layout
        self.name = name
        self.quality = quality
        self.streamKey = streamKey
        self.streamUrl = streamUrl
    }

    public enum CodingKeys: String, CodingKey {
        case layout
        case name
        case quality
        case streamKey = "stream_key"
        case streamUrl = "stream_url"
    }
}

extension RTMPBroadcastRequest: Hashable {
    public static func == (lhs: RTMPBroadcastRequest, rhs: RTMPBroadcastRequest) -> Bool {
        lhs.layout == rhs.layout &&
            lhs.name == rhs.name &&
            lhs.quality == rhs.quality &&
            lhs.streamKey == rhs.streamKey &&
            lhs.streamUrl == rhs.streamUrl
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(layout)
        hasher.combine(name)
        hasher.combine(quality)
        hasher.combine(streamKey)
        hasher.combine(streamUrl)
    }
}
