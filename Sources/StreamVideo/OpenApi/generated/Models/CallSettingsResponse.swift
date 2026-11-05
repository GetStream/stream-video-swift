//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

public final class CallSettingsResponse: @unchecked Sendable, Decodable {
    public var audio: AudioSettings
    public var backstage: BackstageSettings
    /// BroadcastSettingsResponse is the payload for broadcasting settings
    public var broadcasting: BroadcastSettingsResponse
    /// EncryptionSettings is the payload for end-to-end encryption settings
    public var encryption: EncryptionSettingsResponse
    public var frameRecording: FrameRecordingSettingsResponse
    public var geofencing: GeofenceSettings
    public var individualRecording: IndividualRecordingSettingsResponse
    public var ingress: IngressSettingsResponse?
    public var limits: LimitsSettingsResponse
    public var rawRecording: RawRecordingSettingsResponse
    /// RecordSettings is the payload for recording settings
    public var recording: RecordSettingsResponse
    public var ring: RingSettings
    public var screensharing: ScreensharingSettings
    public var session: SessionSettingsResponse
    public var thumbnails: ThumbnailsSettings
    public var transcription: TranscriptionSettings
    public var video: VideoSettings

    public init(
        audio: AudioSettings,
        backstage: BackstageSettings,
        broadcasting: BroadcastSettingsResponse,
        encryption: EncryptionSettingsResponse,
        frameRecording: FrameRecordingSettingsResponse,
        geofencing: GeofenceSettings,
        individualRecording: IndividualRecordingSettingsResponse,
        ingress: IngressSettingsResponse? = nil,
        limits: LimitsSettingsResponse,
        rawRecording: RawRecordingSettingsResponse,
        recording: RecordSettingsResponse,
        ring: RingSettings,
        screensharing: ScreensharingSettings,
        session: SessionSettingsResponse,
        thumbnails: ThumbnailsSettings,
        transcription: TranscriptionSettings,
        video: VideoSettings
    ) {
        self.audio = audio
        self.backstage = backstage
        self.broadcasting = broadcasting
        self.encryption = encryption
        self.frameRecording = frameRecording
        self.geofencing = geofencing
        self.individualRecording = individualRecording
        self.ingress = ingress
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

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: StringCodingKey.self)
        self.audio = try container.decode(AudioSettings.self, forKey: .audio)
        self.backstage = try container.decode(BackstageSettings.self, forKey: .backstage)
        self.broadcasting = try container.decode(BroadcastSettingsResponse.self, forKey: .broadcasting)
        self.encryption = try container.decode(EncryptionSettingsResponse.self, forKey: .encryption)
        self.frameRecording = try container.decode(FrameRecordingSettingsResponse.self, forKey: .frameRecording)
        self.geofencing = try container.decode(GeofenceSettings.self, forKey: .geofencing)
        self.individualRecording = try container.decode(IndividualRecordingSettingsResponse.self, forKey: .individualRecording)
        self.ingress = try container.decodeIfPresent(IngressSettingsResponse.self, forKey: .ingress)
        self.limits = try container.decode(LimitsSettingsResponse.self, forKey: .limits)
        self.rawRecording = try container.decode(RawRecordingSettingsResponse.self, forKey: .rawRecording)
        self.recording = try container.decode(RecordSettingsResponse.self, forKey: .recording)
        self.ring = try container.decode(RingSettings.self, forKey: .ring)
        self.screensharing = try container.decode(ScreensharingSettings.self, forKey: .screensharing)
        self.session = try container.decode(SessionSettingsResponse.self, forKey: .session)
        self.thumbnails = try container.decode(ThumbnailsSettings.self, forKey: .thumbnails)
        self.transcription = try container.decode(TranscriptionSettings.self, forKey: .transcription)
        self.video = try container.decode(VideoSettings.self, forKey: .video)
    }
}

extension CallSettingsResponse: Hashable {
    public static func == (lhs: CallSettingsResponse, rhs: CallSettingsResponse) -> Bool {
        lhs.audio == rhs.audio &&
            lhs.backstage == rhs.backstage &&
            lhs.broadcasting == rhs.broadcasting &&
            lhs.encryption == rhs.encryption &&
            lhs.frameRecording == rhs.frameRecording &&
            lhs.geofencing == rhs.geofencing &&
            lhs.individualRecording == rhs.individualRecording &&
            lhs.ingress == rhs.ingress &&
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
