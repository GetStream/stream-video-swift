//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class GoLiveRequest: Sendable, Encodable, JSONEncodable {
    public let recordingStorageName: String?
    public let startClosedCaption: Bool?
    public let startCompositeRecording: Bool?
    public let startHls: Bool?
    public let startIndividualRecording: Bool?
    public let startRawRecording: Bool?
    public let startRecording: Bool?
    public let startTranscription: Bool?
    public let transcriptionStorageName: String?

    public init(
        recordingStorageName: String? = nil,
        startClosedCaption: Bool? = nil,
        startCompositeRecording: Bool? = nil,
        startHls: Bool? = nil,
        startIndividualRecording: Bool? = nil,
        startRawRecording: Bool? = nil,
        startRecording: Bool? = nil,
        startTranscription: Bool? = nil,
        transcriptionStorageName: String? = nil
    ) {
        self.recordingStorageName = recordingStorageName
        self.startClosedCaption = startClosedCaption
        self.startCompositeRecording = startCompositeRecording
        self.startHls = startHls
        self.startIndividualRecording = startIndividualRecording
        self.startRawRecording = startRawRecording
        self.startRecording = startRecording
        self.startTranscription = startTranscription
        self.transcriptionStorageName = transcriptionStorageName
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(recordingStorageName, forKey: .recordingStorageName)
        try container.encodeIfPresent(startClosedCaption, forKey: .startClosedCaption)
        try container.encodeIfPresent(startCompositeRecording, forKey: .startCompositeRecording)
        try container.encodeIfPresent(startHls, forKey: .startHls)
        try container.encodeIfPresent(startIndividualRecording, forKey: .startIndividualRecording)
        try container.encodeIfPresent(startRawRecording, forKey: .startRawRecording)
        try container.encodeIfPresent(startRecording, forKey: .startRecording)
        try container.encodeIfPresent(startTranscription, forKey: .startTranscription)
        try container.encodeIfPresent(transcriptionStorageName, forKey: .transcriptionStorageName)
    }
}

extension GoLiveRequest: Hashable {
    public static func == (lhs: GoLiveRequest, rhs: GoLiveRequest) -> Bool {
        lhs.recordingStorageName == rhs.recordingStorageName &&
            lhs.startClosedCaption == rhs.startClosedCaption &&
            lhs.startCompositeRecording == rhs.startCompositeRecording &&
            lhs.startHls == rhs.startHls &&
            lhs.startIndividualRecording == rhs.startIndividualRecording &&
            lhs.startRawRecording == rhs.startRawRecording &&
            lhs.startRecording == rhs.startRecording &&
            lhs.startTranscription == rhs.startTranscription &&
            lhs.transcriptionStorageName == rhs.transcriptionStorageName
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(recordingStorageName)
        hasher.combine(startClosedCaption)
        hasher.combine(startCompositeRecording)
        hasher.combine(startHls)
        hasher.combine(startIndividualRecording)
        hasher.combine(startRawRecording)
        hasher.combine(startRecording)
        hasher.combine(startTranscription)
        hasher.combine(transcriptionStorageName)
    }
}
