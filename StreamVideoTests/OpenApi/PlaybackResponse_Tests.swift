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

    // MARK: - Private helpers

    private func decode(reason: String) throws -> PlaybackResponse {
        let json = """
        {
            "type": "hls",
            "playlist_url": "https://example.com/live.m3u8",
            "reason": "\(reason)"
        }
        """
        return try JSONDecoder.streamCore.decode(
            PlaybackResponse.self,
            from: Data(json.utf8)
        )
    }
}
