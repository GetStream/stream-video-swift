//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC

struct MockRTCPeerConnectionCoordinatorStack {

    let sessionId: String
    let peerConnection: MockRTCPeerConnection
    let peerConnectionFactory: PeerConnectionFactory
    let mockSFUStack: MockSFUStack
    let audioSession: StreamAudioSessionAdapter
    let spySubject: PassthroughSubject<TrackEvent, Never>
    let mockLocalAudioMediaAdapter: MockLocalMediaAdapter
    let mockLocalVideoMediaAdapter: MockLocalMediaAdapter
    let mockLocalScreenSharingMediaAdapter: MockLocalMediaAdapter
    let audioMediaAdapter: AudioMediaAdapter
    let videoMediaAdapter: VideoMediaAdapter
    let screenShareMediaAdapter: ScreenShareMediaAdapter
    let mediaAdapter: MediaAdapter
    let coordinator: RTCPeerConnectionCoordinator

    init(
        peerType: PeerConnectionType,
        videoOptions: VideoOptions = .init(),
        callSettings: CallSettings = .init(),
        audioSettings: AudioSettings = .init(),
        sessionId: String = .unique,
        peerConnection: MockRTCPeerConnection = .init(),
        peerConnectionFactory: PeerConnectionFactory = .mock(),
        mockSFUStack: MockSFUStack = .init(),
        audioSession: StreamAudioSessionAdapter = .init(),
        spySubject: PassthroughSubject<TrackEvent, Never> = .init(),
        mockLocalAudioMediaAdapter: MockLocalMediaAdapter = .init(),
        mockLocalVideoMediaAdapter: MockLocalMediaAdapter = .init(),
        mockLocalScreenSharingMediaAdapter: MockLocalMediaAdapter = .init()
    ) {
        self.sessionId = sessionId
        self.peerConnection = peerConnection
        self.peerConnectionFactory = peerConnectionFactory
        self.mockSFUStack = mockSFUStack
        self.audioSession = audioSession
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
        coordinator = .init(
            sessionId: sessionId,
            peerType: peerType,
            peerConnection: peerConnection,
            videoOptions: videoOptions,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: mockSFUStack.adapter,
            mediaAdapter: mediaAdapter
        )
    }
}
