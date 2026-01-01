//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCRtpTransceiverInit_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - temporary

    func test_temporary_audio_returnsCorrectlyConfiguredTransceiverInit() {
        assertTemporary(.audio)
    }

    func test_temporary_video_returnsCorrectlyConfiguredTransceiverInit() {
        assertTemporary(.video)
    }

    func test_temporary_screenShare_returnsCorrectlyConfiguredTransceiverInit() {
        assertTemporary(.screenshare)
    }

    // MARK: - init(direction:streamIds:audioOptions:)

    func test_init_trackTypeAudio_returnsCorrectlyConfiguredTransceiverInit() {
        let streamID = String.unique
        let direction = RTCRtpTransceiverDirection.sendRecv

        let subject = RTCRtpTransceiverInit(
            direction: direction,
            streamIds: [streamID],
            audioOptions: .init(codec: .unknown)
        )

        XCTAssertEqual(subject.direction, direction)
        XCTAssertEqual(subject.streamIds, [streamID])
    }

    // MARK: - init(direction:streamIds:videoOptions:)

    // MARK: Non-SVC

    func test_init_trackTypeVideo_nonSVC_3SpatialLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .h264,
                capturingLayers: .init(spatialLayers: 3, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_nonSVC2SpatialLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .h264,
                capturingLayers: .init(spatialLayers: 2, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_nonSVC1SpatialLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .h264,
                capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    // MARK: SVC

    func test_init_trackTypeVideo_svc_1SpatialLayers_3TemporalLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .av1,
                capturingLayers: .init(spatialLayers: 1, temporalLayers: 3),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_svc_1SpatialLayers_2TemporalLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .av1,
                capturingLayers: .init(spatialLayers: 1, temporalLayers: 2),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_svc_1SpatialLayers_1TemporalLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .av1,
                capturingLayers: .init(spatialLayers: 1, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_svc_2SpatialLayers_1TemporalLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .av1,
                capturingLayers: .init(spatialLayers: 2, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    func test_init_trackTypeVideo_svc_3SpatialLayers_1TemporalLayers_returnsCorrectlyConfiguredTransceiverInit() throws {
        try assertInit(
            .video,
            videoOptions: .init(
                codec: .av1,
                capturingLayers: .init(spatialLayers: 2, temporalLayers: 1),
                bitrate: 1_000_000,
                frameRate: 30
            )
        )
    }

    // MARK: - Private Helpers

    private func assertTemporary(
        _ trackType: TrackType,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let subject = RTCRtpTransceiverInit.temporary(trackType: trackType)

        XCTAssertEqual(subject.direction, .sendOnly)
        switch trackType {
        case .audio:
            XCTAssertEqual(subject.streamIds, ["temp-audio"], file: file, line: line)
        case .video:
            XCTAssertEqual(subject.streamIds, ["temp-video"], file: file, line: line)
            XCTAssertEqual(subject.sendEncodings.count, 3, file: file, line: line)
            XCTAssertEqual(subject.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue, file: file, line: line)
            XCTAssertEqual(subject.sendEncodings[1].rid, VideoLayer.Quality.half.rawValue, file: file, line: line)
            XCTAssertEqual(subject.sendEncodings[2].rid, VideoLayer.Quality.full.rawValue, file: file, line: line)
        case .screenshare:
            XCTAssertEqual(subject.streamIds, ["temp-screenshare"], file: file, line: line)
            XCTAssertEqual(subject.sendEncodings.count, 1, file: file, line: line)
            XCTAssertEqual(subject.sendEncodings[0].rid, VideoLayer.Quality.quarter.rawValue, file: file, line: line)
            XCTAssertTrue(subject.sendEncodings[0].isActive, file: file, line: line)
        default:
            break
        }
    }

    private func assertInit(
        _ trackType: TrackType,
        videoOptions: PublishOptions.VideoPublishOptions,
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let streamID = String.unique
        let direction = RTCRtpTransceiverDirection.sendRecv

        let subject = RTCRtpTransceiverInit(
            trackType: trackType,
            direction: direction,
            streamIds: [streamID],
            videoOptions: videoOptions
        )

        XCTAssertEqual(
            subject.direction,
            direction,
            "direction should be \(direction).",
            file: file,
            line: line
        )
        XCTAssertEqual(
            subject.streamIds,
            [streamID],
            "streamIds should be \([streamID]).",
            file: file,
            line: line
        )

        if videoOptions.codec.isSVC {
            XCTAssertEqual(
                subject.sendEncodings.count,
                1,
                "sendEncoding count should be 1.",
                file: file,
                line: line
            )
        } else {
            XCTAssertEqual(
                subject.sendEncodings.count,
                videoOptions.capturingLayers.spatialLayers,
                "sendEncodings count should be \(videoOptions.capturingLayers.spatialLayers).",
                file: file,
                line: line
            )
        }

        for (offset, sendEncoding) in subject.sendEncodings.enumerated() {
            switch offset {
            case 0:
                XCTAssertEqual(
                    sendEncoding.rid,
                    VideoLayer.Quality.quarter.rawValue,
                    "rid should be set to \(VideoLayer.Quality.quarter.rawValue).",
                    file: file,
                    line: line
                )
            case 1:
                XCTAssertEqual(
                    sendEncoding.rid,
                    VideoLayer.Quality.half.rawValue,
                    "rid should be set to \(VideoLayer.Quality.half.rawValue).",
                    file: file,
                    line: line
                )
            case 2:
                XCTAssertEqual(
                    sendEncoding.rid,
                    VideoLayer.Quality.full.rawValue,
                    "rid should be set to \(VideoLayer.Quality.full.rawValue).",
                    file: file,
                    line: line
                )
            default:
                XCTFail()
            }

            let scaleDownFactor = videoOptions.codec.isSVC
                ? 1
                : try XCTUnwrap(sendEncoding.scaleResolutionDownBy?.intValue)
            XCTAssertEqual(
                sendEncoding.maxFramerate?.intValue,
                videoOptions.frameRate,
                "frameRate should be set to \(videoOptions.frameRate).",
                file: file,
                line: line
            )
            XCTAssertEqual(
                sendEncoding.maxBitrateBps?.intValue,
                videoOptions.bitrate / scaleDownFactor,
                "bitrate should be set to \(videoOptions.bitrate / scaleDownFactor).",
                file: file,
                line: line
            )
            if videoOptions.codec.isSVC {
                XCTAssertNil(
                    sendEncoding.scaleResolutionDownBy,
                    "scaleDownFactor should not be set.",
                    file: file,
                    line: line
                )
                XCTAssertEqual(
                    sendEncoding.scalabilityMode,
                    videoOptions.capturingLayers.scalabilityMode,
                    "scalability mode should be set to \(videoOptions.capturingLayers.scalabilityMode).",
                    file: file,
                    line: line
                )
            } else {
                XCTAssertEqual(
                    sendEncoding.scaleResolutionDownBy?.intValue,
                    scaleDownFactor,
                    "scaleDownFactor should be set to \(scaleDownFactor).",
                    file: file,
                    line: line
                )
                XCTAssertNil(
                    sendEncoding.scalabilityMode,
                    "scalability mode should not be set.",
                    file: file,
                    line: line
                )
            }
        }
    }
}
