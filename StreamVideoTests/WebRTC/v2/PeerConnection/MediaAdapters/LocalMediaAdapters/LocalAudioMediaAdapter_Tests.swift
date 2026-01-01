//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import StreamWebRTC
@preconcurrency import XCTest

final class LocalAudioMediaAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private var mockAudioRecorder: MockStreamCallAudioRecorder! = .init()
    private var disposableBag: DisposableBag! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var publishOptions: [PublishOptions.AudioPublishOptions] = []
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
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
        mockStreamVideo = nil
        mockAudioRecorder = nil
        spySubject = nil
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

    func test_setUp_hasAudioCapabilityAudioIsOff_doesNotAddTrack() async throws {
        try await assertTrackEvent(
            isInverted: true
        ) { subject in
            try await subject.setUp(
                with: .init(audioOn: false),
                ownCapabilities: [.sendAudio]
            )
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
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .audio)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrue_trackWasAdded() async throws {
        try await subject.setUp(
            with: .init(audioOn: false),
            ownCapabilities: [.sendAudio]
        )

        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.didUpdateCallSettings(.init(audioOn: true))
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .audio)
            XCTAssertTrue(track is RTCAudioTrack)
        }
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalse_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdateCallSettings(.init(audioOn: false))
        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .audio)
        XCTAssertTrue(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalseAndThenCallSettingsTrue_trackWasNotAddedAgain() async throws {
        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.setUp(
                with: .init(audioOn: true),
                ownCapabilities: [.sendAudio]
            )
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .audio)
            XCTAssertTrue(track is RTCAudioTrack)
        }
        try await subject.didUpdateCallSettings(.init(audioOn: false))
        await fulfillment { self.subject.primaryTrack.isEnabled == false }

        try await assertTrackEvent(isInverted: true) {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.didUpdateCallSettings(.init(audioOn: true))
        }

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
    }

    // MARK: - didUpdatePublishOptions

    func test_didUpdatePublishOptions_primaryTrackIsNotEnabled_nothingHappens() async throws {
        subject.primaryTrack.isEnabled = false
        try await subject.didUpdatePublishOptions(
            .dummy(
                audio: [.dummy(codec: .opus)]
            )
        )

        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 0)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiveExists_noTransceiverWasAdded() async throws {
        publishOptions = [.dummy(codec: .opus)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .audio, audioOptions: publishOption)
            )
        }
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(audio: publishOptions))

        await wait(for: 2)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiverDoesNotExist_transceiverWasAdded(
    ) async throws {
        publishOptions = [.dummy(codec: .opus)]
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(audio: publishOptions))

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_newTransceiverAddedForNewPublishOption() async throws {
        publishOptions = [.dummy(id: 0, codec: .opus)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .audio, audioOptions: publishOption)
            )
        }
        // We call publish to simulate the publishing flow that will create
        // all necessary transceveivers on the PeerConnection
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        try await subject.didUpdatePublishOptions(
            .dummy(
                audio: [.dummy(id: 1, codec: .red)]
            )
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_existingTransceiverNotInPublishOptionsGetsTrackNullified() async throws {
        publishOptions = [.dummy(codec: .opus)]
        let opusTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .opus))
        let redTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .red))
        mockPeerConnection.stub(for: .addTransceiver, with: opusTransceiver)
        subject.publish()
        await fulfillment { opusTransceiver.sender.track != nil }
        mockPeerConnection.stub(for: .addTransceiver, with: redTransceiver)

        try await subject.didUpdatePublishOptions(
            .dummy(
                audio: [.dummy(codec: .red)]
            )
        )

        await fulfillment { opusTransceiver.sender.track == nil }
    }

    // MARK: - trackInfo

    func test_trackInfo_noPublishedTransceivers_returnsEmptyArray() {
        XCTAssertTrue(subject.trackInfo(for: .allAvailable).isEmpty)
    }

    func test_trackInfo_allAvailable_twoPublishedTransceivers_returnsCorrectArray() async throws {
        // Note: Any call to the addTransceiver method will return the same
        // object reference. However, for this test case's needs the mock
        // below is sufficient.
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: StubVariantResultProvider {
                try! self.makeTransceiver(of: .audio, audioOptions: .dummy(codec: $0 == 0 ? .opus : .red))
            }
        )
        publishOptions = [
            .dummy(codec: .opus),
            .dummy(codec: .red)
        ]
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }

        let trackInfo = subject.trackInfo(for: .allAvailable)
        let opusTrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "opus" })
        let redTrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "red" })

        XCTAssertEqual(trackInfo.count, 2)
        XCTAssertEqual(opusTrackInfo.trackType, .audio)
        XCTAssertFalse(opusTrackInfo.muted)
        XCTAssertEqual(opusTrackInfo.codec.name, "opus")
        XCTAssertEqual(redTrackInfo.trackType, .audio)
        XCTAssertFalse(redTrackInfo.muted)
        XCTAssertEqual(redTrackInfo.codec.name, "red")
    }

    func test_trackInfo_allAvailable_onePublishedAndOneUnpublishedTransceivers_returnsCorrectArray() async throws {
        let opusTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .opus))
        let redTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .red))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? opusTransceiver : redTransceiver
        })
        publishOptions = [.dummy(codec: .opus)]
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        let opusTrackId = try XCTUnwrap(opusTransceiver.sender.track?.trackId)

        try await subject.didUpdatePublishOptions(
            .dummy(audio: [.dummy(codec: .red)])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .allAvailable)
        XCTAssertEqual(trackInfo.count, 2)
        let opusTrackInfo = try XCTUnwrap(trackInfo.first(where: { $0.trackID == opusTrackId }))
        let redTrackInfo = try XCTUnwrap(trackInfo.first(where: { $0.trackID == redTransceiver.sender.track?.trackId }))
        XCTAssertEqual(opusTrackInfo.trackType, .audio)
        XCTAssertEqual(redTrackInfo.trackType, .audio)
    }

    func test_trackInfo_lastPublishOpions_onePublishedAndOneUnpublishedTransceivers_returnsCorrectArray() async throws {
        let opusTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .opus))
        let redTransceiver = try makeTransceiver(of: .audio, audioOptions: .dummy(codec: .red))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? opusTransceiver : redTransceiver
        })
        publishOptions = [.dummy(codec: .opus)]
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        try await subject.didUpdatePublishOptions(
            .dummy(audio: [.dummy(codec: .red)])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .lastPublishOptions)
        XCTAssertEqual(trackInfo.count, 1)
        XCTAssertEqual(trackInfo.first?.trackType, .audio)
        XCTAssertEqual(trackInfo.first?.trackID, redTransceiver.sender.track?.trackId)
        XCTAssertEqual(trackInfo.first?.codec.name, "red")
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
        XCTAssertFalse(mockAudioRecorder.isRecording)
    }

    // MARK: - unpublish

    func test_unpublish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        publishOptions = [.dummy(codec: .opus)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .audio, audioOptions: publishOption)
            )
        }
        try await subject.setUp(
            with: .init(audioOn: true),
            ownCapabilities: [.sendAudio]
        )
        subject.publish()
        await fulfilmentInMainActor { self.subject.primaryTrack.isEnabled == true }

        subject.unpublish()

        await fulfilmentInMainActor { self.subject.primaryTrack.isEnabled == false }
        let transceiver = try XCTUnwrap(
            mockPeerConnection.stubbedFunction[.addTransceiver] as? RTCRtpTransceiver
        )
        XCTAssertNotEqual(transceiver.sender.track?.trackId, subject.primaryTrack.trackId)
        XCTAssertEqual(transceiver.sender.track?.kind, subject.primaryTrack.kind)
        XCTAssertFalse(transceiver.sender.track?.isEnabled ?? true)
        XCTAssertFalse(mockAudioRecorder.isRecording)
    }

    // MARK: - Private

    private func assertTrackEvent(
        isInverted: Bool = false,
        filter: @escaping @Sendable (TrackEvent) -> (String, TrackType, RTCMediaStreamTrack)? = { _ in nil },
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
                    timeout: isInverted ? 1 : defaultTimeout
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
