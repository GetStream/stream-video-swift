//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension CallSettingsResponse {
    static func dummy(
        audio: AudioSettings = AudioSettings.dummy(),
        backstage: BackstageSettings = BackstageSettings.dummy(),
        broadcasting: BroadcastSettingsResponse = BroadcastSettingsResponse.dummy(),
        geofencing: GeofenceSettings = GeofenceSettings.dummy(),
        limits: LimitsSettingsResponse = LimitsSettingsResponse.dummy(),
        recording: RecordSettingsResponse = RecordSettingsResponse.dummy(),
        ring: RingSettings = RingSettings.dummy(),
        screensharing: ScreensharingSettings = ScreensharingSettings.dummy(),
        thumbnails: ThumbnailsSettings = ThumbnailsSettings.dummy(),
        transcription: TranscriptionSettings = TranscriptionSettings.dummy(),
        video: VideoSettings = VideoSettings.dummy(),
        sessionSettings: SessionSettingsResponse = SessionSettingsResponse.dummy()
    ) -> CallSettingsResponse {
        .init(
            audio: audio,
            backstage: backstage,
            broadcasting: broadcasting,
            geofencing: geofencing,
            limits: limits,
            recording: recording,
            ring: ring,
            screensharing: screensharing,
            session: sessionSettings,
            thumbnails: thumbnails,
            transcription: transcription,
            video: video
        )
    }
}
