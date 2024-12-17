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
    private var disposableBag: DisposableBag! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var publishOptions: [PublishOptions.AudioPublishOptions] = []
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var audioSession: MockAudioSession! = .init()
    private lazy var audioSessionAdapter: StreamAudioSessionAdapter! = .init(audioSession)
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var subject: LocalAudioMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        publishOptions: publishOptions,
        subject: spySubject
    )

    private var temporaryPeerConnection: RTCPeerConnection?

    override func tearDown() {
        subject = nil
        spySubject = nil
        audioSession = nil
        audioSessionAdapter = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        temporaryPeerConnection = nil
        disposableBag = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_hasAudioCapabilityAndAudioOn_addsTrack() async throws {
        try await assertTrackEvent(
            filter: {
                switch $0 {
                case let .added(id, trackType, track):
                    return (id, trackType, track)
                default:
                    return nil
                }
            },
            operation: { subject in
                try await subject.setUp(
                    with: .init(audioOn: true),
                    ownCapabilities: [.sendAudio]
                )
            }
        ) { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .audio)
            XCTAssertTrue(track is RTCAudioTrack)
        }

        XCTAssertFalse(subject.primaryTrack.isEnabled)
    }

    func test_setUp_hasAudioCapabilityAudioIsOff_addsTrack() async throws {
        try await assertTrackEvent(
            filter: {
                switch $0 {
                case let .added(id, trackType, track):
                    return (id, trackType, track)
                default:
                    return nil
                }
            },
            operation: { subject in
                try await subject.setUp(
                    with: .init(audioOn: false),
                    ownCapabilities: [.sendAudio]
                )
            }
        ) { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .audio)
            XCTAssertTrue(track is RTCAudioTrack)
        }

        XCTAssertNotNil(subject.primaryTrack)
        XCTAssertFalse(subject.primaryTrack.isEnabled)
    }

    func test_setUp_doesNotHaveAudioCapability_doesNotAddTrack() async throws {
        try await assertTrackEvent(
            isInverted: true
        ) { subject in
            try await subject.setUp(
                with: .init(audioOn: true),
                ownCapabilities: []
            )
        }
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
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdateCallSettings(.init(audioOn: false))

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .audio)
        XCTAssertTrue(request.muteStates[0].muted)
    }

    // MARK: - publish

    func test_publish_disabledLocalTrack_withOnePublishOption_enablesAndAddsTrackAndTransceiver() async throws {
        publishOptions = [.dummy(codec: .opus)]

        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .audio, audioOptions: publishOption)
            )
        }

        try await subject.setUp(
            with: .init(audioOn: false),
            ownCapabilities: [.sendAudio]
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
        let addTransceiverPayloadType = (
            trackType: TrackType,
            track: RTCMediaStreamTrack,
            transceiverInit: RTCRtpTransceiverInit
        ).self
        let transceiverCall = try XCTUnwrap(
            mockPeerConnection.recordedInputPayload(addTransceiverPayloadType, for: .addTransceiver)?.first
        )
        XCTAssertNotEqual(transceiverCall.track.trackId, subject.primaryTrack.trackId)
        XCTAssertEqual(transceiverCall.track.kind, subject.primaryTrack.kind)
        XCTAssertEqual(transceiverCall.trackType, .audio)
    }

    // MARK: - unpublish

    func test_publish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .opus))
        )
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.primaryTrack.isEnabled = true

        subject.unpublish()

        await fulfillment { self.subject.primaryTrack.isEnabled == false }
    }

    // MARK: - Private

    private func assertTrackEvent(
        isInverted: Bool = false,
        filter: @escaping (TrackEvent) -> (String, TrackType, RTCMediaStreamTrack)? = { _ in nil },
        operation: @Sendable @escaping (LocalAudioMediaAdapter) async throws -> Void,
        validation: @Sendable @escaping (String, TrackType, RTCMediaStreamTrack) -> Void = { _, _, _ in XCTFail() }
    ) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask { [weak subject] in
                try await Task.sleep(nanoseconds: 250_000_000)
                let subject = try XCTUnwrap(subject)
                try await operation(subject)
            }

            let eventReceivedExpectation = expectation(description: "")
            eventReceivedExpectation.isInverted = isInverted
            group.addTask { [spySubject, disposableBag] in
                let spySubject = try XCTUnwrap(spySubject)
                let disposableBag = try XCTUnwrap(disposableBag)
                spySubject
                    .compactMap { filter($0) }
                    .sink { id, trackType, track in
                        validation(id, trackType, track)
                        eventReceivedExpectation.fulfill()
                    }
                    .store(in: disposableBag)
            }

            group.addTask { [weak self] in
                await self?.fulfillment(
                    of: [eventReceivedExpectation],
                    timeout: defaultTimeout
                )
            }

            try await group.waitForAll()
        }
    }

    private func assertEqualAsync<T: Equatable>(
        _ expression: @autoclosure () async throws -> T,
        _ expected: @autoclosure () async throws -> T,
        file: StaticString = #file,
        line: UInt = #line
    ) async rethrows {
        let value = try await expression()
        let expectedValue = try await expected()
        XCTAssertEqual(value, expectedValue, file: file, line: line)
    }

    private func makeTransceiver(
        of type: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        audioOptions: PublishOptions.AudioPublishOptions
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
                direction: direction,
                streamIds: streamIds,
                audioOptions: audioOptions
            )
        )!
    }
}
