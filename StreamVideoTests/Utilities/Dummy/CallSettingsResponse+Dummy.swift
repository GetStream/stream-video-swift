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
        frameRecording: FrameRecordingSettingsResponse =
            FrameRecordingSettingsResponse.dummy(),
        geofencing: GeofenceSettings = GeofenceSettings.dummy(),
        individualRecording: IndividualRecordingSettingsResponse =
            IndividualRecordingSettingsResponse.dummy(),
        limits: LimitsSettingsResponse = LimitsSettingsResponse.dummy(),
        rawRecording: RawRecordingSettingsResponse =
            RawRecordingSettingsResponse.dummy(),
        recording: RecordSettingsResponse = RecordSettingsResponse.dummy(),
        ring: RingSettings = RingSettings.dummy(),
        screensharing: ScreensharingSettings = ScreensharingSettings.dummy(),
        thumbnails: ThumbnailsSettings = ThumbnailsSettings.dummy(),
        transcription: TranscriptionSettings = TranscriptionSettings.dummy(),
        video: VideoSettings = VideoSettings.dummy(),
        sessionSettings: SessionSettingsResponse = SessionSettingsResponse.dummy(),
        encryption: EncryptionSettingsResponse = EncryptionSettingsResponse.dummy()
    ) -> CallSettingsResponse {
        .init(
            audio: audio,
            backstage: backstage,
            broadcasting: broadcasting,
            encryption: encryption,
            frameRecording: frameRecording,
            geofencing: geofencing,
            individualRecording: individualRecording,
            limits: limits,
            rawRecording: rawRecording,
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
