//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class JoinCallRequest_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - encode

    func test_encode_withPlaybackCapabilities_encodesPlaybackCapabilitiesKey() throws {
        let subject = JoinCallRequest(
            location: "FRA",
            playbackCapabilities: ["hls"]
        )

        let json = try encode(subject)

        XCTAssertEqual(json["playback_capabilities"] as? [String], ["hls"])
        XCTAssertEqual(json["location"] as? String, "FRA")
    }

    func test_encode_withoutPlaybackCapabilities_omitsPlaybackCapabilitiesKey() throws {
        let subject = JoinCallRequest(location: "FRA")

        let json = try encode(subject)

        XCTAssertNil(json["playback_capabilities"])
    }

    func test_encode_withUnifiedSessionId_encodesUnifiedSessionIdKey() throws {
        let subject = JoinCallRequest(
            location: "FRA",
            unifiedSessionId: "unified-id"
        )

        let json = try encode(subject)

        XCTAssertEqual(json["unified_session_id"] as? String, "unified-id")
    }

    func test_encode_withoutUnifiedSessionId_omitsUnifiedSessionIdKey() throws {
        let subject = JoinCallRequest(location: "FRA")

        let json = try encode(subject)

        XCTAssertNil(json["unified_session_id"])
    }

    // MARK: - Private helpers

    private func encode(_ subject: JoinCallRequest) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder.default.encode(subject)
            ) as? [String: Any]
        )
    }
}
