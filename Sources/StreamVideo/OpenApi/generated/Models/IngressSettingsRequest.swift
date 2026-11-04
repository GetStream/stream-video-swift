//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressSettingsRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var audioEncodingOptions: IngressAudioEncodingOptionsRequest?
    public var enabled: Bool?
    public var videoEncodingOptions: [String: IngressVideoEncodingOptionsRequest]?

    public init(
        audioEncodingOptions: IngressAudioEncodingOptionsRequest? = nil,
        enabled: Bool? = nil,
        videoEncodingOptions: [String: IngressVideoEncodingOptionsRequest]? = nil
    ) {
        self.audioEncodingOptions = audioEncodingOptions
        self.enabled = enabled
        self.videoEncodingOptions = videoEncodingOptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audioEncodingOptions = try container.decodeIfPresent(
            IngressAudioEncodingOptionsRequest.self,
            forKey: .audioEncodingOptions
        )
        self.enabled = try container.decodeIfPresent(Bool.self, forKey: .enabled)
        self.videoEncodingOptions = try container.decodeIfPresent(
            [String: IngressVideoEncodingOptionsRequest].self,
            forKey: .videoEncodingOptions
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audioEncodingOptions, forKey: .audioEncodingOptions)
        try container.encodeIfPresent(enabled, forKey: .enabled)
        try container.encodeIfPresent(videoEncodingOptions, forKey: .videoEncodingOptions)
    }
}

extension IngressSettingsRequest: Hashable {
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
