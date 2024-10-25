//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCRtpTransceiverInit_Tests: XCTestCase {

    func test_init_withTrackTypeAndDirection_givenVideoLayerAndSVCCodec_whenCodecIsSVC_thenSendEncodingsAreFilteredAndAdjusted() {
        let streamIds = [String.unique]
        let result = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendOnly,
            streamIds: streamIds,
            layers: VideoLayer.default,
            preferredVideoCodec: .av1
        )

        XCTAssertEqual(result.direction, .sendOnly)
        XCTAssertEqual(result.streamIds, streamIds)
        XCTAssertEqual(result.sendEncodings.count, 1)
        XCTAssertEqual(result.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(result.sendEncodings[0].maxBitrateBps?.intValue, VideoLayer.full.maxBitrate)
        XCTAssertTrue(result.sendEncodings[0].isActive)
    }

    func test_init_withTrackTypeAndDirection_givenVideoLayerAndNonSVCCodec_whenCodecIsNotSVC_thenAllLayersAreUsedInSendEncodings() {
        let streamIds = [String.unique]
        let result = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendOnly,
            streamIds: streamIds,
            layers: VideoLayer.default,
            preferredVideoCodec: .h264
        )

        XCTAssertEqual(result.direction, .sendOnly)
        XCTAssertEqual(result.streamIds, streamIds)
        XCTAssertEqual(result.sendEncodings.count, 3)
        XCTAssertEqual(result.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(result.sendEncodings[0].maxBitrateBps?.intValue, VideoLayer.quarter.maxBitrate)
        XCTAssertTrue(result.sendEncodings[0].isActive)
        XCTAssertEqual(result.sendEncodings[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(result.sendEncodings[1].maxBitrateBps?.intValue, VideoLayer.half.maxBitrate)
        XCTAssertTrue(result.sendEncodings[1].isActive)
        XCTAssertEqual(result.sendEncodings[2].rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(result.sendEncodings[2].maxBitrateBps?.intValue, VideoLayer.full.maxBitrate)
        XCTAssertTrue(result.sendEncodings[2].isActive)
    }

    func test_init_withScreenshare_givenTrackTypeScreenshare_whenScreenshare_thenAllEncodingsAreActive() {
        let streamIds = [String.unique]
        let result = RTCRtpTransceiverInit(
            trackType: .screenshare,
            direction: .sendOnly,
            streamIds: streamIds,
            layers: VideoLayer.default,
            preferredVideoCodec: .h264
        )

        XCTAssertEqual(result.direction, .sendOnly)
        XCTAssertEqual(result.streamIds, streamIds)
        XCTAssertEqual(result.sendEncodings.count, 3)
        XCTAssertEqual(result.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(result.sendEncodings[0].maxBitrateBps?.intValue, VideoLayer.quarter.maxBitrate)
        XCTAssertTrue(result.sendEncodings[0].isActive)
        XCTAssertEqual(result.sendEncodings[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(result.sendEncodings[1].maxBitrateBps?.intValue, VideoLayer.half.maxBitrate)
        XCTAssertTrue(result.sendEncodings[1].isActive)
        XCTAssertEqual(result.sendEncodings[2].rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(result.sendEncodings[2].maxBitrateBps?.intValue, VideoLayer.full.maxBitrate)
        XCTAssertTrue(result.sendEncodings[2].isActive)
    }
}
