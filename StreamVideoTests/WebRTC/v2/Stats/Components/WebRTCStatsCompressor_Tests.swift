//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCStatsCompressor_Tests: XCTestCase, @unchecked Sendable {

    private var subject: WebRTCStatsCompressor! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_compress_concurrentCall_completes() async throws {
        let publisherRawStats = try await RTCStatisticsReport.dummy()
        let subsciberRawStats = try await RTCStatisticsReport.dummy()
        XCTAssertFalse(publisherRawStats.statistics.isEmpty)
        XCTAssertFalse(subsciberRawStats.statistics.isEmpty)

        DispatchQueue.concurrentPerform(iterations: 100_000) { iteration in
            _ = subject.compress(
                makeReport(
                    publisherRawStats: publisherRawStats,
                    subscriberRawStats: subsciberRawStats,
                    iteration: iteration
                )
            )
        }
    }

    // MARK: - Private Helpers

    private func makeReport(
        publisherRawStats: RTCStatisticsReport?,
        subscriberRawStats: RTCStatisticsReport?,
        iteration: Int
    ) -> CallStatsReport {
        .dummy(
            publisherRawStats: publisherRawStats,
            subscriberRawStats: subscriberRawStats,
            timestamp: Double(iteration)
        )
    }
}
