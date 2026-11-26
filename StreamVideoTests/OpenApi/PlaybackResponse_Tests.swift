//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
@preconcurrency import XCTest

final class PlaybackResponse_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - decode

    func test_decode_percentageGrant_exposesPlaybackValues() throws {
        let subject = try decode(reason: "percentage")

        XCTAssertEqual(subject.type, .hls)
        XCTAssertEqual(subject.playlistUrl, "https://example.com/live.m3u8")
        XCTAssertEqual(subject.reason, .percentage)
    }

    func test_decode_hintGrant_exposesHintReason() throws {
        let subject = try decode(reason: "hint")

        XCTAssertEqual(subject.reason, .hint)
    }

    func test_decode_withStatsToken_exposesStatsToken() throws {
        let subject = try decode(reason: "percentage", statsToken: "jwt")

        XCTAssertEqual(subject.statsToken, "jwt")
    }

    func test_decode_withoutStatsToken_hasNoStatsToken() throws {
        let subject = try decode(reason: "percentage")

        XCTAssertNil(subject.statsToken)
    }

    func test_decode_unknownTypeAndReason_mapsToUnknown() throws {
        let subject = try decode(type: "future-type", reason: "future-reason")

        XCTAssertEqual(subject.type, .unknown)
        XCTAssertEqual(subject.reason, .unknown)
    }

    // MARK: - Private helpers

    private func decode(
        type: String = "hls",
        reason: String,
        statsToken: String? = nil
    ) throws -> PlaybackResponse {
        let token = statsToken.map { ", \"stats_token\": \"\($0)\"" } ?? ""
        let json = """
        {
            "type": "\(type)",
            "playlist_url": "https://example.com/live.m3u8",
            "reason": "\(reason)"\(token)
        }
        """
        return try JSONDecoder.streamCore.decode(
            PlaybackResponse.self,
            from: Data(json.utf8)
        )
    }
}
