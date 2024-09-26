//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class LocalAudioMediaAdapter_Tests: XCTestCase {

    private let mockActiveCallProvider: MockActiveCallProvider! = .init()
    private let mockAudioRecorder: MockStreamCallAudioRecorder! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var audioSession: AudioSession! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var subject: LocalAudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        audioSession: audioSession,
        subject: spySubject
    )

    private var temporaryPeerConnection: RTCPeerConnection?

    override func tearDown() {
        subject = nil
        spySubject = nil
        audioSession = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        temporaryPeerConnection = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_hasAudioCapabilityAndAudioOn_noLocalTrack_createsAndAddsTrackAndTransceiver() async throws {
        // Given
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .audio, file: file, line: line)
                XCTAssertTrue(track is RTCAudioTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }

        // When
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)
        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertNotNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_hasAudioCapabilityAudioIsOff_noLocalTrack_createsTrackWithoutTransceiver() async throws {
        // Given
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .audio, file: file, line: line)
                XCTAssertTrue(track is RTCAudioTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }

        // When
        try await subject.setUp(
            with: .init(audioOn: false),
            ownCapabilities: [.sendAudio]
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)
        XCTAssertNotNil(subject.localTrack)
        XCTAssertFalse(subject.localTrack?.isEnabled ?? true)
        XCTAssertNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_doesNotHavesAudioCapability_noLocalTrack_doesNotCreateTrack() async throws {
        // Given
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .audio, file: file, line: line)
                XCTAssertTrue(track is RTCAudioTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }
        eventExpectation.isInverted = true

        // When
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: []
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: 1) // We set it to one to avoid delaying tests.
        XCTAssertNil(subject.localTrack)
        XCTAssertNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_isEnabledSameAsCallSettings_noOperation() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        XCTAssertNil(mockSFUStack.service.updateSubscriptionsWasCalledWithRequest)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrue_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        try await subject.didUpdateCallSettings(.init(audioOn: true))

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .audio)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalse_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.localTrack?.isEnabled = true

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .audio)
        XCTAssertTrue(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrue_callSettingsUpdatedAudioSession() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        try await subject.didUpdateCallSettings(.init(audioOn: true))

        let isActive = await audioSession.isAudioEnabled
        XCTAssertTrue(isActive)
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalse_callSettingsUpdatedAudioSession() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.localTrack?.isEnabled = true

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        let isActive = await audioSession.isActive
        XCTAssertFalse(isActive)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrue_startsRecording() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        try await subject.didUpdateCallSettings(.init(audioOn: true))

        await fulfillment { [mockAudioRecorder] in
            mockAudioRecorder?.stubbedFunctionInput[.startRecording]?.isEmpty == true
        }
    }

    // MARK: - publish

    func test_publish_disabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .audio)
        )
        try await subject.setUp(
            with: .init(audioOn: false),
            ownCapabilities: [.sendAudio]
        )

        subject.publish()

        await fulfillment { self.subject.localTrack?.isEnabled == true }
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    func test_publish_disabledLocalTrack_transceiverHasBeenCreated_enablesAndAddsTrack() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .audio)
        )
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )

        subject.publish()

        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    // MARK: - unpublish

    func test_publish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .audio)
        )
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.localTrack?.isEnabled = true

        subject.unpublish()

        await fulfillment { self.subject.localTrack?.isEnabled == false }
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
}
