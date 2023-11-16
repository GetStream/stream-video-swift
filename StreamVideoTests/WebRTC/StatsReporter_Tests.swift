//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class StatsReporter_Tests: XCTestCase {

    func test_statsReport_publisher() {
        // Given
        let first = makeStats(isPublisher: true)
        let second = makeStats(isPublisher: false)
        let third = makeStats(
            bytesSent: 20,
            bytesReceived: 30,
            currentRoundTripTime: 15,
            frameWidth: 1920,
            frameHeight: 1280,
            isPublisher: true
        )
        let stats = ParticipantsStats(
            report: ["first": first, "second": second, "third": third]
        )
        
        // When
        let report = StatsReporter.publisherStats(from: stats, timestamp: 123)
        
        // Then
        XCTAssertEqual(report.totalBytesSent, 30)
        XCTAssertEqual(report.totalBytesReceived, 45)
        XCTAssertEqual(report.averageJitterInMs, 0.005)
        XCTAssertEqual(report.averageRoundTripTimeInMs, 10)
        XCTAssertEqual(report.qualityLimitationReasons, "")
        XCTAssertEqual(report.highestFrameWidth, 1920)
        XCTAssertEqual(report.highestFrameHeight, 1280)
        XCTAssertEqual(report.highestFramesPerSecond, 30)
        XCTAssertEqual(report.timestamp, 123)
    }
    
    func test_statsReport_subscriber() {
        // Given
        let first = makeStats(isPublisher: false)
        let second = makeStats(isPublisher: true)
        let third = makeStats(
            bytesSent: 20,
            bytesReceived: 30,
            currentRoundTripTime: 15,
            frameWidth: 1920,
            frameHeight: 1280,
            isPublisher: false
        )
        let stats = ParticipantsStats(
            report: ["first": first, "second": second, "third": third]
        )
        
        // When
        let report = StatsReporter.subscriberStats(from: stats, timestamp: 123)
        
        // Then
        XCTAssertEqual(report.totalBytesSent, 30)
        XCTAssertEqual(report.totalBytesReceived, 45)
        XCTAssertEqual(report.averageJitterInMs, 0.005)
        XCTAssertEqual(report.averageRoundTripTimeInMs, 10)
        XCTAssertEqual(report.qualityLimitationReasons, "")
        XCTAssertEqual(report.highestFrameWidth, 1920)
        XCTAssertEqual(report.highestFrameHeight, 1280)
        XCTAssertEqual(report.highestFramesPerSecond, 30)
        XCTAssertEqual(report.timestamp, 123)
    }
    
    func test_makeBaseStats() {
        // Given
        let rawStats: [String: Any] = [
            StatsConstants.bytesSent: 10,
            StatsConstants.bytesReceived: 15,
            StatsConstants.currentRoundTripTime: 5.0,
            StatsConstants.frameWidth: 1024,
            StatsConstants.frameHeight: 720,
            StatsConstants.framesPerSecond: 30,
            StatsConstants.jitter: 0.005,
            StatsConstants.kind: "video",
            StatsConstants.qualityLimitationReason: "",
            StatsConstants.rid: "f",
            StatsConstants.ssrc: 1234
        ]
        
        // When
        let stats = StatsReporter.makeBaseStats(
            from: rawStats,
            codec: "video/h264",
            index: 0
        )
        
        // Then
        XCTAssertEqual(stats.bytesSent, 10)
        XCTAssertEqual(stats.bytesReceived, 15)
        XCTAssertEqual(stats.jitter, 0.005)
        XCTAssertEqual(stats.currentRoundTripTime, 5)
        XCTAssertEqual(stats.qualityLimitationReason, "")
        XCTAssertEqual(stats.frameWidth, 1024)
        XCTAssertEqual(stats.frameHeight, 720)
        XCTAssertEqual(stats.kind, "video")
        XCTAssertEqual(stats.rid, "f")
        XCTAssertEqual(stats.codec, "video/h264")
        XCTAssertEqual(stats.ssrc, 1234)
        XCTAssertEqual(stats.isPublisher, true)
    }
    
    //MARK: - private
    
    private func makeStats(
        bytesSent: Int = 10,
        bytesReceived: Int = 15,
        currentRoundTripTime: Double = 5,
        frameWidth: Int = 1024,
        frameHeight: Int = 720,
        framesPerSecond: Int = 30,
        jitter: Double = 0.005,
        isPublisher: Bool
    ) -> BaseStats {
        let first = BaseStats(
            bytesSent: bytesSent,
            bytesReceived: bytesReceived,
            codec: "video/h264",
            currentRoundTripTime: currentRoundTripTime,
            frameWidth: frameWidth,
            frameHeight: frameHeight,
            framesPerSecond: framesPerSecond,
            jitter: jitter,
            kind: "video",
            qualityLimitationReason: "",
            rid: "f",
            ssrc: 1234,
            isPublisher: isPublisher
        )
        return first
    }

}
