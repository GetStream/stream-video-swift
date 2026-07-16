//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class SFUWebSocket_Tests: XCTestCase, @unchecked Sendable {

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
