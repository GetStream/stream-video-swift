//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class CallSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    public var audio: AudioSettingsRequest?
    public var backstage: BackstageSettingsRequest?
    public var broadcasting: BroadcastSettingsRequest?
    public var frameRecording: FrameRecordingSettingsRequest?
    public var geofencing: GeofenceSettingsRequest?
    public var individualRecording: IndividualRecordingSettingsRequest?
    public var ingress: IngressSettingsRequest?
    public var limits: LimitsSettingsRequest?
    public var rawRecording: RawRecordingSettingsRequest?
    public var recording: RecordSettingsRequest?
    public var ring: RingSettingsRequest?
    public var screensharing: ScreensharingSettingsRequest?
    public var session: SessionSettingsRequest?
    public var thumbnails: ThumbnailsSettingsRequest?
    public var transcription: TranscriptionSettingsRequest?
    public var video: VideoSettingsRequest?

    public init(audio: AudioSettingsRequest? = nil, backstage: BackstageSettingsRequest? = nil, broadcasting: BroadcastSettingsRequest? = nil, frameRecording: FrameRecordingSettingsRequest? = nil, geofencing: GeofenceSettingsRequest? = nil, individualRecording: IndividualRecordingSettingsRequest? = nil, ingress: IngressSettingsRequest? = nil, limits: LimitsSettingsRequest? = nil, rawRecording: RawRecordingSettingsRequest? = nil, recording: RecordSettingsRequest? = nil, ring: RingSettingsRequest? = nil, screensharing: ScreensharingSettingsRequest? = nil, session: SessionSettingsRequest? = nil, thumbnails: ThumbnailsSettingsRequest? = nil, transcription: TranscriptionSettingsRequest? = nil, video: VideoSettingsRequest? = nil) {
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

    public static func == (lhs: CallSettingsRequest, rhs: CallSettingsRequest) -> Bool {
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
