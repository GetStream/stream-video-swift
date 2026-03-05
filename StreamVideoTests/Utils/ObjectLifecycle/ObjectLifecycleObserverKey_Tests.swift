//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleObserverKey_Tests: XCTestCase, @unchecked Sendable {

    private var previousObserver: ObjectLifecycle.Observing!

    override func setUp() {
        super.setUp()
        previousObserver = ObjectLifecycle.ObserverKey.currentValue
    }

    override func tearDown() {
        ObjectLifecycle.ObserverKey.currentValue = previousObserver
        previousObserver = nil
        super.tearDown()
    }

    func test_currentValue_defaultsToCompositeObserver() {
        XCTAssertTrue(
            ObjectLifecycle.ObserverKey.currentValue is ObjectLifecycle.CompositeObserver
        )
    }

    func test_currentValue_whenOverridden_returnsCustomObserver() {
        let observer = ObjectLifecycle.Recorder()
        ObjectLifecycle.ObserverKey.currentValue = observer

        XCTAssertTrue(ObjectLifecycle.ObserverKey.currentValue === observer)
    }
}
