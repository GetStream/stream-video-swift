//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public final class GoLiveRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var recordingStorageName: String?
    public var startHls: Bool?
    public var startRecording: Bool?
    public var startRtmpBroadcasts: Bool?
    public var startTranscription: Bool?
    public var transcriptionStorageName: String?

    public init(
        recordingStorageName: String? = nil,
        startHls: Bool? = nil,
        startRecording: Bool? = nil,
        startRtmpBroadcasts: Bool? = nil,
        startTranscription: Bool? = nil,
        transcriptionStorageName: String? = nil
    ) {
        self.recordingStorageName = recordingStorageName
        self.startHls = startHls
        self.startRecording = startRecording
        self.startRtmpBroadcasts = startRtmpBroadcasts
        self.startTranscription = startTranscription
        self.transcriptionStorageName = transcriptionStorageName
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case recordingStorageName = "recording_storage_name"
        case startHls = "start_hls"
        case startRecording = "start_recording"
        case startRtmpBroadcasts = "start_rtmp_broadcasts"
        case startTranscription = "start_transcription"
        case transcriptionStorageName = "transcription_storage_name"
    }
    
    public static func == (lhs: GoLiveRequest, rhs: GoLiveRequest) -> Bool {
        lhs.recordingStorageName == rhs.recordingStorageName &&
            lhs.startHls == rhs.startHls &&
            lhs.startRecording == rhs.startRecording &&
            lhs.startRtmpBroadcasts == rhs.startRtmpBroadcasts &&
            lhs.startTranscription == rhs.startTranscription &&
            lhs.transcriptionStorageName == rhs.transcriptionStorageName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(recordingStorageName)
        hasher.combine(startHls)
        hasher.combine(startRecording)
        hasher.combine(startRtmpBroadcasts)
        hasher.combine(startTranscription)
        hasher.combine(transcriptionStorageName)
    }
}
