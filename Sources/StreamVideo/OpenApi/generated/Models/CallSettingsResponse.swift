//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallSettingsResponse: Codable, JSONEncodable, Hashable {

    internal var audio: AudioSettings
    internal var broadcasting: BroadcastSettings
    internal var geofencing: GeofenceSettings
    internal var recording: RecordSettings
    internal var screensharing: ScreensharingSettings
    internal var video: VideoSettings

    internal init(
        audio: AudioSettings,
        broadcasting: BroadcastSettings,
        geofencing: GeofenceSettings,
        recording: RecordSettings,
        screensharing: ScreensharingSettings,
        video: VideoSettings
    ) {
        self.audio = audio
        self.broadcasting = broadcasting
        self.geofencing = geofencing
        self.recording = recording
        self.screensharing = screensharing
        self.video = video
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case audio
        case broadcasting
        case geofencing
        case recording
        case screensharing
        case video
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(audio, forKey: .audio)
        try container.encode(broadcasting, forKey: .broadcasting)
        try container.encode(geofencing, forKey: .geofencing)
        try container.encode(recording, forKey: .recording)
        try container.encode(screensharing, forKey: .screensharing)
        try container.encode(video, forKey: .video)
    }
}
