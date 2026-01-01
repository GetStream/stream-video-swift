//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopLiveRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var continueClosedCaption: Bool?
    public var continueHls: Bool?
    public var continueRecording: Bool?
    public var continueRtmpBroadcasts: Bool?
    public var continueTranscription: Bool?

    public init(
        continueClosedCaption: Bool? = nil,
        continueHls: Bool? = nil,
        continueRecording: Bool? = nil,
        continueRtmpBroadcasts: Bool? = nil,
        continueTranscription: Bool? = nil
    ) {
        self.continueClosedCaption = continueClosedCaption
        self.continueHls = continueHls
        self.continueRecording = continueRecording
        self.continueRtmpBroadcasts = continueRtmpBroadcasts
        self.continueTranscription = continueTranscription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case continueClosedCaption = "continue_closed_caption"
        case continueHls = "continue_hls"
        case continueRecording = "continue_recording"
        case continueRtmpBroadcasts = "continue_rtmp_broadcasts"
        case continueTranscription = "continue_transcription"
    }
    
    public static func == (lhs: StopLiveRequest, rhs: StopLiveRequest) -> Bool {
        lhs.continueClosedCaption == rhs.continueClosedCaption &&
            lhs.continueHls == rhs.continueHls &&
            lhs.continueRecording == rhs.continueRecording &&
            lhs.continueRtmpBroadcasts == rhs.continueRtmpBroadcasts &&
            lhs.continueTranscription == rhs.continueTranscription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(continueClosedCaption)
        hasher.combine(continueHls)
        hasher.combine(continueRecording)
        hasher.combine(continueRtmpBroadcasts)
        hasher.combine(continueTranscription)
    }
}
