//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioMediaAdapter_Tests: XCTestCase {

    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var mockMediaAdapter: MockLocalMediaAdapter! = .init()
    private lazy var audioSession: AudioSession! = .init()
    private lazy var subject: AudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockMediaAdapter,
        subject: spySubject,
        audioSession: audioSession
    )

    override func tearDown() {
        subject = nil
        audioSession = nil
        spySubject = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        sessionId = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_setUpWasCalledOnLocalMediaAdapter() async throws {
        let settings = CallSettings(audioOn: false, videoOn: true)
        let ownCapabilities = [OwnCapability.createCall, .sendAudio, .sendVideo]

        try await subject.setUp(with: settings, ownCapabilities: ownCapabilities)

        let actual = try XCTUnwrap(
            mockMediaAdapter.recordedInputPayload((CallSettings, [OwnCapability]).self, for: .setUp)?.first
        )
        XCTAssertEqual(actual.0, settings)
        XCTAssertEqual(actual.1, ownCapabilities)
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_didUpdateCallSettingsWasCalledOnLocalMediaAdapter() async throws {
        let settings = CallSettings(audioOn: false, videoOn: true)

        try await subject.didUpdateCallSettings(settings)

        let actual = try XCTUnwrap(
            mockMediaAdapter.recordedInputPayload(CallSettings.self, for: .didUpdateCallSettings)?.first
        )
        XCTAssertEqual(actual, settings)
    }

    // MARK: - didUpdateAudioSessionState(_:)

    func test_didUpdateAudioSessionState_audioSessionWasConfiguredCorrectly() async throws {
        await subject.didUpdateAudioSessionState(true)

        let isActive = await audioSession.isAudioEnabled
        XCTAssertTrue(isActive)
    }

    // MARK: - didUpdateAudioSessionSpeakerState(_:)

    func test_didUpdateAudioSessionSpeakerState_audioSessionWasConfiguredCorrectly() async throws {
        await subject.didUpdateAudioSessionSpeakerState(true, with: false)

        let isActive = await audioSession.isActive
        let isSpeakerOn = await audioSession.isSpeakerOn
        XCTAssertFalse(isActive)
        XCTAssertTrue(isSpeakerOn)
    }
}
