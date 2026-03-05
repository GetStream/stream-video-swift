//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ObjectLifecycleTransition_Tests: XCTestCase, @unchecked Sendable {

    func test_rawValue_whenInitializedTransition_returnsInitialized() {
        XCTAssertEqual(ObjectLifecycle.Transition.initialized.rawValue, "initialized")
    }

    func test_rawValue_whenMetadataUpdatedTransition_returnsMetadataUpdated() {
        XCTAssertEqual(
            ObjectLifecycle.Transition.metadataUpdated.rawValue,
            "metadataUpdated"
        )
    }

    func test_rawValue_whenDeinitializedTransition_returnsDeinitialized() {
        XCTAssertEqual(
            ObjectLifecycle.Transition.deinitialized.rawValue,
            "deinitialized"
        )
    }
}
