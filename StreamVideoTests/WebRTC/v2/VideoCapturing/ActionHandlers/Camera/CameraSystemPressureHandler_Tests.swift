//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import CoreMedia
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class CameraSystemPressureHandler_Tests: XCTestCase, @unchecked Sendable {

    private var subject: CameraSystemPressureHandler!
    private var mockDevice: MockSystemPressureCaptureDevice!
    private var mockProvider: MockSystemPressureCaptureDeviceProvider!
    private var previousProvider: SystemPressureCaptureDeviceProviding?

    private var videoSource: RTCVideoSource!
    private var videoCapturer: RTCCameraVideoCapturer!
    private var videoCapturerDelegate: RTCVideoCapturerDelegate!
    private var audioDeviceModule: AudioDeviceModule!
    @Atomic private var dispatchedAction: StreamVideoCapturer.Action?

    override func setUp() {
        super.setUp()
        mockDevice = .init(frameRateRange: 5...60)
        mockProvider = .init(device: mockDevice)
        previousProvider = InjectedValues[\.systemPressureCaptureDeviceProvider]
        InjectedValues[\.systemPressureCaptureDeviceProvider] = mockProvider
        subject = .init()

        videoSource = PeerConnectionFactory
            .mock()
            .makeVideoSource(forScreenShare: false)
        videoCapturer = RTCCameraVideoCapturer()
        videoCapturerDelegate = MockRTCVideoCapturerDelegate()
        audioDeviceModule = .init(MockRTCAudioDeviceModule())
    }

    override func tearDown() {
        InjectedValues[\.systemPressureCaptureDeviceProvider] =
            previousProvider ?? StreamSystemPressureCaptureDeviceProvider()
        previousProvider = nil
        audioDeviceModule = nil
        videoCapturerDelegate = nil
        videoCapturer = nil
        videoSource = nil
        mockProvider = nil
        mockDevice = nil
        subject = nil
        dispatchedAction = nil
        super.tearDown()
    }

    // MARK: - handle

    func test_handle_startCapture_appliesPressureBasedFrameRate() async throws {
        try await subject.handle(
            .startCapture(
                position: .back,
                dimensions: CGSize(width: 1280, height: 720),
                frameRate: 30,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                audioDeviceModule: audioDeviceModule
            )
        )

        mockDevice.sendPressureLevel(.serious)

        await fulfillment("Expected frame rate to be applied under pressure.") {
            self.mockDevice.lastAppliedFrameRate == 15
        }

        XCTAssertEqual(mockDevice.lastAppliedFrameRate, 15)
    }

    func test_handle_externalUpdate_dispatchesAction() async throws {
        subject.actionDispatcher = { action in
            self.dispatchedAction = action
        }

        try await subject.handle(
            .startCapture(
                position: .back,
                dimensions: CGSize(width: 1280, height: 720),
                frameRate: 30,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                audioDeviceModule: audioDeviceModule
            )
        )

        mockDevice.sendPressureLevel(.critical)

        await fulfillment("Expected pressure level to be processed.") {
            self.mockDevice.lastAppliedFrameRate == 10
        }

        try await subject.handle(
            .updateCaptureQuality(
                dimensions: CGSize(width: 1280, height: 720),
                device: mockDevice,
                videoSource: videoSource,
                videoCapturer: videoCapturer,
                videoCapturerDelegate: videoCapturerDelegate,
                reason: .external
            )
        )

        await fulfillment("Expected update action to be dispatched.") {
            self.dispatchedAction != nil
        }

        guard case let .updateCaptureQuality(
            dimensions,
            device,
            _,
            _,
            _,
            reason
        ) = dispatchedAction else {
            XCTFail("Expected updateCaptureQuality action to be dispatched.")
            return
        }

        XCTAssertEqual(dimensions, CGSize(width: 640, height: 360))
        XCTAssertTrue(device === mockDevice)
        XCTAssertEqual(reason, .systemPressure)
    }
}

private final class MockSystemPressureCaptureDevice:
    SystemPressureCaptureDevice,
    @unchecked Sendable {

    private let subject =
        PassthroughSubject<AVCaptureDevice.SystemPressureState.Level, Never>()

    @Atomic var lastAppliedFrameRate: Int?
    var activeFormatFrameRateRange: ClosedRange<Int>
    var position: AVCaptureDevice.Position = .back

    init(frameRateRange: ClosedRange<Int>) {
        activeFormatFrameRateRange = frameRateRange
    }

    var systemPressureLevelPublisher: AnyPublisher<
        AVCaptureDevice.SystemPressureState.Level,
        Never
    > {
        subject.eraseToAnyPublisher()
    }

    func applyFixedFrameRate(_ fps: Int) throws {
        lastAppliedFrameRate = fps
    }

    func outputFormat(
        preferredDimensions: CMVideoDimensions,
        preferredFrameRate: Int,
        preferredMediaSubType: FourCharCode
    ) -> AVCaptureDevice.Format? {
        nil
    }

    func sendPressureLevel(
        _ level: AVCaptureDevice.SystemPressureState.Level
    ) {
        subject.send(level)
    }
}

private final class MockSystemPressureCaptureDeviceProvider:
    SystemPressureCaptureDeviceProviding,
    @unchecked Sendable {
    private let device: SystemPressureCaptureDevice?

    init(device: SystemPressureCaptureDevice?) {
        self.device = device
    }

    func device(
        for cameraCapturer: RTCCameraVideoCapturer,
        position: AVCaptureDevice.Position
    ) -> SystemPressureCaptureDevice? {
        device
    }
}
