//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class CoordinatorWebSocket_Tests: XCTestCase, @unchecked Sendable {

    func test_connectionFailure_reconnectsAutomatically() {
        let internetAvailable = expectation(
            forNotification: .init("io.getstream.core.internetConnectionAvailability"),
            object: nil,
            handler: {
                ($0.userInfo?["internetConnectionStatus"] as? StreamCore.InternetConnectionStatus)?
                    .isAvailable == true
            }
        )
        let eventNotificationCenter = DefaultEventNotificationCenter()
        let subject = CoordinatorWebSocket(
            url: URL(string: "ws://127.0.0.1:1")!,
            eventNotificationCenter: eventNotificationCenter,
            sessionConfiguration: .ephemeral,
            connectPayloadProvider: { nil },
            hasActiveCall: { true }
        )
        let reconnected = expectation(description: "WebSocket reconnects")
        let disconnected = expectation(description: "WebSocket disconnects")

        var connectingCount = 0
        let cancellable = subject
            .connectionStatePublisher
            .sink {
                guard $0 == .connecting else { return }
                connectingCount += 1
                if connectingCount == 2 {
                    reconnected.fulfill()
                    subject.disconnect {
                        disconnected.fulfill()
                    }
                }
            }

        wait(for: [internetAvailable], timeout: defaultTimeout)
        subject.connect()
        wait(for: [reconnected, disconnected], timeout: defaultTimeout)

        XCTAssertEqual(connectingCount, 2)
        cancellable.cancel()
    }
}
