//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
    
public struct CallSettingsRequest: @unchecked Sendable, Codable, JSONEncodable, Hashable {
    
    public var audio: AudioSettingsRequest? = nil
    public var backstage: BackstageSettingsRequest? = nil
    public var broadcasting: BroadcastSettingsRequest? = nil
    public var geofencing: GeofenceSettingsRequest? = nil
    public var limits: LimitsSettingsRequest? = nil
    public var recording: RecordSettingsRequest? = nil
    public var ring: RingSettingsRequest? = nil
    public var screensharing: ScreensharingSettingsRequest? = nil
    public var thumbnails: ThumbnailsSettingsRequest? = nil
    public var transcription: TranscriptionSettingsRequest? = nil
    public var video: VideoSettingsRequest? = nil

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
