//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class RTMPBroadcastRequestQuality: RawRepresentable, Codable, CustomStringConvertible, Hashable, Sendable {
    public let rawValue: String

    public var description: String { rawValue }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let _1080p = RTMPBroadcastRequestQuality(rawValue: "1080p")
    public static let _1440p = RTMPBroadcastRequestQuality(rawValue: "1440p")
    public static let _360p = RTMPBroadcastRequestQuality(rawValue: "360p")
    public static let _480p = RTMPBroadcastRequestQuality(rawValue: "480p")
    public static let _720p = RTMPBroadcastRequestQuality(rawValue: "720p")
    public static let portrait1080x1920 = RTMPBroadcastRequestQuality(rawValue: "portrait-1080x1920")
    public static let portrait1440x2560 = RTMPBroadcastRequestQuality(rawValue: "portrait-1440x2560")
    public static let portrait360x640 = RTMPBroadcastRequestQuality(rawValue: "portrait-360x640")
    public static let portrait480x854 = RTMPBroadcastRequestQuality(rawValue: "portrait-480x854")
    public static let portrait720x1280 = RTMPBroadcastRequestQuality(rawValue: "portrait-720x1280")
}

/// RTMPBroadcastRequest is the payload for starting an RTMP broadcast.
public final class RTMPBroadcastRequest: Sendable, Encodable, JSONEncodable {
    public let layout: LayoutSettings?
    /// Name identifier for RTMP broadcast, must be unique in call
    public let name: String
    /// If provided, will override the call's RTMP settings quality. One of: 360p, 480p, 720p, 1080p, 1440p, portrait-360x640, portrait-480x854, portrait-720x1280, portrait-1080x1920, portrait-1440x2560
    public let quality: RTMPBroadcastRequestQuality?
    /// If provided, will be appended at the end of stream_url
    public let streamKey: String?
    /// URL for the RTMP server to send the call to
    public let streamUrl: String

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

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(layout, forKey: .layout)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(quality, forKey: .quality)
        try container.encodeIfPresent(streamKey, forKey: .streamKey)
        try container.encode(streamUrl, forKey: .streamUrl)
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
