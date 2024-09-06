//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var audio: AudioSettingsRequest?
    public var backstage: BackstageSettingsRequest?
    public var broadcasting: BroadcastSettingsRequest?
    public var geofencing: GeofenceSettingsRequest?
    public var limits: LimitsSettingsRequest?
    public var recording: RecordSettingsRequest?
    public var ring: RingSettingsRequest?
    public var screensharing: ScreensharingSettingsRequest?
    public var thumbnails: ThumbnailsSettingsRequest?
    public var transcription: TranscriptionSettingsRequest?
    public var video: VideoSettingsRequest?

    public init(
        audio: AudioSettingsRequest? = nil,
        backstage: BackstageSettingsRequest? = nil,
        broadcasting: BroadcastSettingsRequest? = nil,
        geofencing: GeofenceSettingsRequest? = nil,
        limits: LimitsSettingsRequest? = nil,
        recording: RecordSettingsRequest? = nil,
        ring: RingSettingsRequest? = nil,
        screensharing: ScreensharingSettingsRequest? = nil,
        thumbnails: ThumbnailsSettingsRequest? = nil,
        transcription: TranscriptionSettingsRequest? = nil,
        video: VideoSettingsRequest? = nil
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
