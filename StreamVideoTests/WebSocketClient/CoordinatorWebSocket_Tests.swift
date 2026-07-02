//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
@testable import StreamVideo
import XCTest

final class CoordinatorWebSocket_Tests: XCTestCase, @unchecked Sendable {

    // `VideoWebSocketConnectionState` (a StreamVideo alias) is used instead of
    // the bare name, which is ambiguous here since StreamCore is imported.

    func test_map_initializedConnectingAuthenticating() {
        XCTAssertEqual(VideoWebSocketConnectionState(.initialized), .initialized)
        XCTAssertEqual(VideoWebSocketConnectionState(.connecting), .connecting)
        XCTAssertEqual(VideoWebSocketConnectionState(.authenticating), .authenticating)
    }

    func test_map_connected_carriesConnectionId() {
        let subject = VideoWebSocketConnectionState(
            .connected(healthCheckInfo: .init(connectionId: "the-connection-id", participantCount: nil))
        )

        guard case let .connected(info) = subject else {
            return XCTFail("Expected .connected")
        }
        XCTAssertEqual(info.coordinatorHealthCheck?.connectionId, "the-connection-id")
    }

    func test_map_disconnectionSources() {
        XCTAssertEqual(
            VideoWebSocketConnectionState(.disconnected(source: .userInitiated)),
            .disconnected(source: .userInitiated)
        )
        XCTAssertEqual(
            VideoWebSocketConnectionState(.disconnected(source: .noPongReceived)),
            .disconnected(source: .noPongReceived)
        )
        XCTAssertEqual(
            VideoWebSocketConnectionState(.disconnected(source: .systemInitiated)),
            .disconnected(source: .systemInitiated)
        )
        // StreamCore's `.timeout` has no video equivalent → maps to systemInitiated.
        XCTAssertEqual(
            VideoWebSocketConnectionState(.disconnected(source: .timeout(from: .connecting))),
            .disconnected(source: .systemInitiated)
        )
    }
}
