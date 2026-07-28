//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class CoordinatorWebSocket_Tests: XCTestCase, @unchecked Sendable {

    func test_connectionFailure_reconnectsAutomatically() async {
        let eventNotificationCenter = DefaultEventNotificationCenter()
        let subject = CoordinatorWebSocket(
            url: URL(string: "ws://127.0.0.1:1")!,
            eventNotificationCenter: eventNotificationCenter,
            sessionConfiguration: .ephemeral,
            connectPayloadProvider: { nil },
            hasActiveCall: { true }
        )
        let reconnected = expectation(description: "WebSocket reconnects")

        var connectingCount = 0
        let cancellable = subject
            .connectionStatePublisher
            .sink {
                guard $0 == .connecting else { return }
                connectingCount += 1
                if connectingCount == 2 {
                    reconnected.fulfill()
                }
            }

        subject.connect()
        await fulfillment(of: [reconnected], timeout: defaultTimeout)
        await subject.disconnect()

        XCTAssertEqual(connectingCount, 2)
        cancellable.cancel()
    }

    func test_callKitReconnectionPolicy_reflectsActiveCall() {
        XCTAssertFalse(
            CallKitReconnectionPolicy { false }.canBeReconnected()
        )
        XCTAssertTrue(
            CallKitReconnectionPolicy { true }.canBeReconnected()
        )
    }

    func test_connectionStatus_tokenErrors_mapsToConnecting() {
        for code in [2, 40, 41, 42, 43] {
            let error = ClientError(
                with: APIError(
                    code: code,
                    message: "token error",
                    statusCode: 401
                )
            )
            let state = WebSocketConnectionState.disconnected(
                source: .serverInitiated(error: error)
            )

            XCTAssertEqual(
                ConnectionStatus(
                    videoWebSocketConnectionState: state
                ),
                .connecting,
                "APIError code \(code)"
            )
        }
    }

    func test_connectionStatus_automaticReconnection_mapsToConnecting() {
        let state = WebSocketConnectionState.disconnected(
            source: .systemInitiated
        )

        XCTAssertEqual(
            ConnectionStatus(
                videoWebSocketConnectionState: state
            ),
            .connecting
        )
    }

    func test_connectionStatus_nonRecoverableError_preservesError() {
        let error = ClientError(
            with: APIError(
                code: 100,
                message: "non-recoverable",
                statusCode: 400
            )
        )
        let state = WebSocketConnectionState.disconnected(
            source: .serverInitiated(error: error)
        )

        guard case let .disconnected(receivedError) =
            ConnectionStatus(
                videoWebSocketConnectionState: state
            )
        else {
            return XCTFail("Expected a disconnected status.")
        }

        XCTAssertTrue(receivedError === error)
    }
}
