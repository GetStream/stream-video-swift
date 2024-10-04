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
        subject: spySubject,
        capturerFactory: mockCapturerFactory,
        videoCaptureSessionProvider: .init()
    )
    private var temporaryPeerConnection: RTCPeerConnection?

    // MARK: - Lifecycle

    override func setUp() {
        super.setUp()
        InjectedValues[\.simulatorStreamFile] = .init(fileURLWithPath: .unique)
    }

    override func tearDown() {
        subject = nil
        spySubject = nil
        mockCapturerFactory = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        peerConnectionFactory = nil
        temporaryPeerConnection = nil
        super.tearDown()
    }

    // MARK: - setUp(with:ownCapabilities:)

    func test_setUp_hasVideoCapabilityAndVideoOn_noLocalTrack_createsAndAddsTrackAndTransceiver() async throws {
        // Given
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .video, file: file, line: line)
                XCTAssertTrue(track is RTCVideoTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }

        // When
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)
        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertNotNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_hasVideoCapabilityVideoOff_noLocalTrack_createsTrackWithoutTransceiver() async throws {
        // Given
        let eventExpectation = assertAsyncOperation { [spySubject] in
            try await spySubject!.nextValue(timeout: defaultTimeout)
        } validationHandler: { [sessionId] event, expectation, file, line in
            switch event {
            case let .added(id, trackType, track):
                XCTAssertEqual(id, sessionId, file: file, line: line)
                XCTAssertEqual(trackType, .video, file: file, line: line)
                XCTAssertTrue(track is RTCVideoTrack, file: file, line: line)
                expectation.fulfill()
            case .removed:
                XCTFail()
            }
        }

        // When
        try await subject.setUp(
            with: .init(videoOn: false),
            ownCapabilities: [.sendVideo]
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: defaultTimeout)
        XCTAssertNotNil(subject.localTrack)
        XCTAssertFalse(subject.localTrack?.isEnabled ?? true)
        XCTAssertNil(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.first)
    }

    func test_setUp_doesNotHavesVideoCapability_noLocalTrack_doesNotCreateTrack() async throws {
        // Given
        let mockCapturer = MockCameraVideoCapturer()
        mockCapturerFactory.stub(for: .buildCameraCapturer, with: mockCapturer)
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
            with: .init(videoOn: true),
            ownCapabilities: []
        )

        // Then
        await fulfillment(of: [eventExpectation], timeout: 1) // We set it to one to avoid delaying tests.
        XCTAssertNil(subject.localTrack)
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
        subject.localTrack?.isEnabled = true

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
            with: try makeTransceiver(of: .video)
        )
        try await subject.setUp(
            with: .init(videoOn: false),
            ownCapabilities: [.sendVideo]
        )

        subject.publish()

        await fulfillment { self.subject.localTrack?.isEnabled == true }
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
    }

    func test_publish_disabledLocalTrack_transceiverHasBeenCreated_enablesAndAddsTrack() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .video, codecs: VideoCodec.defaultCodecs)
        )
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )

        subject.publish()

        XCTAssertTrue(subject.localTrack?.isEnabled ?? false)
        XCTAssertEqual(mockPeerConnection.stubbedFunctionInput[.addTransceiver]?.count, 1)
        XCTAssertEqual(
            (mockPeerConnection.stubbedFunction[.addTransceiver] as? RTCRtpTransceiver)?.sender.parameters.encodings.flatMap(\.rid),
            ["q", "h", "f"]
        )
    }

    // MARK: - unpublish

    func test_publish_enabledLocalTrack_enablesAndAddsTrackAndTransceiver() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .video)
        )
        try await subject.setUp(
            with: .init(videoOn: true),
            ownCapabilities: [.sendVideo]
        )
        subject.localTrack?.isEnabled = true

        subject.unpublish()

        await fulfillment { self.subject.localTrack?.isEnabled == false }
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

        try subject.zoom(by: 10)

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

        try subject.focus(at: .init(x: 10, y: 30))

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

        try subject.addVideoOutput(videoOutput)

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

        try subject.removeVideoOutput(videoOutput)

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

        try subject.addCapturePhotoOutput(videoOutput)

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

        try subject.removeCapturePhotoOutput(videoOutput)

        XCTAssertTrue(
            mockCapturer.recordedInputPayload(AVCapturePhotoOutput.self, for: .removeCapturePhotoOutput)?.last === videoOutput
        )
    }

    // MARK: - changePublishQuality(_:)

    func test_changePublishQuality_transceiverWasUpdatedCorrectly() async throws {
        mockPeerConnection.stub(
            for: .addTransceiver,
            with: try makeTransceiver(of: .video, codecs: VideoCodec.defaultCodecs)
        )
        try await subject.setUp(
            with: .init(videoOn: true, cameraPosition: .back),
            ownCapabilities: [.sendVideo]
        )
        subject.publish()

        subject.changePublishQuality(with: ["q"])

        await fulfillment { self.mockPeerConnection.timesCalled(.addTransceiver) == 1 }
        XCTAssertEqual(
            (mockPeerConnection.stubbedFunction[.addTransceiver] as? RTCRtpTransceiver)?
                .sender
                .parameters
                .encodings
                .filter { $0.isActive }
                .compactMap(\.rid),
            ["q"]
        )
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
