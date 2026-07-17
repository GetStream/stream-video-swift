//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class SFUWebSocket_Tests: XCTestCase, @unchecked Sendable {

    func test_closeCodeProvider_noPongReceived_returns4001() {
        let subject = SFUWebSocketCloseCodeProvider()

        let closeCode = subject.closeCode(
            for: .disconnection(source: .noPongReceived)
        )

        XCTAssertEqual(closeCode.rawValue, 4001)
    }

    func test_closeCodeProvider_reconfiguration_returns4002() {
        let subject = SFUWebSocketCloseCodeProvider()

        let closeCode = subject.closeCode(for: .reconfiguration)

        XCTAssertEqual(closeCode.rawValue, 4002)
    }

    func test_closeCodeProvider_disconnection_returnsNormalClosure() {
        let subject = SFUWebSocketCloseCodeProvider()

        let closeCode = subject.closeCode(
            for: .disconnection(source: .systemInitiated)
        )

        XCTAssertEqual(closeCode, .normalClosure)
    }

    func test_closeCodeProvider_explicitCode_returnsRequestedCode() {
        let subject = SFUWebSocketCloseCodeProvider()

        let closeCode = subject.closeCode(
            for: .explicit(code: .goingAway, source: .userInitiated)
        )

        XCTAssertEqual(closeCode, .goingAway)
    }

    func test_inject_typedPayload_publishesSamePayload() {
        let subject = SFUWebSocket(
            url: URL(string: "https://getstream.io")!,
            sessionConfiguration: .ephemeral
        )
        let expected =
            Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload
                .healthCheckResponse(.init())
        let expectation = expectation(description: "Typed SFU event")
        var received: Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload?
        let cancellable = subject.eventPublisher.sink {
            received = $0
            expectation.fulfill()
        }

        subject.inject(expected)

        wait(for: [expectation], timeout: defaultTimeout)
        XCTAssertEqual(received, expected)
        cancellable.cancel()
    }
}
