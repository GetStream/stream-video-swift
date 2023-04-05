//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class MockResponseBuilder {
    
    func makeCallSettingsResponse() -> CallSettingsResponse {
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true
        )
        let backstageSettings = BackstageSettings(enabled: false)
        let broadcastSettings = BroadcastSettings(
            enabled: false,
            hls: HLSSettings(autoOn: false, enabled: false, qualityTracks: [])
        )
        let geofenceSettings = GeofenceSettings(names: [])
        let recordSettings = RecordSettings(
            audioOnly: false,
            mode: .disabled,
            quality: ._1080p
        )
        let ringSettings = RingSettings(
            autoCancelTimeoutMs: 15000,
            autoRejectTimeoutMs: 15000
        )
        let screensharingSettings = ScreensharingSettings(
            accessRequestEnabled: true,
            enabled: true
        )
        let transcriptionSettings = TranscriptionSettings(
            closedCaptionMode: "",
            mode: .disabled
        )
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            enabled: true
        )
        
        return CallSettingsResponse(
            audio: audioSettings,
            backstage: backstageSettings,
            broadcasting: broadcastSettings,
            geofencing: geofenceSettings,
            recording: recordSettings,
            ring: ringSettings,
            screensharing: screensharingSettings,
            transcription: transcriptionSettings,
            video: videoSettings
        )
    }
    
}
