//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct GoLiveRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var recordingStorageName: String? = nil
    public var startHls: Bool? = nil
    public var startRecording: Bool? = nil
    public var startRtmpBroadcasts: Bool? = nil
    public var startTranscription: Bool? = nil
    public var transcriptionStorageName: String? = nil

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
}
