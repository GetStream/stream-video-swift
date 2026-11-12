//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallSettingsRequest: Sendable, Encodable, JSONEncodable {
    public let audio: AudioSettingsRequest?
    public let backstage: BackstageSettingsRequest?
    public let broadcasting: BroadcastSettingsRequest?
    public let encryption: EncryptionSettingsRequest?
    public let frameRecording: FrameRecordingSettingsRequest?
    public let geofencing: GeofenceSettingsRequest?
    public let individualRecording: IndividualRecordingSettingsRequest?
    public let ingress: IngressSettingsRequest?
    public let lifecycle: LifecycleSettingsRequest?
    public let limits: LimitsSettingsRequest?
    public let rawRecording: RawRecordingSettingsRequest?
    public let recording: RecordSettingsRequest?
    public let ring: RingSettingsRequest?
    public let screensharing: ScreensharingSettingsRequest?
    public let session: SessionSettingsRequest?
    public let thumbnails: ThumbnailsSettingsRequest?
    public let transcription: TranscriptionSettingsRequest?
    public let video: VideoSettingsRequest?

    public init(
        audio: AudioSettingsRequest? = nil,
        backstage: BackstageSettingsRequest? = nil,
        broadcasting: BroadcastSettingsRequest? = nil,
        encryption: EncryptionSettingsRequest? = nil,
        frameRecording: FrameRecordingSettingsRequest? = nil,
        geofencing: GeofenceSettingsRequest? = nil,
        individualRecording: IndividualRecordingSettingsRequest? = nil,
        ingress: IngressSettingsRequest? = nil,
        lifecycle: LifecycleSettingsRequest? = nil,
        limits: LimitsSettingsRequest? = nil,
        rawRecording: RawRecordingSettingsRequest? = nil,
        recording: RecordSettingsRequest? = nil,
        ring: RingSettingsRequest? = nil,
        screensharing: ScreensharingSettingsRequest? = nil,
        session: SessionSettingsRequest? = nil,
        thumbnails: ThumbnailsSettingsRequest? = nil,
        transcription: TranscriptionSettingsRequest? = nil,
        video: VideoSettingsRequest? = nil
    ) {
        self.audio = audio
        self.backstage = backstage
        self.broadcasting = broadcasting
        self.encryption = encryption
        self.frameRecording = frameRecording
        self.geofencing = geofencing
        self.individualRecording = individualRecording
        self.ingress = ingress
        self.lifecycle = lifecycle
        self.limits = limits
        self.rawRecording = rawRecording
        self.recording = recording
        self.ring = ring
        self.screensharing = screensharing
        self.session = session
        self.thumbnails = thumbnails
        self.transcription = transcription
        self.video = video
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: StringCodingKey.self)
        try container.encodeIfPresent(audio, forKey: .audio)
        try container.encodeIfPresent(backstage, forKey: .backstage)
        try container.encodeIfPresent(broadcasting, forKey: .broadcasting)
        try container.encodeIfPresent(encryption, forKey: .encryption)
        try container.encodeIfPresent(frameRecording, forKey: .frameRecording)
        try container.encodeIfPresent(geofencing, forKey: .geofencing)
        try container.encodeIfPresent(individualRecording, forKey: .individualRecording)
        try container.encodeIfPresent(ingress, forKey: .ingress)
        try container.encodeIfPresent(lifecycle, forKey: .lifecycle)
        try container.encodeIfPresent(limits, forKey: .limits)
        try container.encodeIfPresent(rawRecording, forKey: .rawRecording)
        try container.encodeIfPresent(recording, forKey: .recording)
        try container.encodeIfPresent(ring, forKey: .ring)
        try container.encodeIfPresent(screensharing, forKey: .screensharing)
        try container.encodeIfPresent(session, forKey: .session)
        try container.encodeIfPresent(thumbnails, forKey: .thumbnails)
        try container.encodeIfPresent(transcription, forKey: .transcription)
        try container.encodeIfPresent(video, forKey: .video)
    }
}

extension CallSettingsRequest: Hashable {
    public static func == (lhs: CallSettingsRequest, rhs: CallSettingsRequest) -> Bool {
        lhs.audio == rhs.audio &&
            lhs.backstage == rhs.backstage &&
            lhs.broadcasting == rhs.broadcasting &&
            lhs.encryption == rhs.encryption &&
            lhs.frameRecording == rhs.frameRecording &&
            lhs.geofencing == rhs.geofencing &&
            lhs.individualRecording == rhs.individualRecording &&
            lhs.ingress == rhs.ingress &&
            lhs.lifecycle == rhs.lifecycle &&
            lhs.limits == rhs.limits &&
            lhs.rawRecording == rhs.rawRecording &&
            lhs.recording == rhs.recording &&
            lhs.ring == rhs.ring &&
            lhs.screensharing == rhs.screensharing &&
            lhs.session == rhs.session &&
            lhs.thumbnails == rhs.thumbnails &&
            lhs.transcription == rhs.transcription &&
            lhs.video == rhs.video
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(audio)
        hasher.combine(backstage)
        hasher.combine(broadcasting)
        hasher.combine(encryption)
        hasher.combine(frameRecording)
        hasher.combine(geofencing)
        hasher.combine(individualRecording)
        hasher.combine(ingress)
        hasher.combine(lifecycle)
        hasher.combine(limits)
        hasher.combine(rawRecording)
        hasher.combine(recording)
        hasher.combine(ring)
        hasher.combine(screensharing)
        hasher.combine(session)
        hasher.combine(thumbnails)
        hasher.combine(transcription)
        hasher.combine(video)
    }
}
