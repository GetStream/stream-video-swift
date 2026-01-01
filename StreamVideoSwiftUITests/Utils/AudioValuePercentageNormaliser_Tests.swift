//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class AudioValuePercentageNormaliser_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: AudioValuePercentageNormaliser! = .init()

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_valueRangeIsSetCorrectly() {
        XCTAssertEqual(subject.valueRange, (-50...0))
    }

    func test_init_deltaIsCalculatedCorrectly() {
        XCTAssertEqual(subject.delta, 50)
    }

    // MARK: - normalise(_:)

    func test_normalise_valueLessThanLowerBound_returnsExpectedResult() {
        XCTAssertEqual(subject.normalise(-60), 0)
    }

    func test_normalise_valueEqualToLowerBound_returnsExpectedResult() {
        XCTAssertEqual(subject.normalise(-50), 0)
    }

    func test_normalise_valueGreaterThanLowerBoundLessThanUpperBound_returnsExpectedResult() {
        XCTAssertEqual(subject.normalise(-25), 0.5)
    }

    func test_normalise_valueGreaterThanUpperBound_returnsExpectedResult() {
        XCTAssertEqual(subject.normalise(10), 1)
    }
}
