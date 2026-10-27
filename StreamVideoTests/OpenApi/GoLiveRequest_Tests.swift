//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class GoLiveRequest_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - init(startRtmpBroadcasts:)

    // Deprecated so that calling the deprecated init does not warn.
    @available(*, deprecated)
    func test_initWithStartRtmpBroadcasts_encodesOtherFieldsOnly() throws {
        let subject = GoLiveRequest(startHls: true, startRtmpBroadcasts: true)

        let json = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder.default.encode(subject)
            ) as? [String: Any]
        )

        XCTAssertNil(subject.startRtmpBroadcasts)
        XCTAssertEqual(json["start_hls"] as? Bool, true)
        XCTAssertNil(json["start_rtmp_broadcasts"])
    }
}
