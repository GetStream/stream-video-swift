//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class IngressSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var audioEncodingOptions: IngressAudioEncodingOptionsRequest?
    public var enabled: Bool?
    public var videoEncodingOptions: [String: IngressVideoEncodingOptionsRequest]?

    public init(audioEncodingOptions: IngressAudioEncodingOptionsRequest? = nil, enabled: Bool? = nil, videoEncodingOptions: [String: IngressVideoEncodingOptionsRequest]? = nil) {
        self.audioEncodingOptions = audioEncodingOptions
        self.enabled = enabled
        self.videoEncodingOptions = videoEncodingOptions
    }

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioEncodingOptions = "audio_encoding_options"
        case enabled
        case videoEncodingOptions = "video_encoding_options"
    }

    public static func == (lhs: IngressSettingsRequest, rhs: IngressSettingsRequest) -> Bool {
        lhs.audioEncodingOptions == rhs.audioEncodingOptions &&
        lhs.enabled == rhs.enabled &&
        lhs.videoEncodingOptions == rhs.videoEncodingOptions
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioEncodingOptions)
        hasher.combine(enabled)
        hasher.combine(videoEncodingOptions)
    }
}
