//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallSettingsResponse: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var audio: AudioSettings
    public var backstage: BackstageSettings
    public var broadcasting: BroadcastSettingsResponse
    public var frameRecording: FrameRecordingSettingsResponse
    public var geofencing: GeofenceSettings
    public var individualRecording: IndividualRecordingSettingsResponse
    public var ingress: IngressSettingsResponse?
    public var limits: LimitsSettingsResponse
    public var rawRecording: RawRecordingSettingsResponse
    public var recording: RecordSettingsResponse
    public var ring: RingSettings
    public var screensharing: ScreensharingSettings
    public var session: SessionSettingsResponse
    public var thumbnails: ThumbnailsSettings
    public var transcription: TranscriptionSettings
    public var video: VideoSettings

    public init(audio: AudioSettings, backstage: BackstageSettings, broadcasting: BroadcastSettingsResponse, frameRecording: FrameRecordingSettingsResponse, geofencing: GeofenceSettings, individualRecording: IndividualRecordingSettingsResponse, ingress: IngressSettingsResponse? = nil, limits: LimitsSettingsResponse, rawRecording: RawRecordingSettingsResponse, recording: RecordSettingsResponse, ring: RingSettings, screensharing: ScreensharingSettings, session: SessionSettingsResponse, thumbnails: ThumbnailsSettings, transcription: TranscriptionSettings, video: VideoSettings) {
        self.audio = audio
        self.backstage = backstage
        self.broadcasting = broadcasting
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

    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case backstage
        case broadcasting
        case frameRecording = "frame_recording"
        case geofencing
        case individualRecording = "individual_recording"
        case ingress
        case limits
        case rawRecording = "raw_recording"
        case recording
        case ring
        case screensharing
        case session
        case thumbnails
        case transcription
        case video
    }

    public static func == (lhs: CallSettingsResponse, rhs: CallSettingsResponse) -> Bool {
        lhs.audio == rhs.audio &&
        lhs.backstage == rhs.backstage &&
        lhs.broadcasting == rhs.broadcasting &&
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
