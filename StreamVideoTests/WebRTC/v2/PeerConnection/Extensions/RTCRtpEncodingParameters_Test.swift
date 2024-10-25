//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCRtpEncodingParameters_Tests: XCTestCase {

    func test_init_withLayerAndPreferredCodec_givenSVCCoded_whenCodecIsSVC_thenScalabilityModeIsSet() {
        let result = RTCRtpEncodingParameters(
            .init(dimensions: .full, quality: .full, maxBitrate: 100, sfuQuality: .high),
            preferredVideoCodec: .av1
        )

        XCTAssertEqual(result.rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(result.maxBitrateBps?.intValue, 100)
        XCTAssertEqual(result.scalabilityMode, "L3T2_KEY")
        XCTAssertNil(result.scaleResolutionDownBy)
    }

    func test_init_withLayerAndPreferredCodec_givenNonSVCCoded_whenScaleDownFactorExists_thenScaleResolutionIsSet() {
        let result = RTCRtpEncodingParameters(
            .init(dimensions: .full, quality: .full, maxBitrate: 100, scaleDownFactor: 10, sfuQuality: .high),
            preferredVideoCodec: .h264
        )

        XCTAssertEqual(result.rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(result.maxBitrateBps?.intValue, 100)
        XCTAssertEqual(result.scaleResolutionDownBy, 10)
        XCTAssertNil(result.scalabilityMode)
    }

    func test_init_withLayerAndPreferredCodec_givenNoScaleDownFactor_whenScaleDownFactorIsNil_thenScaleResolutionIsNil() {
        let result = RTCRtpEncodingParameters(
            .init(dimensions: .full, quality: .full, maxBitrate: 100, sfuQuality: .high),
            preferredVideoCodec: .h264
        )

        XCTAssertEqual(result.rid, VideoLayer.Quality.full.rawValue)
        XCTAssertEqual(result.maxBitrateBps?.intValue, 100)
        XCTAssertNil(result.scaleResolutionDownBy)
        XCTAssertNil(result.scalabilityMode)
    }
}
