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

    // MARK: - Private helpers

    private func encode(_ subject: JoinCallRequest) throws -> [String: Any] {
        try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder.default.encode(subject)
            ) as? [String: Any]
        )
    }
}
