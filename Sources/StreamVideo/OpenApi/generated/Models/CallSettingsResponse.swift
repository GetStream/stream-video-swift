//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSettingsResponse: @unchecked Sendable, Event, Codable, JSONEncodable, Hashable {
    
    public var audio: AudioSettings
    public var backstage: BackstageSettingsResponse
    public var broadcasting: BroadcastSettingsResponse
    public var geofencing: GeofenceSettingsResponse
    public var limits: LimitsSettingsResponse
    public var recording: RecordSettingsResponse
    public var ring: RingSettingsResponse
    public var screensharing: ScreensharingSettingsResponse
    public var thumbnails: ThumbnailsSettingsResponse
    public var transcription: TranscriptionSettingsResponse
    public var video: VideoSettingsResponse

    public init(
        audio: AudioSettings,
        backstage: BackstageSettingsResponse,
        broadcasting: BroadcastSettingsResponse,
        geofencing: GeofenceSettingsResponse,
        limits: LimitsSettingsResponse,
        recording: RecordSettingsResponse,
        ring: RingSettingsResponse,
        screensharing: ScreensharingSettingsResponse,
        thumbnails: ThumbnailsSettingsResponse,
        transcription: TranscriptionSettingsResponse,
        video: VideoSettingsResponse
    ) {
        self.audio = audio
        self.backstage = backstage
        self.broadcasting = broadcasting
        self.geofencing = geofencing
        self.limits = limits
        self.recording = recording
        self.ring = ring
        self.screensharing = screensharing
        self.thumbnails = thumbnails
        self.transcription = transcription
        self.video = video
    }
    
    public enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case backstage
        case broadcasting
        case geofencing
        case limits
        case recording
        case ring
        case screensharing
        case thumbnails
        case transcription
        case video
    }
}
