//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleInjectedValues_Tests: XCTestCase, @unchecked Sendable {

    private var previousObserver: ObjectLifecycle.Observing!

    override func setUp() {
        super.setUp()
        previousObserver = InjectedValues[\.objectLifecycleObserver]
    }

    override func tearDown() {
        InjectedValues[\.objectLifecycleObserver] = previousObserver
        previousObserver = nil
        super.tearDown()
    }

    func test_objectLifecycleObserver_whenOverridden_returnsInjectedObserver() {
        let observer = ObjectLifecycle.Recorder()

        InjectedValues[\.objectLifecycleObserver] = observer

        XCTAssertTrue(InjectedValues[\.objectLifecycleObserver] === observer)
    }
}
