//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreVideo
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class StreamVideoProcessPipeline_Tests: XCTestCase, @unchecked Sendable {

    private var source: MockRTCVideoCapturerDelegate!
    private var subject: StreamVideoProcessPipeline!

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        source = nil
        super.tearDown()
    }

    // MARK: - didUpdate(_:)

    func test_didUpdate_forwardsFilterToNodes() {
        var nodeOneFilter: VideoFilter?
        var nodeTwoFilter: VideoFilter?
        let nodes = [
            TestNode(onUpdate: { nodeOneFilter = $0 }),
            TestNode(onUpdate: { nodeTwoFilter = $0 })
        ]
        source = .init()
        subject = StreamVideoProcessPipeline(
            source: source,
            nodes: nodes
        )
        let filter = VideoFilter(
            id: "filter",
            name: "Filter",
            filter: { $0.originalImage }
        )

        subject.didUpdate(filter)

        XCTAssertTrue(nodeOneFilter === filter)
        XCTAssertTrue(nodeTwoFilter === filter)
    }

    // MARK: - capturer(_:didCapture:)

    func test_capturer_nodesEmpty_forwardsOriginalFrame() throws {
        source = .init()
        subject = StreamVideoProcessPipeline(
            source: source,
            nodes: []
        )
        let capturer = RTCVideoCapturer()
        let frame = try makeFrame(rotation: ._0, timeStampNs: 10)

        subject.capturer(capturer, didCapture: frame)

        XCTAssertTrue(source.didCaptureWasCalledWith?.capturer === capturer)
        XCTAssertTrue(source.didCaptureWasCalledWith?.frame === frame)
    }

    func test_capturer_nodesApplySequentialTransforms_forwardsLastFrame() throws {
        let nodes = [
            TestNode(
                onCapture: { frame in
                    RTCVideoFrame(
                        buffer: frame.buffer,
                        rotation: ._90,
                        timeStampNs: frame.timeStampNs
                    )
                }
            ),
            TestNode(
                onCapture: { frame in
                    RTCVideoFrame(
                        buffer: frame.buffer,
                        rotation: ._180,
                        timeStampNs: frame.timeStampNs
                    )
                }
            )
        ]
        source = .init()
        subject = StreamVideoProcessPipeline(
            source: source,
            nodes: nodes
        )
        let capturer = RTCVideoCapturer()
        let frame = try makeFrame(rotation: ._0, timeStampNs: 20)

        subject.capturer(capturer, didCapture: frame)

        XCTAssertTrue(source.didCaptureWasCalledWith?.capturer === capturer)
        XCTAssertEqual(source.didCaptureWasCalledWith?.frame.rotation, ._180)
    }

    // MARK: - Private Helpers

    private func makeFrame(
        rotation: RTCVideoRotation,
        timeStampNs: Int64
    ) throws -> RTCVideoFrame {
        RTCVideoFrame(
            buffer: RTCCVPixelBuffer(pixelBuffer: try .make()),
            rotation: rotation,
            timeStampNs: timeStampNs
        )
    }
}

private final class TestNode: StreamVideoProcessNode {
    private let onUpdate: (VideoFilter?) -> Void
    private let onCapture: (RTCVideoFrame) -> RTCVideoFrame

    init(
        onUpdate: @escaping (VideoFilter?) -> Void = { _ in },
        onCapture: @escaping (RTCVideoFrame) -> RTCVideoFrame = { $0 }
    ) {
        self.onUpdate = onUpdate
        self.onCapture = onCapture
    }

    func didUpdate(_ videoFilter: VideoFilter?) {
        onUpdate(videoFilter)
    }

    func didCapture(_ frame: RTCVideoFrame) -> RTCVideoFrame {
        onCapture(frame)
    }
}
