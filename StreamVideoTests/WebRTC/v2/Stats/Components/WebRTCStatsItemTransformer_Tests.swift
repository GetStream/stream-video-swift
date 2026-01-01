//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebRTCStatsItemTransformer_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Tests

    func test_encoder_transformsOutboundVideoTrack() {
        // Setup
        let stat = makeStat(type: "outbound-rtp", framesSent: 30, framesPerSecond: 15, totalEncodeTime: 1.0)
        let codecStat = makeCodecStat()
        let mediaSourceStat = makeMediaSourceStat(trackIdentifier: "track-1")
        let stats: [String: MutableRTCStatistics] = [
            "stat-1": stat,
            "codec-1": codecStat,
            "media-1": mediaSourceStat
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let trackToKindMap: [String: TrackType] = ["track-1": .video]
        let transformer = WebRTCStatsItemTransformer(mode: .encoder)

        // Act
        let items = transformer.transform((stats: report, trackToKindMap: trackToKindMap))

        // Assert
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertEqual(item.trackType, .video)
        XCTAssertEqual(item.codec.name, "VP8")
        XCTAssertEqual(item.codec.clockRate, 90000)
        XCTAssertEqual(item.codec.payloadType, 99)
        XCTAssertEqual(item.codec.fmtp, "foo")
        XCTAssertEqual(item.videoDimension.width, 640)
        XCTAssertEqual(item.videoDimension.height, 360)
        // avgFps and avgFrameTimeMs should be computed, but with no previous output, avgFps == framesSent
        XCTAssertEqual(Int(item.avgFps), 30)
        XCTAssertEqual(Int(item.avgFrameTimeMs), Int((1.0 / 30) * 1000))
    }

    func test_decoder_transformsInboundVideoTrack() {
        // Setup
        let stat = makeStat(type: "inbound-rtp", framesDecoded: 40, framesPerSecond: 20, totalDecodeTime: 2.0)
        let codecStat = makeCodecStat(mimeType: "video/H264")
        let mediaSourceStat = makeMediaSourceStat(trackIdentifier: "track-2")
        let stats: [String: MutableRTCStatistics] = [
            "stat-2": stat,
            "codec-1": codecStat,
            "media-1": mediaSourceStat
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let trackToKindMap: [String: TrackType] = ["track-2": .screenshare]
        let transformer = WebRTCStatsItemTransformer(mode: .decoder)

        // Act
        let items = transformer.transform((stats: report, trackToKindMap: trackToKindMap))

        // Assert
        XCTAssertEqual(items.count, 1)
        let item = items[0]
        XCTAssertEqual(item.trackType, .screenShare)
        XCTAssertEqual(item.codec.name, "H264")
        XCTAssertEqual(item.codec.clockRate, 90000)
        XCTAssertEqual(item.codec.payloadType, 99)
        XCTAssertEqual(item.codec.fmtp, "foo")
        XCTAssertEqual(item.videoDimension.width, 640)
        XCTAssertEqual(item.videoDimension.height, 360)
        XCTAssertEqual(Int(item.avgFps), 40)
        XCTAssertEqual(Int(item.avgFrameTimeMs), Int((2.0 / 40) * 1000))
    }

    func test_transform_returnsEmptyIfNoMatchingTrack() {
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: [:])
        let transformer = WebRTCStatsItemTransformer(mode: .encoder)
        let result = transformer.transform((stats: report, trackToKindMap: [:]))
        XCTAssertTrue(result.isEmpty)
    }

    func test_transform_filtersNonVideoInEncoderMode() {
        // Only kind == "video" should pass in encoder
        let audioStat = makeStat(type: "outbound-rtp", kind: "audio")
        let stats: [String: MutableRTCStatistics] = [
            "stat-1": audioStat
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let transformer = WebRTCStatsItemTransformer(mode: .encoder)
        let result = transformer.transform((stats: report, trackToKindMap: [:]))
        XCTAssertTrue(result.isEmpty)
    }

    func test_transform_filtersNonVideoInDecoderMode() {
        // Only kind == "video" should pass in decoder
        let nonVideoStat = makeStat(type: "inbound-rtp", kind: "audio")
        let stats: [String: MutableRTCStatistics] = [
            "stat-1": nonVideoStat
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let transformer = WebRTCStatsItemTransformer(mode: .decoder)
        let result = transformer.transform((stats: report, trackToKindMap: [:]))
        XCTAssertTrue(result.isEmpty)
    }

    func test_transform_returnsEmptyIfMappingMissing() {
        let stat = makeStat(type: "outbound-rtp")
        let codecStat = makeCodecStat()
        let mediaSourceStat = makeMediaSourceStat(trackIdentifier: "not-in-map")
        let stats: [String: MutableRTCStatistics] = [
            "stat-1": stat,
            "codec-1": codecStat,
            "media-1": mediaSourceStat
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let transformer = WebRTCStatsItemTransformer(mode: .encoder)
        // trackToKindMap is empty; so result is empty
        let result = transformer.transform((stats: report, trackToKindMap: [:]))
        XCTAssertTrue(result.isEmpty)
    }

    func test_decoder_multipleTracks_selectsLargestArea() {
        // stat-2 has bigger area
        let stat1 = makeStat(
            type: "inbound-rtp",
            framesDecoded: 10,
            frameWidth: 320,
            frameHeight: 240,
            mediaSourceId: "media-1"
        )
        let stat2 = makeStat(
            type: "inbound-rtp",
            framesDecoded: 10,
            frameWidth: 1920,
            frameHeight: 1080,
            mediaSourceId: "media-2"
        )
        let codecStat = makeCodecStat()
        let mediaSourceStat1 = makeMediaSourceStat(trackIdentifier: "track-1")
        let mediaSourceStat2 = makeMediaSourceStat(trackIdentifier: "track-2")
        let stats: [String: MutableRTCStatistics] = [
            "stat-1": stat1,
            "stat-2": stat2,
            "codec-1": codecStat,
            "media-1": mediaSourceStat1,
            "media-2": mediaSourceStat2
        ]
        let report = MutableRTCStatisticsReport(timestamp: 0, statistics: stats)
        let trackToKindMap: [String: TrackType] = [
            "track-1": .video,
            "track-2": .screenshare
        ]
        let transformer = WebRTCStatsItemTransformer(mode: .decoder)
        let items = transformer.transform((stats: report, trackToKindMap: trackToKindMap))
        XCTAssertEqual(items.count, 1)
        XCTAssertEqual(items.first?.videoDimension.width, 1920)
        XCTAssertEqual(items.first?.videoDimension.height, 1080)
    }

    // MARK: - Private Helpers

    private func makeStat(
        type: String,
        kind: String = "video",
        codecId: String = "codec-1",
        framesSent: Int = 0,
        framesDecoded: Int = 0,
        framesPerSecond: Int = 0,
        totalEncodeTime: Double = 0,
        totalDecodeTime: Double = 0,
        frameWidth: Int = 640,
        frameHeight: Int = 360,
        mediaSourceId: String = "media-1",
        trackIdentifier: String = "track-1",
        targetBitrate: Int? = nil
    ) -> MutableRTCStatistics {
        var values: [String: RawJSON] = [
            "kind": .string(kind),
            "codecId": .string(codecId),
            "framesSent": .number(Double(framesSent)),
            "framesDecoded": .number(Double(framesDecoded)),
            "framesPerSecond": .number(Double(framesPerSecond)),
            "totalEncodeTime": .number(totalEncodeTime),
            "totalDecodeTime": .number(totalDecodeTime),
            "frameWidth": .number(Double(frameWidth)),
            "frameHeight": .number(Double(frameHeight)),
            "mediaSourceId": .string(mediaSourceId)
        ]
        if let target = targetBitrate {
            values["targetBitrate"] = .number(Double(target))
        }
        return MutableRTCStatistics(
            timestamp: 0,
            type: type,
            values: values
        )
    }

    private func makeCodecStat(
        mimeType: String = "video/VP8",
        clockRate: Int = 90000,
        payloadType: Int = 99,
        sdpFmtpLine: String = "foo"
    ) -> MutableRTCStatistics {
        MutableRTCStatistics(
            timestamp: 0,
            type: "codec",
            values: [
                "mimeType": .string(mimeType),
                "clockRate": .number(Double(clockRate)),
                "payloadType": .number(Double(payloadType)),
                "sdpFmtpLine": .string(sdpFmtpLine)
            ]
        )
    }

    private func makeMediaSourceStat(
        trackIdentifier: String = "track-1"
    ) -> MutableRTCStatistics {
        MutableRTCStatistics(
            timestamp: 0,
            type: "media-source",
            values: [
                "trackIdentifier": .string(trackIdentifier)
            ]
        )
    }
}
