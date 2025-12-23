//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class LocalScreenShareMediaAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var disposableBag: DisposableBag! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var mockCapturerFactory: MockVideoCapturerFactory! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var publishOptions: [PublishOptions.VideoPublishOptions] = [.dummy(codec: .h264)]
    private lazy var screenShareSessionProvider: ScreenShareSessionProvider! = .init()
    private lazy var mockAudioDeviceModule: MockRTCAudioDeviceModule! = .init()
    private var temporaryPeerConnection: RTCPeerConnection?
    private lazy var subject: LocalScreenShareMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        publishOptions: publishOptions,
        subject: spySubject,
        screenShareSessionProvider: screenShareSessionProvider,
        capturerFactory: mockCapturerFactory,
        audioDeviceModule: .init(mockAudioDeviceModule)
    )

    override func tearDown() {
        subject = nil
        spySubject = nil
        mockCapturerFactory = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        screenShareSessionProvider = nil
        temporaryPeerConnection = nil
        disposableBag = nil
        mockAudioDeviceModule = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_screenShareSessionExists_primaryTrackSourceSameAsActiveSession() {
        let track = peerConnectionFactory.mockVideoTrack(forScreenShare: true)
        screenShareSessionProvider.activeSession = .init(
            localTrack: track,
            screenSharingType: .broadcast,
            capturer: mockCapturerFactory.buildScreenCapturer(
                .broadcast,
                source: track.source,
                audioDeviceModule: .init(mockAudioDeviceModule),
                includeAudio: true
            ),
            includeAudio: true
        )

        XCTAssertTrue(subject.primaryTrack.source === track.source)
    }

    // MARK: - didUpdatePublishOptions

    func test_didUpdatePublishOptions_primaryTrackIsNotEnabled_nothingHappens() async throws {
        subject.primaryTrack.isEnabled = false
        try await subject.didUpdatePublishOptions(
            .dummy(
                screenShare: [.dummy(codec: .av1)]
            )
        )

        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 0)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiveExists_noTransceiverWasAdded() async throws {
        publishOptions = [.dummy(codec: .h264)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .screenshare, videoOptions: publishOption)
            )
        }
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: true
        )
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(screenShare: publishOptions))

        await wait(for: 2)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiverDoesNotExist_transceiverWasAdded(
    ) async throws {
        publishOptions = [.dummy(codec: .h264)]
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: true
        )
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(screenShare: publishOptions))

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_newTransceiverAddedForNewPublishOption() async throws {
        publishOptions = [.dummy(id: 0, codec: .h264)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .screenshare, videoOptions: publishOption)
            )
        }
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: true
        )
        subject.primaryTrack.isEnabled = false
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        try await subject.didUpdatePublishOptions(
            .dummy(
                screenShare: [.dummy(id: 1, codec: .av1)]
            )
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_existingTransceiverNotInPublishOptionsGetsTrackNullified() async throws {
        publishOptions = [.dummy(codec: .h264)]
        let h264Transceiver = try makeTransceiver(of: .screenshare, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .screenshare, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: h264Transceiver)
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: MockStreamVideoCapturer(),
            includeAudio: true
        )
        subject.primaryTrack.isEnabled = false
        subject.publish()
        await fulfillment { h264Transceiver.sender.track != nil }
        mockPeerConnection.stub(for: .addTransceiver, with: av1Transceiver)

        try await subject.didUpdatePublishOptions(
            .dummy(
                screenShare: [.dummy(codec: .av1)]
            )
        )

        await fulfillment { h264Transceiver.sender.track == nil }
    }

    // MARK: - beginScreenSharing(of:ownCapabilities:)

    func test_beginScreenSharing_addTrack() async throws {
        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.beginScreenSharing(
                of: .inApp,
                ownCapabilities: [.screenshare],
                includeAudio: true
            )
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .screenshare)
            XCTAssertTrue(track is RTCVideoTrack)
        }
    }

    func test_beginScreenSharing_withoutCapabilityWithActiveSession_stopsCapturingAndSession() async throws {
        try await assertStopCapturing {
            try await subject.beginScreenSharing(
                of: .inApp,
                ownCapabilities: [],
                includeAudio: true
            )
        }
    }

    func test_beginScreenSharing_withCapabilityNoActiveSession_configuresActiveSessionCorrectly() async throws {
        try await assertActiveSessionConfiguration(.inApp, assertStopCapture: false)
    }

    func test_beginScreenSharing_withCapabilityWithActiveSessionOfDifferentType_configuresActiveSessionCorrectly() async throws {
        try await assertActiveSessionConfiguration(.inApp, assertStopCapture: true)
    }

    func test_beginScreenSharing_withCapabilityWithActiveSessionOfSameType_configuresActiveSessionCorrectly() async throws {
        let screensharingType = ScreensharingType.inApp
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)

        try await subject.beginScreenSharing(
            of: screensharingType,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        try await subject.beginScreenSharing(
            of: screensharingType,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )

        XCTAssertEqual(mockCapturerFactory.timesCalled(.buildScreenCapturer), 1)
        XCTAssertEqual(capturer.timesCalled(.stopCapture), 0)
    }

    func test_beginScreenSharing_startsCapturing() async throws {
        let screensharingType = ScreensharingType.inApp
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)

        try await subject.beginScreenSharing(
            of: screensharingType,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )

        await fulfillment { capturer.timesCalled(.startCapture) == 1 }
    }

    func test_beginScreenSharing_withCapability_updateMuteStateOnSFU() async throws {
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .screenShare)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_beginScreenSharing_withCapability_startsCapturing() async throws {
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)

        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )

        await fulfillment { capturer.timesCalled(.startCapture) == 1 }
    }

    // MARK: - stopScreenSharing

    func test_stopScreenSharing_updateMuteStateOnSFU() async throws {
        try await subject.stopScreenSharing()

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .screenShare)
        XCTAssertTrue(request.muteStates[0].muted)
    }

    func test_stopScreenSharing_stopsCapturing() async throws {
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { capturer.timesCalled(.startCapture) == 1 }

        try await subject.stopScreenSharing()

        await fulfillment { capturer.timesCalled(.stopCapture) >= 1 }
    }

    // MARK: - trackInfo

    func test_trackInfo_noPublishedTransceivers_returnsEmptyArray() {
        XCTAssertTrue(subject.trackInfo(for: .allAvailable).isEmpty)
    }

    func test_trackInfo_allAvailable_twoPublishedTransceivers_returnsCorrectArray() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: StubVariantResultProvider {
                try! self.makeTransceiver(of: .video, videoOptions: .dummy(codec: $0 == 0 ? .h264 : .av1))
            }
        )
        publishOptions = [
            .dummy(codec: .h264, fmtp: "a"),
            .dummy(codec: .av1, fmtp: "b")
        ]
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }

        let trackInfo = subject.trackInfo(for: .allAvailable)
        let h264TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "h264" })
        let av1TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "av1" })

        XCTAssertEqual(trackInfo.count, 2)
        XCTAssertEqual(h264TrackInfo.trackType, .screenShare)
        XCTAssertFalse(h264TrackInfo.muted)
        XCTAssertEqual(h264TrackInfo.codec.name, "h264")
        XCTAssertEqual(h264TrackInfo.codec.fmtp, "a")
        XCTAssertEqual(av1TrackInfo.trackType, .screenShare)
        XCTAssertFalse(av1TrackInfo.muted)
        XCTAssertEqual(av1TrackInfo.codec.name, "av1")
        XCTAssertEqual(av1TrackInfo.codec.fmtp, "b")
        XCTAssertNotEqual(h264TrackInfo.trackID, av1TrackInfo.trackID)
    }

    func test_trackInfo_allAvailable_onePublishedAndOneUnpublishedTransceivers_returnsCorrectArray() async throws {
        let h264Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? h264Transceiver : av1Transceiver
        })
        publishOptions = [.dummy(codec: .h264, fmtp: "a")]
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        try await subject.didUpdatePublishOptions(
            .dummy(screenShare: [.dummy(codec: .av1, fmtp: "b")])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .allAvailable)
        let h264TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "h264" })
        let av1TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "av1" })

        XCTAssertEqual(trackInfo.count, 2)
        XCTAssertEqual(h264TrackInfo.trackType, .screenShare)
        XCTAssertTrue(h264TrackInfo.muted)
        XCTAssertEqual(h264TrackInfo.codec.name, "h264")
        XCTAssertEqual(h264TrackInfo.codec.fmtp, "a")
        XCTAssertEqual(av1TrackInfo.trackType, .screenShare)
        XCTAssertFalse(av1TrackInfo.muted)
        XCTAssertEqual(av1TrackInfo.codec.name, "av1")
        XCTAssertEqual(av1TrackInfo.codec.fmtp, "b")
        XCTAssertNotEqual(h264TrackInfo.trackID, av1TrackInfo.trackID)
    }

    func test_trackInfo_lastPublishOpions_onePublishedAndOneUnpublishedTransceivers_returnsCorrectArray() async throws {
        let h264Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? h264Transceiver : av1Transceiver
        })
        publishOptions = [.dummy(codec: .h264)]
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        try await subject.didUpdatePublishOptions(
            .dummy(screenShare: [.dummy(codec: .av1, fmtp: "b")])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .lastPublishOptions)
        XCTAssertEqual(trackInfo.count, 1)
        XCTAssertEqual(trackInfo.first?.trackType, .screenShare)
        XCTAssertFalse(trackInfo.first?.muted ?? true)
        XCTAssertEqual(trackInfo.first?.codec.name, "av1")
        XCTAssertEqual(trackInfo.first?.codec.fmtp, "b")
    }

    // MARK: - publish

    func test_publish_disabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(
                of: .video,
                videoOptions: .dummy(codec: .h264)
            )
        )
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: capturer,
            includeAudio: true
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    func test_publish_disabledLocalTrack_transceiverHasBeenCreated_enablesAndAddsTrack() async throws {
        let mockTransceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: mockTransceiver)
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        screenShareSessionProvider.activeSession = .init(
            localTrack: subject.primaryTrack,
            screenSharingType: .inApp,
            capturer: capturer,
            includeAudio: true
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertTrue(subject.primaryTrack.isEnabled)
        XCTAssertTrue(mockTransceiver.sender.track?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
    }

    // MARK: - unpublish

    func test_unpublish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        let mockTransceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: mockTransceiver)
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { capturer.timesCalled(.startCapture) == 1 }
        XCTAssertTrue(subject.primaryTrack.isEnabled)

        subject.unpublish()

        await fulfillment {
            self.subject.primaryTrack.isEnabled == false && mockTransceiver.sender.track?.isEnabled == false
        }
    }

    func test_unpublish_enabledLocalTrack_stopsCapturingOnActiveSession() async throws {
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        )
        try await subject.beginScreenSharing(
            of: .inApp,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )
        await fulfillment { capturer.timesCalled(.startCapture) == 1 }

        subject.unpublish()

        await fulfillment { capturer.timesCalled(.stopCapture) >= 1 }
    }

    // MARK: - Private

    private func makeTransceiver(
        of type: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        videoOptions: PublishOptions.VideoPublishOptions = .dummy(codec: .h264)
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
                videoOptions: videoOptions
            )
        )!
    }

    private func assertTrackEvent(
        isInverted: Bool = false,
        filter: @escaping @Sendable (TrackEvent) -> (String, TrackType, RTCMediaStreamTrack)? = { _ in nil },
        operation: @Sendable @escaping (LocalScreenShareMediaAdapter) async throws -> Void,
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
                await self?.fulfillment(of: [eventReceivedExpectation], timeout: defaultTimeout)
            }

            try await group.waitForAll()
        }
    }

    private func assertBeginScreenSharing(
        _ type: ScreensharingType
    ) async throws {
        //        if !ownCapabilities.contains(.screenshare) {
        //            XCTAssert
        //        }
    }

    private func assertStopCapturing(
        _ operation: () async throws -> Void
    ) async throws {
        let capturer = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturer)
        screenShareSessionProvider.activeSession = .init(
            localTrack: peerConnectionFactory.mockVideoTrack(forScreenShare: true),
            screenSharingType: .inApp,
            capturer: capturer,
            includeAudio: true
        )

        try await operation()

        await fulfillment { capturer.timesCalled(.stopCapture) >= 1 }
        XCTAssertNil(screenShareSessionProvider.activeSession)
    }

    private func assertActiveSessionConfiguration(
        _ screensharingType: ScreensharingType,
        assertStopCapture: Bool,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let capturerA = MockStreamVideoCapturer()
        let capturerB = MockStreamVideoCapturer()
        mockCapturerFactory.stub(for: .buildScreenCapturer, with: capturerB)

        if assertStopCapture {
            screenShareSessionProvider.activeSession = .init(
                localTrack: subject.primaryTrack,
                screenSharingType: screensharingType == .inApp ? .broadcast : .inApp,
                capturer: capturerA,
                includeAudio: true
            )
        }

        try await subject.beginScreenSharing(
            of: screensharingType,
            ownCapabilities: [.screenshare],
            includeAudio: true
        )

        await fulfillment(file: file, line: line) {
            self.screenShareSessionProvider.activeSession != nil
        }

        XCTAssertEqual(mockCapturerFactory.timesCalled(.buildScreenCapturer), 1)
        let input = try XCTUnwrap(
            mockCapturerFactory
                .recordedInputPayload(
                    (ScreensharingType, RTCVideoSource, AudioDeviceModule, Bool).self,
                    for: .buildScreenCapturer
                )?.first
        )
        XCTAssertEqual(
            input.0,
            screensharingType,
            file: file,
            line: line
        )
        XCTAssertTrue(
            input.1 === subject.primaryTrack.source,
            file: file,
            line: line
        )
        XCTAssertEqual(
            screenShareSessionProvider.activeSession?.localTrack.trackId,
            subject.primaryTrack.trackId,
            file: file,
            line: line
        )
        XCTAssertEqual(
            screenShareSessionProvider.activeSession?.screenSharingType,
            screensharingType,
            file: file,
            line: line
        )
        XCTAssertTrue(
            screenShareSessionProvider.activeSession?.capturer === capturerB,
            file: file,
            line: line
        )
        if assertStopCapture {
            XCTAssertTrue(
                capturerA.timesCalled(.stopCapture) > 1,
                file: file,
                line: line
            )
        }
    }
}

#if compiler(>=6.0)
extension RTCRtpTransceiver: @retroactive @unchecked Sendable {}
#else
extension RTCRtpTransceiver: @unchecked Sendable {}
#endif
