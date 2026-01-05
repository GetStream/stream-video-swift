//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class MediaPubSubHint: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var audioPublished: Bool
    public var audioSubscribed: Bool
    public var videoPublished: Bool
    public var videoSubscribed: Bool

    public init(audioPublished: Bool, audioSubscribed: Bool, videoPublished: Bool, videoSubscribed: Bool) {
        self.audioPublished = audioPublished
        self.audioSubscribed = audioSubscribed
        self.videoPublished = videoPublished
        self.videoSubscribed = videoSubscribed
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audioPublished = "audio_published"
        case audioSubscribed = "audio_subscribed"
        case videoPublished = "video_published"
        case videoSubscribed = "video_subscribed"
    }
    
    public static func == (lhs: MediaPubSubHint, rhs: MediaPubSubHint) -> Bool {
        lhs.audioPublished == rhs.audioPublished &&
            lhs.audioSubscribed == rhs.audioSubscribed &&
            lhs.videoPublished == rhs.videoPublished &&
            lhs.videoSubscribed == rhs.videoSubscribed
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audioPublished)
        hasher.combine(audioSubscribed)
        hasher.combine(videoPublished)
        hasher.combine(videoSubscribed)
    }
}
