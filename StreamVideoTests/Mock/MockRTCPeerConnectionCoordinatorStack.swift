//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC

struct MockRTCPeerConnectionCoordinatorStack: @unchecked Sendable {

    let sessionId: String
    let peerConnection: MockRTCPeerConnection
    let peerConnectionFactory: PeerConnectionFactory
    let mockSFUStack: MockSFUStack
    let audioSession: CallAudioSession
    let spySubject: PassthroughSubject<TrackEvent, Never>
    let mockLocalAudioMediaAdapter: MockLocalMediaAdapter
    let mockLocalVideoMediaAdapter: MockLocalMediaAdapter
    let mockLocalScreenSharingMediaAdapter: MockLocalMediaAdapter
    let audioMediaAdapter: AudioMediaAdapter
    let videoMediaAdapter: VideoMediaAdapter
    let screenShareMediaAdapter: ScreenShareMediaAdapter
    let mediaAdapter: MediaAdapter
    let iceAdapter: ICEAdapter
    let iceConnectionStateAdapter: ICEConnectionStateAdapter
    let coordinator: RTCPeerConnectionCoordinator

    init(
        peerType: PeerConnectionType,
        videoOptions: VideoOptions = .init(),
        callSettings: CallSettings = .init(),
        audioSettings: AudioSettings = .init(),
        publishOptions: PublishOptions = .init(),
        sessionId: String = .unique,
        peerConnection: MockRTCPeerConnection = .init(),
        peerConnectionFactory: PeerConnectionFactory = .mock(),
        mockSFUStack: MockSFUStack = .init(),
        audioSession: CallAudioSession? = nil,
        spySubject: PassthroughSubject<TrackEvent, Never> = .init(),
        mockLocalAudioMediaAdapter: MockLocalMediaAdapter = .init(),
        mockLocalVideoMediaAdapter: MockLocalMediaAdapter = .init(),
        mockLocalScreenSharingMediaAdapter: MockLocalMediaAdapter = .init(),
        clientCapabilities: Set<ClientCapability> = []
    ) {
        self.sessionId = sessionId
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.mockSFUStack = mockSFUStack
        self.audioSession = audioSession ?? .init()
        self.spySubject = spySubject
        self.mockLocalAudioMediaAdapter = mockLocalAudioMediaAdapter
        self.mockLocalVideoMediaAdapter = mockLocalVideoMediaAdapter
        self.mockLocalScreenSharingMediaAdapter = mockLocalScreenSharingMediaAdapter

        let audioMediaAdapter = AudioMediaAdapter(
            sessionID: sessionId,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: mockLocalAudioMediaAdapter,
            subject: spySubject
        )
        self.audioMediaAdapter = audioMediaAdapter

        let videoMediaAdapter = VideoMediaAdapter(
            sessionID: sessionId,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: mockLocalVideoMediaAdapter,
            subject: spySubject
        )
        self.videoMediaAdapter = videoMediaAdapter

        let screenShareMediaAdapter = ScreenShareMediaAdapter(
            sessionID: sessionId,
            peerConnection: peerConnection,
            peerConnectionFactory: peerConnectionFactory,
            localMediaManager: mockLocalScreenSharingMediaAdapter,
            subject: spySubject
        )
        self.screenShareMediaAdapter = screenShareMediaAdapter

        let mediaAdapter = MediaAdapter(
            subject: spySubject,
            audioMediaAdapter: audioMediaAdapter,
            videoMediaAdapter: videoMediaAdapter,
            screenShareMediaAdapter: screenShareMediaAdapter
        )
        self.mediaAdapter = mediaAdapter

        let iceAdapter = ICEAdapter(
            sessionID: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            sfuAdapter: mockSFUStack.adapter
        )
        self.iceAdapter = iceAdapter

        let iceConnectionStateAdapter = ICEConnectionStateAdapter()
        self.iceConnectionStateAdapter = iceConnectionStateAdapter

        coordinator = .init(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            publishOptions: publishOptions,
            sfuAdapter: mockSFUStack.adapter,
            mediaAdapter: mediaAdapter,
            iceAdapter: iceAdapter,
            iceConnectionStateAdapter: iceConnectionStateAdapter,
            clientCapabilities: clientCapabilities
        )
    }
}
