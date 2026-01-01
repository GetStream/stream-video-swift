//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StreamVideoSfuModelsVideoLayer_ConvenienceTests: XCTestCase, @unchecked Sendable {

    func test_initWithVideoLayer() {
        let videoLayer = VideoLayer(
            dimensions: CMVideoDimensions(width: 1920, height: 1080),
            quality: .full,
            maxBitrate: 1_000_000,
            sfuQuality: .high
        )

        let sfuVideoLayer = Stream_Video_Sfu_Models_VideoLayer(videoLayer, fps: 30)

        XCTAssertEqual(sfuVideoLayer.bitrate, 1_000_000)
        XCTAssertEqual(sfuVideoLayer.rid, "f")
        XCTAssertEqual(sfuVideoLayer.videoDimension.width, 1920)
        XCTAssertEqual(sfuVideoLayer.videoDimension.height, 1080)
        XCTAssertEqual(sfuVideoLayer.quality, .high)
        XCTAssertEqual(sfuVideoLayer.fps, 30)
    }

    func test_initWithRTCRtpEncodingParameters() {
        let encodingParameters = MockRTCRtpEncodingParameters()
        encodingParameters.stub(for: \.rid, with: "q")
        encodingParameters.stub(for: \.maxBitrateBps, with: NSNumber(value: 500_000))
        encodingParameters.stub(for: \.maxFramerate, with: NSNumber(value: 15))

        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp8,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1280, height: 720)
        )

        let sfuVideoLayer = Stream_Video_Sfu_Models_VideoLayer(encodingParameters, publishOptions: videoOptions)

        XCTAssertEqual(sfuVideoLayer.rid, "q")
        XCTAssertEqual(sfuVideoLayer.bitrate, 500_000)
        XCTAssertEqual(sfuVideoLayer.fps, 15)
        XCTAssertEqual(sfuVideoLayer.videoDimension.width, 1280)
        XCTAssertEqual(sfuVideoLayer.videoDimension.height, 720)
    }

    func test_initWithRTCRtpEncodingParameters_withMissingValues() {
        let encodingParameters = MockRTCRtpEncodingParameters()
        encodingParameters.stub(for: \.rid, with: nil)
        encodingParameters.stub(for: \.maxBitrateBps, with: nil)
        encodingParameters.stub(for: \.maxFramerate, with: nil)

        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp8,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1280, height: 720)
        )

        let sfuVideoLayer = Stream_Video_Sfu_Models_VideoLayer(encodingParameters, publishOptions: videoOptions)

        XCTAssertEqual(sfuVideoLayer.rid, "q")
        XCTAssertEqual(sfuVideoLayer.bitrate, 1_000_000)
        XCTAssertEqual(sfuVideoLayer.fps, 30)
        XCTAssertEqual(sfuVideoLayer.videoDimension.width, 1280)
        XCTAssertEqual(sfuVideoLayer.videoDimension.height, 720)
    }
}
