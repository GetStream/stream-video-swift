//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleEvent_Tests: XCTestCase, @unchecked Sendable {

    func test_equatable_whenEventsMatch_returnsTrue() {
        let timestamp = Date(timeIntervalSince1970: 1_234)

        let lhs = ObjectLifecycle.Event(
            transition: .initialized,
            typeName: "TypeA",
            instanceId: "id-1",
            timestamp: timestamp,
            metadata: ["key": "value"]
        )
        let rhs = ObjectLifecycle.Event(
            transition: .initialized,
            typeName: "TypeA",
            instanceId: "id-1",
            timestamp: timestamp,
            metadata: ["key": "value"]
        )

        XCTAssertEqual(lhs, rhs)
    }

    func test_equatable_whenEventsDiffer_returnsFalse() {
        let timestamp = Date(timeIntervalSince1970: 1_234)

        let lhs = ObjectLifecycle.Event(
            transition: .initialized,
            typeName: "TypeA",
            instanceId: "id-1",
            timestamp: timestamp,
            metadata: [:]
        )
        let rhs = ObjectLifecycle.Event(
            transition: .deinitialized,
            typeName: "TypeA",
            instanceId: "id-1",
            timestamp: timestamp,
            metadata: [:]
        )

        XCTAssertNotEqual(lhs, rhs)
    }
}
