//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCRtpTransceiverInit_ConvenienceTests: XCTestCase, @unchecked Sendable {

    // MARK: - temporary

    func test_temporary_withAudioTrack() {
        let transceiverInit = RTCRtpTransceiverInit.temporary(trackType: .audio)

        XCTAssertEqual(transceiverInit.direction, .sendOnly)
        XCTAssertEqual(transceiverInit.streamIds, ["temp-audio"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 0)
    }

    func test_temporary_withVideoTrack() {
        let transceiverInit = RTCRtpTransceiverInit.temporary(trackType: .video)

        XCTAssertEqual(transceiverInit.direction, .sendOnly)
        XCTAssertEqual(transceiverInit.streamIds, ["temp-video"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 3)
    }

    func test_temporary_withScreenShareTrack() {
        let transceiverInit = RTCRtpTransceiverInit.temporary(trackType: .screenshare)

        XCTAssertEqual(transceiverInit.direction, .sendOnly)
        XCTAssertEqual(transceiverInit.streamIds, ["temp-screenshare"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)
        XCTAssertTrue(transceiverInit.sendEncodings.allSatisfy { $0.isActive })
    }

    func test_temporary_withUnknownTrack() {
        let transceiverInit = RTCRtpTransceiverInit.temporary(trackType: .unknown)

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds.count, 0)
        XCTAssertEqual(transceiverInit.sendEncodings.count, 0)
    }

    // MARK: - init(direction:streamIds:audioOptions:)

    func test_initWithAudioPublishOptions() {
        let audioOptions = PublishOptions.AudioPublishOptions(
            id: 1,
            codec: .opus,
            bitrate: 64000
        )

        let transceiverInit = RTCRtpTransceiverInit(
            direction: .sendRecv,
            streamIds: ["audio-stream"],
            audioOptions: audioOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["audio-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 0)
    }

    // MARK: - init(trackType:direction:streamIds:videoOptions:)

    func test_initWithVideoPublishOptions_forNonSVCCodec_withThreeSpatialLayers() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 3, temporalLayers: 1),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 3)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(transceiverInit.sendEncodings[1].rid, VideoLayer.Quality.half.rawValue)
        XCTAssertEqual(transceiverInit.sendEncodings[2].rid, VideoLayer.Quality.full.rawValue)
    }

    func test_initWithVideoPublishOptions_forNonSVCCodec_withTwoSpatialLayers() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 2, temporalLayers: 1),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 2)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
        XCTAssertEqual(transceiverInit.sendEncodings[1].rid, VideoLayer.Quality.half.rawValue)
    }

    func test_initWithVideoPublishOptions_forNonSVCCodec_withOneSpatialLayer() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .h264,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
    }

    func test_initWithVideoPublishOptions_forSVCCodec_withThreeSpatialLayers() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp9,
            capturingLayers: .init(spatialLayers: 3, temporalLayers: 2),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
    }

    func test_initWithVideoPublishOptions_forSVCCodec_withTwoSpatialLayers() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp9,
            capturingLayers: .init(spatialLayers: 2, temporalLayers: 2),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
    }

    func test_initWithVideoPublishOptions_forSVCCodec_withOneSpatialLayer() {
        let videoOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp9,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 2),
            bitrate: 1_000_000,
            frameRate: 30,
            dimensions: CGSize(width: 1920, height: 1080)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .video,
            direction: .sendRecv,
            streamIds: ["video-stream"],
            videoOptions: videoOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["video-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
    }

    func test_initWithScreenSharePublishOptions() {
        let screenShareOptions = PublishOptions.VideoPublishOptions(
            id: 1,
            codec: .vp8,
            capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
            bitrate: 500_000,
            frameRate: 15,
            dimensions: CGSize(width: 1280, height: 720)
        )

        let transceiverInit = RTCRtpTransceiverInit(
            trackType: .screenshare,
            direction: .sendRecv,
            streamIds: ["screenshare-stream"],
            videoOptions: screenShareOptions
        )

        XCTAssertEqual(transceiverInit.direction, .sendRecv)
        XCTAssertEqual(transceiverInit.streamIds, ["screenshare-stream"])
        XCTAssertEqual(transceiverInit.sendEncodings.count, 1)
        XCTAssertTrue(transceiverInit.sendEncodings.allSatisfy { $0.isActive })

        XCTAssertEqual(transceiverInit.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue)
    }
}
