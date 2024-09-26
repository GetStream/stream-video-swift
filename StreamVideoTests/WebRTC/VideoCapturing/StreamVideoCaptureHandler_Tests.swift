//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamVideoCaptureHandler_Tests: XCTestCase {

    private lazy var source: MockRTCVideoCapturerDelegate! = .init()
    private lazy var subject: StreamVideoCaptureHandler! = .init(
        source: source,
        filters: []
    )

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        source = nil
        super.tearDown()
    }

    // MARK: - capturer(_:didCapture:)

    // MARK: camera: front

    func test_didCapture_orientationPortraitCameraFront_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .portrait(isUpsideDown: false),
            cameraPosition: .front,
            expected: ._90
        )
    }

    func test_didCapture_orientationPortraitUpsideDownCameraFront_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .portrait(isUpsideDown: true),
            cameraPosition: .front,
            expected: ._270
        )
    }

    func test_didCapture_orientationLandscapeLeftCameraFront_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .landscape(isLeft: true),
            cameraPosition: .front,
            expected: ._0
        )
    }

    func test_didCapture_orientationLandscapeRightCameraFront_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .landscape(isLeft: false),
            cameraPosition: .front,
            expected: ._180
        )
    }

    // MARK: camera: back

    func test_didCapture_orientationPortraitCameraBack_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .portrait(isUpsideDown: false),
            cameraPosition: .back,
            expected: ._90
        )
    }

    func test_didCapture_orientationPortraitUpsideDownCameraBack_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .portrait(isUpsideDown: true),
            cameraPosition: .back,
            expected: ._270
        )
    }

    func test_didCapture_orientationLandscapeLeftCameraBack_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .landscape(isLeft: true),
            cameraPosition: .back,
            expected: ._180
        )
    }

    func test_didCapture_orientationLandscapeRightCameraBack_frameHasExpectedOrientation() async throws {
        try await assertFrameOrientation(
            deviceOrientation: .landscape(isLeft: false),
            cameraPosition: .back,
            expected: ._0
        )
    }

    // MARK: - Private Helpers

    func assertFrameOrientation(
        deviceOrientation: StreamDeviceOrientation,
        cameraPosition: AVCaptureDevice.Position,
        expected: RTCVideoRotation,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let orientationAdapter = StreamDeviceOrientationAdapter() { deviceOrientation }
        InjectedValues[\.orientationAdapter] = orientationAdapter
        let capturer: RTCVideoCapturer! = .init()
        _ = subject
        subject.currentCameraPosition = cameraPosition
        let frame = RTCVideoFrame(
            buffer: RTCCVPixelBuffer(pixelBuffer: try .make()),
            rotation: ._270,
            timeStampNs: 0
        )

        subject.capturer(capturer, didCapture: frame)

        await fulfillment(file: file, line: line) { self.source.didCaptureWasCalledWith != nil }
        XCTAssertTrue(
            source.didCaptureWasCalledWith?.capturer === capturer,
            file: file,
            line: line
        )
        XCTAssertEqual(
            source.didCaptureWasCalledWith?.frame.rotation.rawValue,
            expected.rawValue,
            file: file,
            line: line
        )
    }
}
