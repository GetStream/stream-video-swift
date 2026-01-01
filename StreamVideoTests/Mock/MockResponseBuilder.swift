//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class MockResponseBuilder: @unchecked Sendable {
    
    func makeJoinCallResponse(cid: String, recording: Bool = false) -> JoinCallResponse {
        JoinCallResponse(
            call: makeCallResponse(cid: cid, recording: recording),
            created: true,
            credentials: Credentials(
                iceServers: [],
                server: SFUResponse(
                    edgeName: "test",
                    url: "test.com",
                    wsEndpoint: "wss://test.com"
                ),
                token: "test"
            ),
            
            duration: "1.0",
            members: [],
            ownCapabilities: [.sendAudio, .sendVideo],
            statsOptions: StatsOptions(enableRtcStats: false, reportingIntervalMs: 10000)
        )
    }
    
    func makeCallResponse(
        cid: String,
        acceptedBy: [String: Date] = [:],
        rejectedBy: [String: Date] = [:],
        recording: Bool = false,
        liveStartedAt: Date? = nil,
        liveEndedAt: Date? = nil
    ) -> CallResponse {
        let userResponse = makeUserResponse()
        let callIngressResponse = CallIngressResponse(
            rtmp: RTMPIngress(address: "test")
        )
        let session = makeCallSessionResponse(
            cid: cid,
            acceptedBy: acceptedBy,
            rejectedBy: rejectedBy,
            liveStartedAt: liveStartedAt,
            liveEndedAt: liveEndedAt
        )
        let callResponse = CallResponse(
            backstage: false,
            blockedUserIds: [],
            captioning: false,
            cid: cid,
            createdAt: Date(),
            createdBy: userResponse,
            currentSessionId: String(cid.split(separator: ":")[1]),
            custom: [:],
            egress: EgressResponse(
                broadcasting: false,
                rtmps: []
            ),
            id: String(cid.split(separator: ":")[1]),
            ingress: callIngressResponse,
            recording: recording,
            session: session,
            settings: makeCallSettingsResponse(),
            transcribing: false,
            type: String(cid.split(separator: ":")[0]),
            updatedAt: Date()
        )
        return callResponse
    }
    
    func makeQueryCallsResponse() -> QueryCallsResponse {
        let first = CallStateResponseFields(
            call: makeCallResponse(cid: "default:123"),
            members: [],
            ownCapabilities: [.sendAudio, .sendVideo]
        )
        let second = CallStateResponseFields(
            call: makeCallResponse(cid: "default:test"),
            members: [],
            ownCapabilities: [.sendAudio, .sendVideo]
        )
        let response = QueryCallsResponse(
            calls: [first, second],
            duration: "1.0"
        )
        return response
    }
    
    func makeMemberResponse(id: String = "test") -> MemberResponse {
        MemberResponse(
            createdAt: Date(),
            custom: [:],
            updatedAt: Date(),
            user: makeUserResponse(id: id),
            userId: id
        )
    }
    
    func makeUserResponse(id: String = "test") -> UserResponse {
        UserResponse(
            blockedUserIds: [],
            createdAt: Date(),
            custom: [:],
            id: id,
            language: "en",
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
    
    func makeCallSettingsResponse() -> CallSettingsResponse {
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            defaultDevice: .speaker,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
        )
        let backstageSettings = BackstageSettings(enabled: false)
        let broadcastSettings = BroadcastSettingsResponse(
            enabled: false,
            hls: HLSSettingsResponse(
                autoOn: false,
                enabled: false, qualityTracks: []
            ),
            rtmp: .init(enabled: true, quality: "good")
        )
        let geofenceSettings = GeofenceSettings(names: [])
        let recordSettings = RecordSettingsResponse(
            audioOnly: false,
            mode: "disabled",
            quality: "1080p"
        )
        let ringSettings = RingSettings(
            autoCancelTimeoutMs: 15000,
            incomingCallTimeoutMs: 15000,
            missedCallTimeoutMs: 15000
        )
        let screensharingSettings = ScreensharingSettings(
            accessRequestEnabled: false,
            enabled: true
        )
        let transcriptionSettings = TranscriptionSettings(
            closedCaptionMode: .available,
            language: .auto,
            mode: .disabled
        )
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: true,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
        )
        let thumbnailsSettings = ThumbnailsSettings(enabled: false)
        let sessionSettingsResponse = SessionSettingsResponse(inactivityTimeoutSeconds: 10)
        
        return CallSettingsResponse(
            audio: audioSettings,
            backstage: backstageSettings,
            broadcasting: broadcastSettings,
            geofencing: geofenceSettings,
            limits: .dummy(),
            recording: recordSettings,
            ring: ringSettings,
            screensharing: screensharingSettings,
            session: sessionSettingsResponse,
            thumbnails: thumbnailsSettings,
            transcription: transcriptionSettings,
            video: videoSettings
        )
    }
    
    func makeCallSessionResponse(
        cid: String,
        acceptedBy: [String: Date] = [:],
        rejectedBy: [String: Date] = [:],
        liveStartedAt: Date? = nil,
        liveEndedAt: Date? = nil
    ) -> CallSessionResponse {
        CallSessionResponse(
            acceptedBy: acceptedBy,
            anonymousParticipantCount: 0,
            endedAt: liveEndedAt,
            id: cid,
            liveEndedAt: liveEndedAt,
            liveStartedAt: liveStartedAt,
            missedBy: [:],
            participants: [],
            participantsCountByRole: [:],
            rejectedBy: rejectedBy,
            startedAt: liveStartedAt
        )
    }
}
