//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class AudioMediaAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var mockMediaAdapter: MockLocalMediaAdapter! = .init()
    private lazy var subject: AudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        localMediaManager: mockMediaAdapter,
        subject: spySubject
    )

    override func tearDown() {
        subject = nil
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

    // MARK: - didUpdatePublishOptions(_:)

    func test_didUpdatePublishOptions_didUpdatePublishOptionsWasCalledOnLocalMediaAdapter() async throws {
        let publishOptions = PublishOptions.dummy(audio: [.dummy(codec: .red)])

        try await subject.didUpdatePublishOptions(publishOptions)

        let actual = try XCTUnwrap(
            mockMediaAdapter.recordedInputPayload(PublishOptions.self, for: .didUpdatePublishOptions)?.first
        )
        XCTAssertEqual(actual, publishOptions)
    }

    // MARK: - trackInfo

    func test_trackInfo_allAvailable_trackInfoWasCalledOnLocalMediaAdapter() {
        let expected: [Stream_Video_Sfu_Models_TrackInfo] = [
            .dummy(trackType: .audio, mid: "0"),
            .dummy(trackType: .audio, mid: "1")
        ]
        mockMediaAdapter.stub(
            for: .trackInfo,
            with: expected
        )

        let actual = subject.trackInfo(for: .allAvailable)

        XCTAssertEqual(
            mockMediaAdapter.recordedInputPayload(RTCPeerConnectionTrackInfoCollectionType.self, for: .trackInfo)?.first,
            .allAvailable
        )
        XCTAssertEqual(actual, expected)
    }

    func test_trackInfo_lastPublishOptions_trackInfoWasCalledOnLocalMediaAdapter() {
        let expected: [Stream_Video_Sfu_Models_TrackInfo] = [
            .dummy(trackType: .audio, mid: "0"),
            .dummy(trackType: .audio, mid: "1")
        ]
        mockMediaAdapter.stub(
            for: .trackInfo,
            with: expected
        )

        let actual = subject.trackInfo(for: .lastPublishOptions)

        XCTAssertEqual(
            mockMediaAdapter.recordedInputPayload(RTCPeerConnectionTrackInfoCollectionType.self, for: .trackInfo)?.first,
            .lastPublishOptions
        )
        XCTAssertEqual(actual, expected)
    }
}
