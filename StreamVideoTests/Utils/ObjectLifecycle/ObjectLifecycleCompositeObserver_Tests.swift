//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleCompositeObserver_Tests:
    XCTestCase,
    @unchecked Sendable {

    private var observerA: SpyLifecycleObserver!
    private var observerB: SpyLifecycleObserver!
    private var subject: ObjectLifecycle.CompositeObserver!

    override func setUp() {
        super.setUp()
        observerA = .init()
        observerB = .init()
        subject = .init([observerA, observerB])
    }

    override func tearDown() {
        subject = nil
        observerA = nil
        observerB = nil
        super.tearDown()
    }

    func test_record_whenCalled_forwardsEventToAllObservers() {
        let event = ObjectLifecycle.Event(
            transition: .initialized,
            typeName: "TypeA",
            instanceId: "id",
            timestamp: .distantPast,
            metadata: [:]
        )

        subject.record(event)

        XCTAssertEqual(observerA.events, [event])
        XCTAssertEqual(observerB.events, [event])
    }

    func test_init_whenUsingVariadicInitializer_createsCompositeObserver() {
        let subject = ObjectLifecycle.CompositeObserver(observerA, observerB)
        let event = ObjectLifecycle.Event(
            transition: .initialized,
            typeName: "TypeA",
            instanceId: "id",
            timestamp: .distantPast,
            metadata: [:]
        )

        subject.record(event)

        XCTAssertEqual(observerA.events, [event])
        XCTAssertEqual(observerB.events, [event])
    }
}

private final class SpyLifecycleObserver:
    ObjectLifecycle.Observing,
    @unchecked Sendable {

    private(set) var events: [ObjectLifecycle.Event] = []

    func record(_ event: ObjectLifecycle.Event) {
        events.append(event)
    }
}
