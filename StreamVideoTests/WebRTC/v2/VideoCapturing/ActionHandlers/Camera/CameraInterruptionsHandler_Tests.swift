//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CameraInterruptionsHandler_Tests: XCTestCase, @unchecked Sendable {

    private var subject: CameraInterruptionsHandler!
    private var videoSource: RTCVideoSource!
    private var videoCapturer: RTCCameraVideoCapturer!
    private var videoCapturerDelegate: RTCVideoCapturerDelegate!
    private var audioDeviceModule: AudioDeviceModule!

    override func setUp() {
        super.setUp()
        subject = .init()
        videoSource = PeerConnectionFactory
            .mock()
            .makeVideoSource(forScreenShare: false)
        videoCapturerDelegate = MockRTCVideoCapturerDelegate()
        videoCapturer = RTCCameraVideoCapturer(
            delegate: videoCapturerDelegate,
            captureSession: AVCaptureSession()
        )
        audioDeviceModule = .init(MockRTCAudioDeviceModule())
    }

    override func tearDown() {
        audioDeviceModule = nil
        videoCapturerDelegate = nil
        videoCapturer = nil
        videoSource = nil
        subject = nil
        super.tearDown()
    }

    func test_handle_setCameraPosition_whenSessionStops_doesNotRestartCapture() async throws {
        let recorder = ActionRecorder()
        let unexpectedRecovery = expectation(description: "Capture should not recover.")
        unexpectedRecovery.isInverted = true
        unexpectedRecovery.assertForOverFulfill = false

        try await subject.handle(makeStartAction(position: .front))
        try await subject.handle(makeSetCameraPositionAction(position: .back))
        subject.actionDispatcher = { action in
            await recorder.record(action)
            unexpectedRecovery.fulfill()
        }

        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        await safeFulfillment(of: [unexpectedRecovery], timeout: 0.5)
        let actions = await recorder.actions
        XCTAssertTrue(actions.isEmpty)
    }

    func test_handle_setCameraPosition_whenSessionsStopDuringConsecutiveChanges_doesNotRestartCapture() async throws {
        let recorder = ActionRecorder()
        let unexpectedRecovery = expectation(description: "Capture should not recover.")
        unexpectedRecovery.isInverted = true
        unexpectedRecovery.assertForOverFulfill = false

        try await subject.handle(makeStartAction(position: .front))
        subject.actionDispatcher = { action in
            await recorder.record(action)
            unexpectedRecovery.fulfill()
        }

        try await subject.handle(makeSetCameraPositionAction(position: .back))
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        try await subject.handle(makeSetCameraPositionAction(position: .front))
        NotificationCenter.default.post(
            name: AVCaptureSession.didStartRunningNotification,
            object: videoCapturer.captureSession
        )
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        await safeFulfillment(of: [unexpectedRecovery], timeout: 0.5)
        let actions = await recorder.actions
        XCTAssertTrue(actions.isEmpty)
    }

    func test_handle_setCameraPosition_whenSessionStopsUnexpectedlyAfterRestart_restartsUsingCurrentPosition() async throws {
        let recorder = ActionRecorder()

        try await subject.handle(makeStartAction(position: .front))
        try await subject.handle(makeSetCameraPositionAction(position: .back))
        subject.actionDispatcher = { action in await recorder.record(action) }
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )
        NotificationCenter.default.post(
            name: AVCaptureSession.didStartRunningNotification,
            object: videoCapturer.captureSession
        )
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        await fulfillment("Expected capture recovery actions.") {
            await recorder.actions.count >= 2
        }
        let actions = await recorder.actions
        assertStopCapture(actions[0])
        assertStartCapture(actions[1], position: .back)
    }

    func test_handle_startCapture_whenSessionStopsUnexpectedly_restartsUsingLastConfiguration() async throws {
        let recorder = ActionRecorder()

        try await subject.handle(makeStartAction(position: .front))
        subject.actionDispatcher = { action in await recorder.record(action) }
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        await fulfillment("Expected capture recovery actions.") {
            await recorder.actions.count >= 2
        }
        let actions = await recorder.actions
        assertStopCapture(actions[0])
        assertStartCapture(actions[1], position: .front)
    }

    func test_handleFailure_setCameraPosition_whenSessionStopsLater_recoversUsingLastSuccessfulPosition() async throws {
        let recorder = ActionRecorder()
        let streamCapturer = StreamVideoCapturer(
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule,
            actionHandlers: [subject, FailingCameraPositionHandler()]
        )

        try await subject.handle(makeStartAction(position: .front))
        do {
            try await streamCapturer.setCameraPosition(.back)
            XCTFail("Expected the camera position change to fail.")
        } catch is FailingCameraPositionHandler.Failure {
            // Expected failure from the downstream handler.
        }

        subject.actionDispatcher = { action in await recorder.record(action) }
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )

        await fulfillment("Expected capture recovery actions.") {
            await recorder.actions.count >= 2
        }
        let actions = await recorder.actions
        assertStopCapture(actions[0])
        assertStartCapture(actions[1], position: .front)
    }

    func test_handleFailure_setCameraPosition_whenSessionAlreadyStopped_restartsUsingLastSuccessfulPosition() async throws {
        let recorder = ActionRecorder()
        let action = makeSetCameraPositionAction(position: .back)
        let unexpectedRecovery = expectation(description: "Capture should not recover.")
        unexpectedRecovery.isInverted = true
        unexpectedRecovery.assertForOverFulfill = false
        let expectedRecovery = expectation(description: "Capture should recover.")
        expectedRecovery.expectedFulfillmentCount = 2

        try await subject.handle(makeStartAction(position: .front))
        try await subject.handle(action)
        subject.actionDispatcher = { _ in unexpectedRecovery.fulfill() }
        NotificationCenter.default.post(
            name: AVCaptureSession.didStopRunningNotification,
            object: videoCapturer.captureSession
        )
        await safeFulfillment(of: [unexpectedRecovery], timeout: 0.5)

        subject.actionDispatcher = { action in
            await recorder.record(action)
            expectedRecovery.fulfill()
        }
        await subject.handleFailure(for: action)

        await fulfillment(of: [expectedRecovery], timeout: 1)
        let actions = await recorder.actions
        guard actions.count >= 2 else { return }
        assertStopCapture(actions[0])
        assertStartCapture(actions[1], position: .front)
    }

    private func makeStartAction(
        position: AVCaptureDevice.Position
    ) -> StreamVideoCapturer.Action {
        .startCapture(
            position: position,
            dimensions: CGSize(width: 1280, height: 720),
            frameRate: 30,
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate,
            audioDeviceModule: audioDeviceModule
        )
    }

    private func makeSetCameraPositionAction(
        position: AVCaptureDevice.Position
    ) -> StreamVideoCapturer.Action {
        .setCameraPosition(
            position: position,
            videoSource: videoSource,
            videoCapturer: videoCapturer,
            videoCapturerDelegate: videoCapturerDelegate
        )
    }

    private func assertStopCapture(
        _ action: StreamVideoCapturer.Action,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case .stopCapture = action else {
            XCTFail("Expected stopCapture action, got \(action).", file: file, line: line)
            return
        }
    }

    private func assertStartCapture(
        _ action: StreamVideoCapturer.Action,
        position expectedPosition: AVCaptureDevice.Position,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard case let .startCapture(position, _, _, _, _, _, _) = action else {
            XCTFail("Expected startCapture action, got \(action).", file: file, line: line)
            return
        }
        XCTAssertEqual(position, expectedPosition, file: file, line: line)
    }
}

private actor ActionRecorder {
    private(set) var actions: [StreamVideoCapturer.Action] = []

    func record(_ action: StreamVideoCapturer.Action) {
        actions.append(action)
    }
}

private struct FailingCameraPositionHandler: StreamVideoCapturerActionHandler {
    struct Failure: Error {}

    func handle(_ action: StreamVideoCapturer.Action) async throws {
        guard case .setCameraPosition = action else { return }
        throw Failure()
    }
}
