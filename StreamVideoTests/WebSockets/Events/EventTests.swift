//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class EventTests: XCTestCase, @unchecked Sendable {

    private lazy var customVideoEvent: CustomVideoEvent! = CustomVideoEvent(
        callCid: "123",
        createdAt: Date(),
        custom: [:],
        user: .init(
            blockedUserIds: [],
            createdAt: Date(),
            custom: [:],
            id: "456",
            language: "en",
            role: "admin",
            teams: [],
            updatedAt: Date()
        )
    )

    override func tearDown() {
        customVideoEvent = nil
        super.tearDown()
    }

    // MARK: - unwrap

    func test_unwrap_isVideoEvent_returnsExpected() {
        let videoEvent = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: .init()
            )
        )

        XCTAssertEqual(videoEvent.unwrap(), videoEvent)
    }

    func test_unwrap_isWrappedCoordinatorEvent_returnsExpected() {
        let videoEvent = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: .init()
            )
        )
        let wrappedEvent = WrappedEvent.coordinatorEvent(videoEvent)

        XCTAssertEqual(wrappedEvent.unwrap(), videoEvent)
    }

    func test_unwrap_isWrappedButNotCoordinatorEvent_returnsExpected() {
        struct TestEvent: Event {}
        let wrappedEvent = WrappedEvent.internalEvent(TestEvent())

        XCTAssertNil(wrappedEvent.unwrap())
    }

    func test_unwrap_isUnknownEvent_returnsExpected() {
        struct TestEvent: Event {}

        let subject = TestEvent()

        XCTAssertNil(subject.unwrap())
    }

    // MARK: - forCall

    func test_forCall_isWSCallEventWithSameCID_returnsTrue() {
        let videoEvent = VideoEvent.typeCustomVideoEvent(customVideoEvent)

        XCTAssertTrue(videoEvent.forCall(cid: "123"))
    }

    func test_forCall_isWSCallEventWithDifferentCID_returnsFalse() {
        let videoEvent = VideoEvent.typeCustomVideoEvent(customVideoEvent)

        XCTAssertFalse(videoEvent.forCall(cid: "789"))
    }

    func test_forCall_isNotWSCallEvent_returnsFalse() {
        let subject = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: Date()
            )
        )

        XCTAssertFalse(subject.forCall(cid: "123"))
    }

    func test_forCall_isNotVideoEvent_returnsFalse() {
        struct TestEvent: Event {}

        let subject = TestEvent()

        XCTAssertFalse(subject.forCall(cid: "123"))
    }
}
