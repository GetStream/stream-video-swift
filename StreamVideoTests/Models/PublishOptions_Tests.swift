//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class VideoPublishOptionsTests: XCTestCase, @unchecked Sendable {

    // MARK: - buildLayers

    func test_buildLayers_forVideoTrackWithNonSVCCodecs_returnsExpectedResult() {
        assertTrackLayers(.video, for: .h264, spatialLayers: 3)
        assertTrackLayers(.video, for: .h264, spatialLayers: 2)
        assertTrackLayers(.video, for: .h264, spatialLayers: 1)

        assertTrackLayers(.video, for: .vp8, spatialLayers: 3)
        assertTrackLayers(.video, for: .vp8, spatialLayers: 2)
        assertTrackLayers(.video, for: .vp8, spatialLayers: 1)
    }

    func test_buildLayers_forVideoTrackWithSVCCodecs_returnsExpectedResult() {
        assertTrackLayers(.video, for: .av1, spatialLayers: 3)
        assertTrackLayers(.video, for: .av1, spatialLayers: 2)
        assertTrackLayers(.video, for: .av1, spatialLayers: 1)

        assertTrackLayers(.video, for: .av1, spatialLayers: 3)
        assertTrackLayers(.video, for: .av1, spatialLayers: 2)
        assertTrackLayers(.video, for: .av1, spatialLayers: 1)
    }

    // MARK: - Private Helpers

    private func assertTrackLayers(
        _ trackType: TrackType,
        for codec: VideoCodec,
        spatialLayers: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let bitrate = 1000
        let frameRate = 30
        let dimensions = CGSize(width: 1920, height: 1080)
        let capturingLayers = PublishOptions.VideoPublishOptions.CapturingLayers(
            spatialLayers: spatialLayers,
            temporalLayers: 1
        )
        let options = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: codec,
            capturingLayers: capturingLayers,
            bitrate: bitrate,
            frameRate: frameRate,
            dimensions: dimensions
        )

        let layers = options.buildLayers(for: .video)

        XCTAssertEqual(layers.count, capturingLayers.spatialLayers)
        switch spatialLayers {
        case 1:
            XCTAssertEqual(layers[0].rid, "q")
            XCTAssertEqual(layers[0].bitrate, .init(bitrate))
            XCTAssertEqual(layers[0].fps, .init(frameRate))
            XCTAssertEqual(layers[0].videoDimension.width, .init(dimensions.width))
            XCTAssertEqual(layers[0].videoDimension.height, .init(dimensions.height))

        case 2:
            XCTAssertEqual(layers[0].rid, "q")
            XCTAssertEqual(layers[0].bitrate, .init(bitrate / 2))
            XCTAssertEqual(layers[0].fps, .init(frameRate))
            XCTAssertEqual(layers[0].videoDimension.width, .init(dimensions.width / 2))
            XCTAssertEqual(layers[0].videoDimension.height, .init(dimensions.height / 2))

            XCTAssertEqual(layers[1].rid, "h")
            XCTAssertEqual(layers[1].bitrate, .init(bitrate))
            XCTAssertEqual(layers[1].fps, .init(frameRate))
            XCTAssertEqual(layers[1].videoDimension.width, .init(dimensions.width))
            XCTAssertEqual(layers[1].videoDimension.height, .init(dimensions.height))

        case 3:
            XCTAssertEqual(layers[0].rid, "q")
            XCTAssertEqual(layers[0].bitrate, .init(bitrate / 4))
            XCTAssertEqual(layers[0].fps, .init(frameRate))
            XCTAssertEqual(layers[0].videoDimension.width, .init(dimensions.width / 4))
            XCTAssertEqual(layers[0].videoDimension.height, .init(dimensions.height / 4))

            XCTAssertEqual(layers[1].rid, "h")
            XCTAssertEqual(layers[1].bitrate, .init(bitrate / 2))
            XCTAssertEqual(layers[1].fps, .init(frameRate))
            XCTAssertEqual(layers[1].videoDimension.width, .init(dimensions.width / 2))
            XCTAssertEqual(layers[1].videoDimension.height, .init(dimensions.height / 2))

            XCTAssertEqual(layers[2].rid, "f")
            XCTAssertEqual(layers[2].bitrate, .init(bitrate))
            XCTAssertEqual(layers[2].fps, .init(frameRate))
            XCTAssertEqual(layers[2].videoDimension.width, .init(dimensions.width))
            XCTAssertEqual(layers[2].videoDimension.height, .init(dimensions.height))

        default:
            fatalError()
        }
    }
}
