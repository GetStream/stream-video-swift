//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCRtpEncodingParameters_Tests: XCTestCase, @unchecked Sendable {
    
    // MARK: - init(_:preferredVideoCodec:)
    
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
    
    // MARK: - init(_:videoPublishOptions:frameRate:bitrate:)
    
    func test_initWithVideoLayerAndPublishOptions_forSVCCodec() {
        let videoLayer = VideoLayer(
            dimensions: CMVideoDimensions(width: 1920, height: 1080),
            quality: .full,
            maxBitrate: 1_000_000,
            sfuQuality: .high
        )
        
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp9,
            capturingLayers: .init(spatialLayers: 3, temporalLayers: 2),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )
        
        let encodingParameters = RTCRtpEncodingParameters(
            videoLayer,
            videoPublishOptions: videoOptions,
            frameRate: 30,
            bitrate: 1_000_000
        )
        
        XCTAssertEqual(encodingParameters.rid, "f")
        XCTAssertEqual(encodingParameters.maxFramerate, 30)
        XCTAssertEqual(encodingParameters.maxBitrateBps, 1_000_000)
        XCTAssertEqual(encodingParameters.scalabilityMode, videoOptions.capturingLayers.scalabilityMode)
        XCTAssertNil(encodingParameters.scaleResolutionDownBy)
    }
    
    func test_initWithVideoLayerAndPublishOptions_forNonSVCCodec() {
        let videoLayer = VideoLayer(
            dimensions: CMVideoDimensions(width: 1280, height: 720),
            quality: .half,
            maxBitrate: 500_000,
            sfuQuality: .mid
        )
        
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 500_000,
            frameRate: 30,
            dimensions: CGSize(width: 1280, height: 720)
        )
        
        let encodingParameters = RTCRtpEncodingParameters(
            videoLayer,
            videoPublishOptions: videoOptions,
            frameRate: 30,
            bitrate: 500_000,
            scaleDownFactor: 2
        )
        
        XCTAssertEqual(encodingParameters.rid, "h")
        XCTAssertEqual(encodingParameters.maxFramerate, 30)
        XCTAssertEqual(encodingParameters.maxBitrateBps, 500_000)
        XCTAssertNil(encodingParameters.scalabilityMode)
        XCTAssertEqual(encodingParameters.scaleResolutionDownBy, 2)
    }
    
    func test_initWithVideoLayerAndPublishOptions_withDefaultScaleDownFactor() {
        let videoLayer = VideoLayer(
            dimensions: CMVideoDimensions(width: 640, height: 480),
            quality: .quarter,
            maxBitrate: 250_000,
            sfuQuality: .lowUnspecified
        )
        
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 250_000,
            frameRate: 30,
            dimensions: CGSize(width: 640, height: 480)
        )
        
        let encodingParameters = RTCRtpEncodingParameters(
            videoLayer,
            videoPublishOptions: videoOptions,
            frameRate: 30,
            bitrate: 250_000
        )
        
        XCTAssertEqual(encodingParameters.rid, "q")
        XCTAssertEqual(encodingParameters.maxFramerate, 30)
        XCTAssertEqual(encodingParameters.maxBitrateBps, 250_000)
        XCTAssertNil(encodingParameters.scalabilityMode)
        XCTAssertEqual(encodingParameters.scaleResolutionDownBy, 1)
    }
}
