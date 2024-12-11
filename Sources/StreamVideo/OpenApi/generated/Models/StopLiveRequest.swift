//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public final class StopLiveRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var continueHls: Bool?
    public var continueRecording: Bool?
    public var continueRtmpBroadcast: Bool?
    public var continueTranscription: Bool?

    public init(
        continueHls: Bool? = nil,
        continueRecording: Bool? = nil,
        continueRtmpBroadcast: Bool? = nil,
        continueTranscription: Bool? = nil
    ) {
        self.continueHls = continueHls
        self.continueRecording = continueRecording
        self.continueRtmpBroadcast = continueRtmpBroadcast
        self.continueTranscription = continueTranscription
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case continueHls = "continue_hls"
        case continueRecording = "continue_recording"
        case continueRtmpBroadcast = "continue_rtmp_broadcast"
        case continueTranscription = "continue_transcription"
    }
    
    public static func == (lhs: StopLiveRequest, rhs: StopLiveRequest) -> Bool {
        lhs.continueHls == rhs.continueHls &&
            lhs.continueRecording == rhs.continueRecording &&
            lhs.continueRtmpBroadcast == rhs.continueRtmpBroadcast &&
            lhs.continueTranscription == rhs.continueTranscription
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(continueHls)
        hasher.combine(continueRecording)
        hasher.combine(continueRtmpBroadcast)
        hasher.combine(continueTranscription)
    }
}
