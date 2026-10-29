//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class IngressSettingsResponse: @unchecked Sendable, Codable, JSONEncodable {
    public var audioEncodingOptions: IngressAudioEncodingResponse?
    public var enabled: Bool
    public var videoEncodingOptions: [String: IngressVideoEncodingResponse]?

    public init(
        audioEncodingOptions: IngressAudioEncodingResponse? = nil,
        enabled: Bool,
        videoEncodingOptions: [String: IngressVideoEncodingResponse]? = nil
    ) {
        self.audioEncodingOptions = audioEncodingOptions
        self.enabled = enabled
        self.videoEncodingOptions = videoEncodingOptions
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audioEncodingOptions = try container.decodeIfPresent(IngressAudioEncodingResponse.self, forKey: .audioEncodingOptions)
        self.enabled = try container.decode(Bool.self, forKey: .enabled)
        self.videoEncodingOptions = try container.decodeIfPresent(
            [String: IngressVideoEncodingResponse].self,
            forKey: .videoEncodingOptions
        )
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audioEncodingOptions, forKey: .audioEncodingOptions)
        try container.encode(enabled, forKey: .enabled)
        try container.encodeIfPresent(videoEncodingOptions, forKey: .videoEncodingOptions)
    }
}

extension IngressSettingsResponse: Hashable {
    public static func == (lhs: IngressSettingsResponse, rhs: IngressSettingsResponse) -> Bool {
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
