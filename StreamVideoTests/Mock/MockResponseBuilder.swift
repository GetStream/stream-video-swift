//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo

class MockResponseBuilder {
    
    func makeJoinCallResponse(cid: String, recording: Bool = false) -> JoinCallResponse {
        JoinCallResponse(
            blockedUsers: [],
            call: makeCallResponse(cid: cid, recording: recording),
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
            acceptedBy: acceptedBy,
            rejectedBy: rejectedBy,
            liveStartedAt: liveStartedAt,
            liveEndedAt: liveEndedAt
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
            recording: recording,
            session: session,
            settings: makeCallSettingsResponse(),
            transcribing: false,
            type: "default",
            updatedAt: Date()
        )
        return callResponse
    }
    
    func makeQueryCallsResponse() -> QueryCallsResponse {
        let first = CallStateResponseFields(
            blockedUsers: [],
            call: makeCallResponse(cid: "default:123"),
            members: [],
            ownCapabilities: [.sendAudio, .sendVideo]
        )
        let second = CallStateResponseFields(
            blockedUsers: [],
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
            defaultDevice: .speaker,
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
    
    func makeCallParticipant(
        id: String,
        name: String = "",
        roles: [String] = [],
        hasVideo: Bool = false,
        hasAudio: Bool = false,
        isScreenSharing: Bool = false,
        isSpeaking: Bool = false,
        isDominantSpeaker: Bool = false,
        pin: PinInfo? = nil
    ) -> CallParticipant {
        let participant = CallParticipant(
            id: id,
            userId: id,
            roles: roles,
            name: name,
            profileImageURL: nil,
            trackLookupPrefix: nil,
            hasVideo: hasVideo,
            hasAudio: hasAudio,
            isScreenSharing: isScreenSharing,
            showTrack: true,
            track: nil,
            trackSize: .zero,
            screenshareTrack: nil,
            isSpeaking: isSpeaking,
            isDominantSpeaker: isDominantSpeaker,
            sessionId: id,
            connectionQuality: .unknown,
            joinedAt: Date(),
            audioLevel: 0,
            audioLevels: [],
            pin: pin
        )
        return participant
    }
    
    func makeCallSessionResponse(
        acceptedBy: [String: Date] = [:],
        rejectedBy: [String: Date] = [:],
        liveStartedAt: Date? = nil,
        liveEndedAt: Date? = nil
    ) -> CallSessionResponse {
        CallSessionResponse(
            acceptedBy: acceptedBy,
            endedAt: liveEndedAt,
            id: "test",
            liveEndedAt: liveEndedAt,
            liveStartedAt: liveStartedAt,
            participants: [],
            participantsCountByRole: [:],
            rejectedBy: rejectedBy,
            startedAt: liveStartedAt
        )
    }
    
}
