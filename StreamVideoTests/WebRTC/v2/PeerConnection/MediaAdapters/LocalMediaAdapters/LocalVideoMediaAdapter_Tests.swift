//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class LocalVideoMediaAdapter_Tests: XCTestCase {
    private let mockActiveCallProvider: MockActiveCallProvider! = .init()
    private let mockAudioRecorder: MockStreamCallAudioRecorder! = .init()
    private lazy var sessionId: String! = .unique
    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = MockSFUStack()
    private lazy var mockCapturerFactory: MockVideoCapturerFactory! = .init()
    private lazy var spySubject: PassthroughSubject<TrackEvent, Never>! = .init()
    private lazy var subject: LocalVideoMediaAdapter! = .init(
        sessionID: sessionId,
        peerConnection: mockPeerConnection,
        peerConnectionFactory: peerConnectionFactory,
        sfuAdapter: mockSFUStack.adapter,
        videoOptions: .init(),
        videoConfig: .dummy(),
        publishOptions: [.dummy(codec: .h264)],
        subject: spySubject,
        capturerFactory: mockCapturerFactory,
        videoCaptureSessionProvider: .init()
    )
    private var temporaryPeerConnection: RTCPeerConnection?
    private var disposableBag: DisposableBag! = .init()

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        InjectedValues[\.simulatorStreamFile] = .init(fileURLWithPath: .unique)

        RTCSetMinDebugLogLevel(.verbose)
        RTCEnableMetrics()
    }

    override func tearDown() {
        subject = nil
        spySubject = nil
        mockCapturerFactory = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        temporaryPeerConnection = nil
        disposableBag = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_hasVideoCapabilityAndVideoOn_noLocalTrack_createsAndAddsTrackAndTransceiver() async throws {
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

        XCTAssertFalse(subject.primaryTrack.isEnabled ?? true)
        XCTAssertNotNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_hasVideoCapabilityVideoOff_noLocalTrack_createsTrackWithoutTransceiver() async throws {
        try await assertTrackEvent {
            switch $0 {
            case let .added(id, trackType, track):
                return (id, trackType, track)
            default:
                return nil
            }
        } operation: { subject in
            try await subject.setUp(
                with: .init(videoOn: false),
                ownCapabilities: [.sendVideo]
            )
        } validation: { [sessionId] id, trackType, track in
            XCTAssertEqual(id, sessionId)
            XCTAssertEqual(trackType, .video)
            XCTAssertTrue(track is RTCVideoTrack)
        }

        XCTAssertNotNil(subject.primaryTrack)
        XCTAssertFalse(subject.primaryTrack.isEnabled ?? true)
        XCTAssertNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_doesNotHaveVideoCapability_noLocalTrack_doesNotCreateTrack() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)

        try await assertTrackEvent(isInverted: true, operation: { subject in
            try await subject.setUp(
                with: .init(videoOn: true),
                ownCapabilities: []
            )
        })

        XCTAssertNil(subject.primaryTrack)
        XCTAssertNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
        XCTAssertEqual(mockCapturer.stubbedFunctionInput[.capturingDevice]?.count, 0)
        XCTAssertEqual(mockCapturer.stubbedFunctionInput[.startCapture]?.count, 0)
    }

    func test_setUp_hasVideoCapabilityAndVideoOn_noLocalTrack_capturerWasCorrectlyConfigured() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)

        // When
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        // Then
        XCTAssertEqual(mockCapturer.stubbedFunctionInput[.capturingDevice]?.count, 1)
        XCTAssertEqual(mockCapturer.stubbedFunctionInput[.startCapture]?.count, 1)
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

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .video)
        XCTAssertFalse(request.muteStates[0].muted)
    }

    func test_didUpdateCallSettings_isEnabledTrueCallSettingsFalse_SFUWasCalled() async throws {
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        subject.primaryTrack.isEnabled = true

        try await subject.didUpdateCallSettings(.init(videoOn: false))

        let request = try XCTUnwrap(mockSFUStack.service.updateMuteStatesWasCalledWithRequest)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertEqual(request.muteStates.count, 1)
        XCTAssertEqual(request.muteStates[0].trackType, .video)
        XCTAssertTrue(request.muteStates[0].muted)
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
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(
                of: .video,
                videoOptions: .dummy(codec: .h264)
            )
        )
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        subject.publish()

        await fulfillment { self.subject.primaryTrack.isEnabled == true }
        XCTAssertTrue(subject.primaryTrack.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.timesCalled(.addTransceiver), 1)
        XCTAssertEqual(
            (mockPeerConnection.stubbedFunction[.addTransceiver] as? RTCRtpTransceiver)?.sender.parameters.encodings.flatMap(\.rid),
            ["q", "h", "f"]
        )
    }

    // MARK: - unpublish

    func test_publish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(
                of: .video,
                videoOptions: .dummy(
                    codec: .h264
                )
            )
        )
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        subject.primaryTrack.isEnabled = true

        subject.unpublish()

        await fulfillment { self.subject.primaryTrack.isEnabled == false }
    }

    // MARK: - didUpdateCameraPosition(_:)

    func test_didUpdateCameraPosition_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )

        try await subject.didUpdateCameraPosition(.front)

        XCTAssertEqual(
            mockCapturer.recordedInputPayload(AVCaptureDevice.Position.self, for: .setCameraPosition)?.last,
            .front
        )
    }

    // MARK: - setVideoFilter(_:)

    func test_setVideoFilter_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        subject.setVideoFilter(
            .init(id: "test", name: "test", filter: { _ in fatalError() })
        )

        XCTAssertEqual(
            mockCapturer.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.last?.id,
            "test"
        )
    }

    // MARK: - zoom(by:)

    func test_zoom_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )

        try await subject.zoom(by: 10)

        XCTAssertEqual(
            mockCapturer.recordedInputPayload(CGFloat.self, for: .zoom)?.last,
            10
        )
    }

    // MARK: - focus(at:)

    func test_focus_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )

        try await subject.focus(at: .init(x: 10, y: 30))

        XCTAssertEqual(
            mockCapturer.recordedInputPayload(CGPoint.self, for: .focus)?.last,
            .init(x: 10, y: 30)
        )
    }

    // MARK: - addVideoOutput(_:)

    func test_addVideoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        let videoOutput = AVCaptureVideoDataOutput()

        try await subject.addVideoOutput(videoOutput)

        XCTAssertTrue(
            mockCapturer.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .addVideoOutput)?.last === videoOutput
        )
    }

    // MARK: - removeVideoOutput(_:)

    func test_removeVideoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        let videoOutput = AVCaptureVideoDataOutput()

        try await subject.removeVideoOutput(videoOutput)

        XCTAssertTrue(
            mockCapturer.recordedInputPayload(AVCaptureVideoDataOutput.self, for: .removeVideoOutput)?.last === videoOutput
        )
    }

    // MARK: - addCapturePhotoOutput(_:)

    func test_addCapturePhotoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        let videoOutput = AVCapturePhotoOutput()

        try await subject.addCapturePhotoOutput(videoOutput)

        XCTAssertTrue(
            mockCapturer.recordedInputPayload(AVCapturePhotoOutput.self, for: .addCapturePhotoOutput)?.last === videoOutput
        )
    }

    // MARK: - removeCapturePhotoOutput(_:)

    func test_removeCapturePhotoOutput_videoCapturerWasCalledWithExpectedInput() async throws {
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        let videoOutput = AVCapturePhotoOutput()

        try await subject.removeCapturePhotoOutput(videoOutput)

        XCTAssertTrue(
            mockCapturer.recordedInputPayload(AVCapturePhotoOutput.self, for: .removeCapturePhotoOutput)?.last === videoOutput
        )
    }

    // MARK: - changePublishQuality(_:)

    func test_changePublishQuality_transceiverWasUpdatedCorrectly() async throws {
        fatalError()
//        let transceiver = try makeTransceiver(of: .video, layers: VideoLayer.default)
//        mockPeerConnection.stub(for: .addTransceiver, with: transceiver)
//        try await subject.setUp(
//            with: .init(videoOn: true, cameraPosition: .back),
//            ownCapabilities: [.sendVideo]
//        )
//        subject.publish()
//
//        let scalabilityMode = "L2T1"
//        var layer = Stream_Video_Sfu_Event_VideoLayerSetting.dummy(
//            name: "q",
//            isActive: true,
//            scalabilityMode: scalabilityMode,
//            maxFramerate: 30,
//            maxBitrate: 120,
//            scaleResolutionDownBy: 2
//        )
//
//        subject.changePublishQuality(
//            with: [
//                layer
//            ]
//        )
//
//        let activeEncoding = try XCTUnwrap(
//            transceiver
//                .sender
//                .parameters
//                .encodings
//                .filter { $0.isActive }
//                .first
//        )
//
//        XCTAssertEqual(activeEncoding.rid, "q")
//        XCTAssertTrue(activeEncoding.isActive)
//        XCTAssertEqual(activeEncoding.maxBitrateBps, 120)
//        XCTAssertEqual(activeEncoding.maxFramerate, 30)
//        XCTAssertEqual(activeEncoding.scaleResolutionDownBy, 2)
//        XCTAssertEqual(activeEncoding.scalabilityMode, scalabilityMode)
    }

    // MARK: - Private

    private func assertTrackEvent(
        isInverted: Bool = false,
        filter: @escaping (TrackEvent) -> (String, TrackType, RTCMediaStreamTrack)? = { _ in nil },
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
                await self?.fulfillment(of: [eventReceivedExpectation], timeout: defaultTimeout)
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
