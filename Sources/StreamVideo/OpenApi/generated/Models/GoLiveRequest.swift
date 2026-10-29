//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class GoLiveRequest: @unchecked Sendable, Codable, JSONEncodable {
    public var recordingStorageName: String?
    public var startClosedCaption: Bool?
    public var startHls: Bool?
    public var startRecording: Bool?
    public var startTranscription: Bool?
    public var transcriptionStorageName: String?

    public init(
        recordingStorageName: String? = nil,
        startClosedCaption: Bool? = nil,
        startHls: Bool? = nil,
        startRecording: Bool? = nil,
        startTranscription: Bool? = nil,
        transcriptionStorageName: String? = nil
    ) {
        self.recordingStorageName = recordingStorageName
        self.startClosedCaption = startClosedCaption
        self.startHls = startHls
        self.startRecording = startRecording
        self.startTranscription = startTranscription
        self.transcriptionStorageName = transcriptionStorageName
    }

    public enum CodingKeys: String, CodingKey {
        case recordingStorageName = "recording_storage_name"
        case startClosedCaption = "start_closed_caption"
        case startHls = "start_hls"
        case startRecording = "start_recording"
        case startTranscription = "start_transcription"
        case transcriptionStorageName = "transcription_storage_name"
    }
}

extension GoLiveRequest: Hashable {
    public static func == (lhs: GoLiveRequest, rhs: GoLiveRequest) -> Bool {
        lhs.recordingStorageName == rhs.recordingStorageName &&
            lhs.startClosedCaption == rhs.startClosedCaption &&
            lhs.startHls == rhs.startHls &&
            lhs.startRecording == rhs.startRecording &&
            lhs.startTranscription == rhs.startTranscription &&
            lhs.transcriptionStorageName == rhs.transcriptionStorageName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(recordingStorageName)
        hasher.combine(startClosedCaption)
        hasher.combine(startHls)
        hasher.combine(startRecording)
        hasher.combine(startTranscription)
        hasher.combine(transcriptionStorageName)
    }
}
