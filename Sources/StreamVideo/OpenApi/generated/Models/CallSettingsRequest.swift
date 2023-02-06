//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
#if canImport(AnyCodable)
import AnyCodable
#endif

internal struct CallSettingsRequest: Codable, JSONEncodable, Hashable {

    internal var geofencing: GeofenceSettingsRequest?
    internal var recording: RecordSettingsRequest?
    internal var screensharing: ScreensharingSettingsRequest?
    internal var video: VideoSettingsRequest?

    internal init(
        geofencing: GeofenceSettingsRequest? = nil,
        recording: RecordSettingsRequest? = nil,
        screensharing: ScreensharingSettingsRequest? = nil,
        video: VideoSettingsRequest? = nil
    ) {
        self.geofencing = geofencing
        self.recording = recording
        self.screensharing = screensharing
        self.video = video
    }

    internal enum CodingKeys: String, CodingKey, CaseIterable {
        case geofencing
        case recording
        case screensharing
        case video
    }

    // Encodable protocol methods

    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(geofencing, forKey: .geofencing)
        try container.encodeIfPresent(recording, forKey: .recording)
        try container.encodeIfPresent(screensharing, forKey: .screensharing)
        try container.encodeIfPresent(video, forKey: .video)
    }
}
