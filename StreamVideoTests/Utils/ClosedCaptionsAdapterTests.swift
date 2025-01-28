//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

@MainActor
final class ClosedCaptionsAdapterTests: XCTestCase {
    private lazy var call: MockCall! = MockCall()
    private lazy var subject: ClosedCaptionsAdapter! = .init(call)

    override func tearDown() {
        call = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_givenDefaultParameters_whenInitialized_thenPropertiesAreSet() {
        XCTAssertEqual(subject.capacity, 2)
        XCTAssertEqual(subject.itemPresentationDuration, 2.7)
    }

    func test_init_givenCustomParameters_whenInitialized_thenPropertiesAreSet() {
        subject = ClosedCaptionsAdapter(call, capacity: 5, itemPresentationDuration: 3.5)
        XCTAssertEqual(subject.capacity, 5)
        XCTAssertEqual(subject.itemPresentationDuration, 3.5)
    }
}
