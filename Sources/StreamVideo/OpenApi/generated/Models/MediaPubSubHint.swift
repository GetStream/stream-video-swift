//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct MediaPubSubHint: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
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
}
