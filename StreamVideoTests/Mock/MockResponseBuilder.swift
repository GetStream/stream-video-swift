//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class MockResponseBuilder {
    
    func makeJoinCallResponse(cid: String) -> JoinCallResponse {
        JoinCallResponse(
            blockedUsers: [],
            call: makeCallResponse(cid: cid),
            created: true,
            credentials: Credentials(
                iceServers: [],
                server: SFUResponse(
                    edgeName: "test",
                    url: "test.com",
                    wsEndpoint: "wss://test.com"
                ),
                token: "test")
            ,
            duration: "1.0",
            members: [],
            ownCapabilities: [.sendAudio, .sendVideo]
        )
    }
    
    func makeCallResponse(
        cid: String,
        acceptedBy: [String: Date] = [:],
        rejectedBy: [String: Date] = [:]
    ) -> CallResponse {
        let userResponse = makeUserResponse()
        let callIngressResponse = CallIngressResponse(
            rtmp: RTMPIngress(address: "test")
        )
        let session = CallSessionResponse(
            acceptedBy: acceptedBy,
            id: "test",
            participants: [],
            participantsCountByRole: [:],
            rejectedBy: rejectedBy
        )
        let callResponse = CallResponse(
            backstage: false,
            blockedUserIds: [],
            cid: cid,
            createdAt: Date(),
            createdBy: userResponse,
            currentSessionId: "123",
            custom: [:],
            egress: EgressResponse(
                broadcasting: false,
                rtmps: []
            ),
            id: "123",
            ingress: callIngressResponse,
            recording: false,
            session: session,
            settings: makeCallSettingsResponse(),
            transcribing: false,
            type: "default",
            updatedAt: Date()
        )
        return callResponse
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
            createdAt: Date(),
            custom: [:],
            id: id,
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
    
    func makeCallSettingsResponse() -> CallSettingsResponse {
        let audioSettings = AudioSettings(
            accessRequestEnabled: true,
            micDefaultOn: true,
            opusDtxEnabled: true,
            redundantCodingEnabled: true,
            speakerDefaultOn: true
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
            incomingCallTimeoutMs: 15000
        )
        let screensharingSettings = ScreensharingSettings(
            accessRequestEnabled: false,
            enabled: true
        )
        let transcriptionSettings = TranscriptionSettings(
            closedCaptionMode: "",
            mode: .disabled
        )
        let videoSettings = VideoSettings(
            accessRequestEnabled: true,
            cameraDefaultOn: true,
            cameraFacing: .front,
            enabled: true,
            targetResolution: .init(bitrate: 100, height: 100, width: 100)
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
