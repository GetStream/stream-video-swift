//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@preconcurrency import StreamWebRTC
@preconcurrency import XCTest

final class LocalVideoMediaAdapter_Tests: XCTestCase, @unchecked Sendable {
    private lazy var sessionId: String! = .unique
    private lazy var publishOptions: [PublishOptions.VideoPublishOptions]! = [.dummy(codec: .h264)]
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = MockSFUStack()
    private lazy var mockCapturerFactory: MockVideoCapturerFactory! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var videoCaptureSessionProvider: VideoCaptureSessionProvider! = .init()
    private lazy var mockVideoCapturer: MockStreamVideoCapturer! = .init()
    private lazy var mockCaptureDeviceProvider: MockCaptureDeviceProvider! = .init()
    private lazy var mockAudioDeviceModule: MockRTCAudioDeviceModule! = .init()
    private lazy var subject: LocalVideoMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        videoOptions: .init(),
        videoConfig: .dummy(),
        publishOptions: publishOptions,
        subject: spySubject,
        capturerFactory: mockCapturerFactory,
        videoCaptureSessionProvider: videoCaptureSessionProvider,
        audioDeviceModule: .init(mockAudioDeviceModule)
    )
    private var temporaryPeerConnection: RTCPeerConnection?
    private var disposableBag: DisposableBag! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        InjectedValues[\.simulatorStreamFile] = .init(fileURLWithPath: .unique)
        InjectedValues[\.captureDeviceProvider] = mockCaptureDeviceProvider
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockVideoCapturer)

        RTCSetMinDebugLogLevel(.verbose)
        RTCEnableMetrics()
    }

    override func tearDown() {
        subject = nil
        publishOptions = nil
        spySubject = nil
        mockCapturerFactory = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        temporaryPeerConnection = nil
        disposableBag = nil
        videoCaptureSessionProvider = nil
        mockVideoCapturer = nil
        mockCaptureDeviceProvider = nil
        mockAudioDeviceModule = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_videoCaptureShareSessionExists_primaryTrackSourceSameAsActiveSession() {
        let track = peerConnectionFactory.mockVideoTrack(forScreenShare: false)
        videoCaptureSessionProvider.activeSession = .init(
            position: .front,
            localTrack: track,
            capturer: mockVideoCapturer
        )

        XCTAssertTrue(subject.primaryTrack.source === track.source)
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_hasVideoCapabilityAndVideoOn_addsTrack() async throws {
        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.setUp(
                with: .init(videoOn: true),
                ownCapabilities: [.sendVideo]
            )
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .video)
            XCTAssertTrue(track is RTCVideoTrack)
        }

        XCTAssertFalse(subject.primaryTrack.isEnabled)
    }

    func test_setUp_hasVideoCapabilityVideoIsOff_doesNotAddTrack() async throws {
        try await assertTrackEvent(
            isInverted: true
        ) { subject in
            try await subject.setUp(
                with: .init(videoOn: false),
                ownCapabilities: [.sendVideo]
            )
        }
    }

    func test_setUp_hasVideoCapabilityCameraPositionIsFrontVideoIsOf_videoCaptureSessionIsNil() async throws {
        try await subject.setUp(
            with: .init(videoOn: false, cameraPosition: .front),
            ownCapabilities: [.sendVideo]
        )

        XCTAssertEqual(mockCapturerFactory.timesCalled(.buildCameraCapturer), 0)
        XCTAssertNil(videoCaptureSessionProvider.activeSession)
    }

    func test_setUp_hasVideoCapabilityCameraPositionIsFrontVideoIsOn_configuresVideoCaptureSessionCorrectly() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .front),
            ownCapabilities: [.sendVideo]
        )

        XCTAssertEqual(mockCapturerFactory.timesCalled(.buildCameraCapturer), 1)
        XCTAssertTrue(videoCaptureSessionProvider.activeSession?.capturer === mockVideoCapturer)
        XCTAssertEqual(videoCaptureSessionProvider.activeSession?.localTrack.trackId, subject.primaryTrack.trackId)
        XCTAssertEqual(videoCaptureSessionProvider.activeSession?.position, .front)
    }

    func test_setUp_hasVideoCapabilityCameraPositionIsBackVideoIsOn_configuresVideoCaptureSessionCorrectly() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )

        XCTAssertEqual(mockCapturerFactory.timesCalled(.buildCameraCapturer), 1)
        XCTAssertTrue(videoCaptureSessionProvider.activeSession?.capturer === mockVideoCapturer)
        XCTAssertEqual(videoCaptureSessionProvider.activeSession?.localTrack.trackId, subject.primaryTrack.trackId)
        XCTAssertEqual(videoCaptureSessionProvider.activeSession?.position, .back)
    }

    func test_setUp_doesNotHaveVideoCapability_doesNotAddTrack() async throws {
        try await assertTrackEvent(
            isInverted: true
        ) { subject in
            try await subject.setUp(
                with: .init(videoOn: true),
                ownCapabilities: []
            )
        }
    }

    func test_setUp_doesNotHaveVideoCapability_stopsCaptureOnActiveSession() async throws {
        videoCaptureSessionProvider.activeSession = .init(
            position: .front,
            localTrack: peerConnectionFactory.mockVideoTrack(forScreenShare: false),
            capturer: mockVideoCapturer
        )

        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: []
        )

        await fulfillment { self.mockVideoCapturer.timesCalled(.stopCapture) > 1 }
        XCTAssertNil(videoCaptureSessionProvider.activeSession)
    }

    // MARK: - didUpdateCallSettings(_:)

    func test_didUpdateCallSettings_isEnabledSameAsCallSettings_noOperation() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        try await subject.didUpdateCallSettings(.init(videoOn: false))

        XCTAssertNil(mockSFUStack.service.updateSubscriptionsWasCalledWithRequest)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrue_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        try await subject.didUpdateCallSettings(.init(videoOn: true))

        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .video)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledFalseCallSettingsTrueTrackNotAdded_trackWasAdded() async throws {
        try await subject.setUp(
            with: .init(videoOn: false),
            ownCapabilities: [.sendVideo]
        )

        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.didUpdateCallSettings(.init(videoOn: true))
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .video)
            XCTAssertTrue(track is RTCVideoTrack)
        }
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalse_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdateCallSettings(.init(videoOn: false))

        await fulfillment { self.mockSFUStack.service.updateMuteStatesWasCalledWithRequest != nil }
        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .video)
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
                with: .init(videoOn: true),
                ownCapabilities: [.sendVideo]
            )
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .video)
            XCTAssertTrue(track is RTCVideoTrack)
        }
        try await subject.didUpdateCallSettings(.init(videoOn: false))
        await fulfillment { self.subject.primaryTrack.isEnabled == false }

        try await assertTrackEvent(isInverted: true) {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.didUpdateCallSettings(.init(videoOn: true))
        }

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
    }

    // MARK: - didUpdatePublishOptions

    func test_didUpdatePublishOptions_primaryTrackIsNotEnabled_nothingHappens() async throws {
        subject.primaryTrack.isEnabled = false
        try await subject.didUpdatePublishOptions(
            .dummy(
                video: [.dummy(codec: .av1)]
            )
        )

        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 0)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiveExists_noTransceiverWasAdded() async throws {
        publishOptions = [.dummy(codec: .h264)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .video, videoOptions: publishOption)
            )
        }
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(video: publishOptions))

        await wait(for: 2)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_currentlyPublishedTransceiverDoesNotExist_transceiverWasAdded(
    ) async throws {
        publishOptions = [.dummy(codec: .h264)]
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdatePublishOptions(.init(video: publishOptions))

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_newTransceiverAddedForNewPublishOption() async throws {
        publishOptions = [.dummy(id: 0, codec: .h264)]
        try publishOptions.forEach { publishOption in
            mockPeerConnection.stub(
                for: .addTransceiver,
                with: try makeTransceiver(of: .video, videoOptions: publishOption)
            )
        }
        // We call publish to simulate the publishing flow that will create
        // all necessary transceveivers on the PeerConnection
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        try await subject.didUpdatePublishOptions(
            .dummy(
                video: [.dummy(id: 1, codec: .av1)]
            )
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
    }

    func test_didUpdatePublishOptions_primaryTrackIsEnabled_existingTransceiverNotInPublishOptionsGetsTrackNullified() async throws {
        publishOptions = [.dummy(codec: .h264)]
        let h264Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: h264Transceiver)
        subject.publish()
        await fulfillment { h264Transceiver.sender.track != nil }
        mockPeerConnection.stub(for: .addTransceiver, with: av1Transceiver)

        try await subject.didUpdatePublishOptions(
            .dummy(
                video: [.dummy(codec: .av1)]
            )
        )

        await fulfillment { h264Transceiver.sender.track == nil }
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
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }

        let trackInfo = subject.trackInfo(for: .allAvailable)
        let h264TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "h264" })
        let av1TrackInfo = try XCTUnwrap(trackInfo.first { $0.codec.name == "av1" })

        XCTAssertEqual(trackInfo.count, 2)
        XCTAssertEqual(h264TrackInfo.trackType, .video)
        XCTAssertFalse(h264TrackInfo.muted)
        XCTAssertEqual(h264TrackInfo.codec.name, "h264")
        XCTAssertEqual(h264TrackInfo.codec.fmtp, "a")
        XCTAssertEqual(av1TrackInfo.trackType, .video)
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
        publishOptions = [.dummy(codec: .h264)]
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        let h264TrackId = try XCTUnwrap(h264Transceiver.sender.track?.trackId)

        try await subject.didUpdatePublishOptions(
            .dummy(video: [.dummy(codec: .av1)])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .allAvailable)
        XCTAssertEqual(trackInfo.count, 2)
        let h264TrackInfo = try XCTUnwrap(trackInfo.first(where: { $0.trackID == h264TrackId }))
        let av1TrackInfo = try XCTUnwrap(trackInfo.first(where: { $0.trackID == av1Transceiver.sender.track?.trackId }))
        XCTAssertEqual(h264TrackInfo.trackType, .video)
        XCTAssertEqual(av1TrackInfo.trackType, .video)
    }

    func test_trackInfo_lastPublishOpions_onePublishedAndOneUnpublishedTransceivers_returnsCorrectArray() async throws {
        let h264Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? h264Transceiver : av1Transceiver
        })
        publishOptions = [.dummy(codec: .h264)]
        subject.publish()
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        try await subject.didUpdatePublishOptions(
            .dummy(video: [.dummy(codec: .av1)])
        )

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }
        let trackInfo = subject.trackInfo(for: .lastPublishOptions)
        XCTAssertEqual(trackInfo.count, 1)
        XCTAssertEqual(trackInfo.first?.trackType, .video)
        XCTAssertEqual(trackInfo.first?.trackID, av1Transceiver.sender.track?.trackId)
        XCTAssertEqual(trackInfo.first?.codec.name, "av1")
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
        try await subject.setUp(
            with: .init(videoOn: false),
            ownCapabilities: [.sendVideo]
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    func test_publish_disabledLocalTrack_transceiverHasBeenCreated_enablesAndAddsTrack() async throws {
        let mockTransceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: mockTransceiver)
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertTrue(subject.primaryTrack.isEnabled)
        XCTAssertTrue(mockTransceiver.sender.track?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
    }

    // MARK: - unpublish

    func test_unpublish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        let mockTransceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: mockTransceiver)
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        await fulfillment { mockTransceiver.sender.track?.isEnabled == true }
        XCTAssertTrue(subject.primaryTrack.isEnabled)

        subject.unpublish()

        await fulfillment {
            self.subject.primaryTrack.isEnabled == false && mockTransceiver.sender.track?.isEnabled == false
        }
    }

    func test_unpublish_enabledLocalTrack_stopsCapturingOnActiveSession() async throws {
        let mockCaptureDevice = MockCaptureDevice()
        mockCaptureDevice.stub(for: \.position, with: .front)
        mockCaptureDeviceProvider.stubbedFunction[.deviceForAVPosition] = mockCaptureDevice
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        )
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        await fulfillment { self.videoCaptureSessionProvider.activeSession?.device != nil }

        subject.unpublish()

        await fulfillment { self.mockVideoCapturer.timesCalled(.stopCapture) == 1 }
    }

    // MARK: - didUpdateCameraPosition(_:)

    func test_didUpdateCameraPosition_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true, cameraPosition: .back))
        await fulfillment { self.videoCaptureSessionProvider.activeSession?.position == .back }

        try await subject.didUpdateCameraPosition(.front)

        await fulfillment { self.videoCaptureSessionProvider.activeSession?.position == .front }
    }

    // MARK: - setVideoFilter(_:)

    func test_setVideoFilter_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))

        subject.setVideoFilter(
            .init(id: "test", name: "test", filter: { _ in fatalError() })
        )

        await fulfillment { self.mockVideoCapturer.timesCalled(.setVideoFilter) == 1 }
        XCTAssertEqual(
            mockVideoCapturer.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first?.id,
            "test"
        )
    }

    // MARK: - zoom(by:)

    func test_zoom_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))

        try await subject.zoom(by: 10)

        XCTAssertEqual(
            mockVideoCapturer.recordedInputPayload(CGFloat.self, for: .zoom)?.last,
            10
        )
    }

    // MARK: - focus(at:)

    func test_focus_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))

        try await subject.focus(at: .init(x: 10, y: 30))

        XCTAssertEqual(
            mockVideoCapturer.recordedInputPayload(CGPoint.self, for: .focus)?.last,
            .init(x: 10, y: 30)
        )
    }

    // MARK: - addVideoOutput(_:)

    func test_addVideoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        let videoOutput = AVCaptureVideoDataOutput()

        try await subject.addVideoOutput(videoOutput)

        XCTAssertTrue(
            mockVideoCapturer.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .addVideoOutput)?.last === videoOutput
        )
    }

    // MARK: - removeVideoOutput(_:)

    func test_removeVideoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        let videoOutput = AVCaptureVideoDataOutput()

        try await subject.removeVideoOutput(videoOutput)

        XCTAssertTrue(
            mockVideoCapturer.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .removeVideoOutput)?.last === videoOutput
        )
    }

    // MARK: - addCapturePhotoOutput(_:)

    func test_addCapturePhotoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        let videoOutput = AVCapturePhotoOutput()

        try await subject.addCapturePhotoOutput(videoOutput)

        XCTAssertTrue(
            mockVideoCapturer.recordedInputPayload(AVCapturePhotoOutput.self, for: .addCapturePhotoOutput)?.last === videoOutput
        )
    }

    // MARK: - removeCapturePhotoOutput(_:)

    func test_removeCapturePhotoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        let videoOutput = AVCapturePhotoOutput()

        try await subject.removeCapturePhotoOutput(videoOutput)

        XCTAssertTrue(
            mockVideoCapturer.recordedInputPayload(AVCapturePhotoOutput.self, for: .removeCapturePhotoOutput)?.last === videoOutput
        )
    }

    // MARK: - changePublishQuality(_:)

    func test_changePublishQuality_forActiveTransceiver_transceiverWasUpdatedCorrectly() async throws {
        let transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: transceiver)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        let scalabilityMode = "L2T1"

        subject.changePublishQuality(
            with: [
                .dummy(
                    codec: .dummy(name: "h264"),
                    layers: [
                        .dummy(
                            name: "q",
                            isActive: true,
                            scalabilityMode: scalabilityMode,
                            maxFramerate: 30,
                            maxBitrate: 120,
                            scaleResolutionDownBy: 2
                        )
                    ],
                    trackType: .video
                )
            ]
        )

        await fulfillment {
            transceiver
                .sender
                .parameters
                .encodings
                .filter { $0.isActive }
                .first?.rid == "q"
        }

        let activeEncoding = try XCTUnwrap(
            transceiver
                .sender
                .parameters
                .encodings
                .filter { $0.isActive }
                .first
        )
        XCTAssertEqual(activeEncoding.rid, "q")
        XCTAssertTrue(activeEncoding.isActive)
        XCTAssertEqual(activeEncoding.maxBitrateBps, 120)
        XCTAssertEqual(activeEncoding.maxFramerate, 30)
        XCTAssertEqual(activeEncoding.scaleResolutionDownBy, 2)
        XCTAssertEqual(activeEncoding.scalabilityMode, scalabilityMode)
    }

    func test_changePublishQuality_forActiveTransceiver_videoCapturerWasCalledWithCorrectDimensions() async throws {
        let transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        mockPeerConnection.stub(for: .addTransceiver, with: transceiver)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }

        let scalabilityMode = "L2T1"

        subject.changePublishQuality(
            with: [
                .dummy(
                    codec: .dummy(name: "h264"),
                    layers: [
                        .dummy(
                            name: "q",
                            isActive: true,
                            scalabilityMode: scalabilityMode,
                            maxFramerate: 30,
                            maxBitrate: 120,
                            scaleResolutionDownBy: 2
                        )
                    ],
                    trackType: .video
                )
            ]
        )

        await fulfillment {
            self.mockVideoCapturer.timesCalled(.updateCaptureQuality) == 1
        }
    }

    func test_changePublishQuality_forInactiveTransceiver_transceiverWasUpdatedCorrectly() async throws {
        let transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .h264))
        let av1Transceiver = try makeTransceiver(of: .video, videoOptions: .dummy(codec: .av1))
        mockPeerConnection.stub(for: .addTransceiver, with: StubVariantResultProvider {
            $0 == 1 ? transceiver : av1Transceiver
        })
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        try await subject.didUpdateCallSettings(.init(videoOn: true))
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        try await subject.didUpdatePublishOptions(.dummy(video: [.dummy(codec: .av1)]))
        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 2 }

        let scalabilityMode = "L2T4"

        subject.changePublishQuality(
            with: [
                .dummy(
                    codec: .dummy(name: "av1"),
                    layers: [
                        .dummy(
                            name: "q",
                            isActive: true,
                            scalabilityMode: scalabilityMode,
                            maxFramerate: 30,
                            maxBitrate: 120,
                            scaleResolutionDownBy: 2
                        )
                    ],
                    trackType: .video
                )
            ]
        )

        await wait(for: 1)
        XCTAssertTrue(
            transceiver
                .sender
                .parameters
                .encodings
                .filter { $0.scalabilityMode == scalabilityMode }
                .isEmpty
        )
    }

    // MARK: - Private

    private func assertTrackEvent(
        isInverted: Bool = false,
        filter: @escaping @Sendable (TrackEvent) -> (String, TrackType, RTCMediaStreamTrack)? = { _ in nil },
        operation: @Sendable @escaping (LocalVideoMediaAdapter) async throws -> Void,
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
                await self?.fulfillment(of: [eventReceivedExpectation], timeout: isInverted ? 1 : defaultTimeout)
            }

            try await group.waitForAll()
        }
    }

    private func makeTransceiver(
        of type: TrackType,
        direction: RTCRtpTransceiverDirection = .sendOnly,
        streamIds: [String] = [.unique],
        videoOptions: PublishOptions.VideoPublishOptions
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
}
