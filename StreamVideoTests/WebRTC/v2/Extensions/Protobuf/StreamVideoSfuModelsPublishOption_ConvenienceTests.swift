//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamVideoSfuModelsPublishOption_ConvenienceTests: XCTestCase, @unchecked Sendable {

    func test_initWithAudioPublishOptions() {
        let audioOptions = PublishOptions.AudioPublishOptions(
            id: 1,
            codec: .opus,
            bitrate: 64000
        )

        let publishOption = Stream_Video_Sfu_Models_PublishOption(audioOptions)

        XCTAssertEqual(publishOption.trackType, .audio)
        XCTAssertEqual(publishOption.codec.name, "opus")
        XCTAssertEqual(publishOption.bitrate, 64000)
    }

    func test_initWithVideoPublishOptions() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 3, temporalLayers: 2),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let publishOption = Stream_Video_Sfu_Models_PublishOption(videoOptions, trackType: .video)

        XCTAssertEqual(publishOption.trackType, .video)
        XCTAssertEqual(publishOption.codec.name, "h264")
        XCTAssertEqual(publishOption.bitrate, 1_000_000)
        XCTAssertEqual(publishOption.fps, 30)
        XCTAssertEqual(publishOption.videoDimension.width, 1920)
        XCTAssertEqual(publishOption.videoDimension.height, 1080)
        XCTAssertEqual(publishOption.maxSpatialLayers, 3)
        XCTAssertEqual(publishOption.maxTemporalLayers, 2)
    }

    func test_initWithScreenSharePublishOptions() {
        let screenShareOptions = PublishOptions.VideoPublishOptions(
            id: 2,
            codec: .vp8,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 500_000,
            frameRate: 15,
            dimensions: CGSize(width: 1280, height: 720)
        )

        let publishOption = Stream_Video_Sfu_Models_PublishOption(screenShareOptions, trackType: .screenShare)

        XCTAssertEqual(publishOption.trackType, .screenShare)
        XCTAssertEqual(publishOption.codec.name, "vp8")
        XCTAssertEqual(publishOption.bitrate, 500_000)
        XCTAssertEqual(publishOption.fps, 15)
        XCTAssertEqual(publishOption.videoDimension.width, 1280)
        XCTAssertEqual(publishOption.videoDimension.height, 720)
        XCTAssertEqual(publishOption.maxSpatialLayers, 1)
        XCTAssertEqual(publishOption.maxTemporalLayers, 1)
    }
}
