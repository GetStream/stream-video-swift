//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CoreMedia
@testable import StreamVideo
import XCTest

final class StreamVideoSfuModelsPublishOption_VideoLayersTests: XCTestCase, @unchecked Sendable {

    func test_videoLayers_withThreeSpatialLayers() {
        var publishOption = Stream_Video_Sfu_Models_PublishOption()
        publishOption.videoDimension.width = 1920
        publishOption.videoDimension.height = 1080
        publishOption.bitrate = 1_000_000
        publishOption.maxSpatialLayers = 3

        let videoLayers = publishOption.videoLayers(spatialLayersRequired: 3)

        XCTAssertEqual(videoLayers.count, 3)
        XCTAssertEqual(videoLayers[0].quality, .full)
        XCTAssertEqual(videoLayers[0].dimensions.width, 1920)
        XCTAssertEqual(videoLayers[0].dimensions.height, 1080)
        XCTAssertEqual(videoLayers[0].maxBitrate, 1_000_000)

        XCTAssertEqual(videoLayers[1].quality, .half)
        XCTAssertEqual(videoLayers[1].dimensions.width, 960)
        XCTAssertEqual(videoLayers[1].dimensions.height, 540)
        XCTAssertEqual(videoLayers[1].maxBitrate, 500_000)

        XCTAssertEqual(videoLayers[2].quality, .quarter)
        XCTAssertEqual(videoLayers[2].dimensions.width, 480)
        XCTAssertEqual(videoLayers[2].dimensions.height, 270)
        XCTAssertEqual(videoLayers[2].maxBitrate, 250_000)
    }

    func test_videoLayers_withTwoSpatialLayers() {
        var publishOption = Stream_Video_Sfu_Models_PublishOption()
        publishOption.videoDimension.width = 1280
        publishOption.videoDimension.height = 720
        publishOption.bitrate = 500_000
        publishOption.maxSpatialLayers = 2

        let videoLayers = publishOption.videoLayers(spatialLayersRequired: 2)

        XCTAssertEqual(videoLayers.count, 2)
        XCTAssertEqual(videoLayers[0].quality, .full)
        XCTAssertEqual(videoLayers[0].dimensions.width, 1280)
        XCTAssertEqual(videoLayers[0].dimensions.height, 720)
        XCTAssertEqual(videoLayers[0].maxBitrate, 500_000)

        XCTAssertEqual(videoLayers[1].quality, .half)
        XCTAssertEqual(videoLayers[1].dimensions.width, 640)
        XCTAssertEqual(videoLayers[1].dimensions.height, 360)
        XCTAssertEqual(videoLayers[1].maxBitrate, 250_000)
    }

    func test_videoLayers_withOneSpatialLayer() {
        var publishOption = Stream_Video_Sfu_Models_PublishOption()
        publishOption.videoDimension.width = 640
        publishOption.videoDimension.height = 480
        publishOption.bitrate = 250_000
        publishOption.maxSpatialLayers = 1

        let videoLayers = publishOption.videoLayers(spatialLayersRequired: 1)

        XCTAssertEqual(videoLayers.count, 1)
        XCTAssertEqual(videoLayers[0].quality, .full)
        XCTAssertEqual(videoLayers[0].dimensions.width, 640)
        XCTAssertEqual(videoLayers[0].dimensions.height, 480)
        XCTAssertEqual(videoLayers[0].maxBitrate, 250_000)
    }

    func test_videoLayers_withNoSpatialLayers() {
        var publishOption = Stream_Video_Sfu_Models_PublishOption()
        publishOption.videoDimension.width = 1920
        publishOption.videoDimension.height = 1080
        publishOption.bitrate = 1_000_000
        publishOption.maxSpatialLayers = 0

        let videoLayers = publishOption.videoLayers(spatialLayersRequired: 0)

        XCTAssertEqual(videoLayers.count, 0)
    }
}
