//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class LocalScreenShareMediaAdapter_Tests: XCTestCase {

    private let mockActiveCallProvider: MockActiveCallProvider! = .init()
    private let mockAudioRecorder: MockStreamCallAudioRecorder! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var mockCapturerFactory: MockVideoCapturerFactory! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var screenShareSessionProvider: ScreenShareSessionProvider! = .init()
    private lazy var subject: LocalScreenShareMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        videoOptions: .init(),
        videoConfig: .dummy(),
        subject: spySubject,
        screenShareSessionProvider: screenShareSessionProvider,
        capturerFactory: mockCapturerFactory
    )

    private var temporaryPeerConnection: RTCPeerConnection?

    override func tearDown() {
        subject = nil
        spySubject = nil
        mockCapturerFactory = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        screenShareSessionProvider = nil
        temporaryPeerConnection = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_noOperation() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.screenshare]
        )

        XCTAssertNil(subject.localTrack)
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_noOperation() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.screenshare]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))

        XCTAssertNil(subject.localTrack)
    }

    // MARK: - beginScreenSharing(of:ownCapabilities:)

    func test_beginScreenSharing_withCapabilityWithoutPriorTrack_createsTrackAndTransceiver() async throws {
        try await assertBeginScreenSharing(
            .inApp,
            ownCapabilities: [.screenshare]
        )
        XCTAssertNotNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_beginScreenSharing_withCapabilityWithPriorTrack_createsTrackAndTransceiverAfterClearingPreviousOne() async throws {
        // Given
        try await assertBeginScreenSharing(
            .inApp,
            ownCapabilities: [.screenshare]
        )

        // When
        try await assertBeginScreenSharing(
            .broadcast,
            ownCapabilities: [.screenshare]
        )

        // Then
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 2)
    }

    func test_beginScreenSharing_withCapability_callSFU() async throws {
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .screenShare)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_beginScreenSharing_withCapability_videoCapturerStartsCapturing() async throws {
        let mockCapturer = MockVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: mockCapturer)

        // When
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        // Then
        XCTAssertEqual(mockCapturer.stubbedFunctionInput[.startCapture]?.count, 1)
    }

    func test_beginScreenSharing_withCapability_sessionProviderHasBeenUpdated() async throws {
        let mockCapturer = MockVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: mockCapturer)

        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        XCTAssertTrue(
            screenShareSessionProvider.activeSession?.localTrack === subject.localTrack
        )
        XCTAssertEqual(
            screenShareSessionProvider.activeSession?.screenSharingType, .inApp
        )
        XCTAssertTrue(
            (screenShareSessionProvider.activeSession?.capturer as? MockVideoCapturer) === mockCapturer
        )
    }

    func test_beginScreenSharing_withoutCapability_noAction() async throws {
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [])

        XCTAssertNil(screenShareSessionProvider.activeSession)
    }

    // MARK: - stopScreenSharing

    func test_stopScreenSharing_callSFU() async throws {
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        try await subject.stopScreenSharing()

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .screenShare)
        XCTAssertTrue(request.muteStates[0].muted)
    }

    func test_stopScreenSharing_videoCapturerStopsCapturing() async throws {
        let mockCapturer = MockVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: mockCapturer)
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        // When
        try await subject.stopScreenSharing()

        await fulfillment { [mockCapturer] in
            mockCapturer.stubbedFunctionInput[.stopCapture]?.count == 1
        }
    }

    func test_stopScreenSharing_sessionProvideHasBeenUpdated() async throws {
        try await assertBeginScreenSharing(.inApp, ownCapabilities: [.screenshare])

        try await subject.stopScreenSharing()

        XCTAssertNil(screenShareSessionProvider.activeSession)
    }

    // MARK: - publish

    func test_publish_disabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .screenshare)
        )
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare]
        )

        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    func test_publish_disabledLocalTrack_transceiverHasBeenCreated_enablesAndAddsTrack() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .screenshare, codecs: [VideoCodec.screenshare])
        )
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare]
        )

        let transceiver = try XCTUnwrap(mockPeerConnection.stubbedFunction[.addTransceiver] as? RTCRtpTransceiver)
        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
        /// When there is only one encoding on the transceiver, WebRTC internally, removes the rid
        XCTAssertEqual(
            transceiver.sender.parameters.encodings.compactMap(\.maxBitrateBps),
            [NSNumber(value: VideoCodec.screenshare.maxBitrate)]
        )
    }

    // MARK: - unpublish

    func test_publish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .screenshare)
        )
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare]
        )
        subject.localTrack?.isEnabled = true

        subject.unpublish()

        XCTAssertFalse(subject.localTrack?.isEnabled ?? true)
    }

    // MARK: - Private

    private func assertAsyncOperation<T>(
        _ operation: @escaping () async throws -> T,
        validationHandler: @escaping (T, XCTestExpectation, StaticString, UInt) throws -> Void = { _, _, _, _ in },
        file: StaticString = #file,
        line: UInt = #line
    ) -> XCTestExpectation {
        let expectation = self.expectation(description: "Assert async expectation")
        Task {
            do {
                try validationHandler(try await operation(), expectation, file, line)
            } catch { /* No-op */ }
        }
        return expectation
    }

    private func makeTransceiver(
        of type: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        codecs: [VideoCodec]? = nil
    ) throws -> RTCRtpTransceiver {
        if temporaryPeerConnection == nil {
            temporaryPeerConnection = try peerConnectionFactory.makePeerConnection(
                configuration: .init(),
                constraints: .defaultConstraints,
                delegate: nil
            )
        }

        return temporaryPeerConnection!.addTransceiver(
            of: type == .audio ? .audio : .video,
            init: RTCRtpTransceiverInit(
                trackType: type,
                direction: direction,
                streamIds: streamIds,
                codecs: codecs
            )
        )!
    }

    private func assertBeginScreenSharing(
        _ type: ScreensharingType,
        ownCapabilities: [OwnCapability]
    ) async throws {
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .screenshare, file: file, line: line)
                XCTAssertTrue(track is RTCVideoTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }
        eventExpectation.isInverted = !ownCapabilities.contains(.screenshare)

        try await subject.beginScreenSharing(
            of: type,
            ownCapabilities: ownCapabilities
        )

        await fulfillment(
            of: [eventExpectation],
            timeout: ownCapabilities.contains(.screenshare) ? defaultTimeout : 1
        )
        if ownCapabilities.contains(.screenshare) {
            XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        }
    }
}
