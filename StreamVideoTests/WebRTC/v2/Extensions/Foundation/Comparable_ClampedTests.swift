//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ComparableClampedTests: XCTestCase, @unchecked Sendable {

    func test_clamped_withinBounds_returnsSameValue() {
        let value = 15
        let clampedValue = value.clamped(to: 10...20)
        XCTAssertEqual(clampedValue, 15)
    }

    func test_clamped_belowLowerBound_returnsLowerBound() {
        let value = 5
        let clampedValue = value.clamped(to: 10...20)
        XCTAssertEqual(clampedValue, 10)
    }

    func test_clamped_aboveUpperBound_returnsUpperBound() {
        let value = 25
        let clampedValue = value.clamped(to: 10...20)
        XCTAssertEqual(clampedValue, 20)
    }

    func test_clamped_atLowerBound_returnsLowerBound() {
        let value = 10
        let clampedValue = value.clamped(to: 10...20)
        XCTAssertEqual(clampedValue, 10)
    }

    func test_clamped_atUpperBound_returnsUpperBound() {
        let value = 20
        let clampedValue = value.clamped(to: 10...20)
        XCTAssertEqual(clampedValue, 20)
    }

    func test_clamped_withNegativeRange_returnsClampedValue() {
        let value = -5
        let clampedValue = value.clamped(to: -10...0)
        XCTAssertEqual(clampedValue, -5)
    }

    func test_clamped_withFloatingPointValues_returnsClampedValue() {
        let value = 15.5
        let clampedValue = value.clamped(to: 10.0...20.0)
        XCTAssertEqual(clampedValue, 15.5)
    }

    func test_clamped_withFloatingPointBelowLowerBound_returnsLowerBound() {
        let value = 5.5
        let clampedValue = value.clamped(to: 10.0...20.0)
        XCTAssertEqual(clampedValue, 10.0)
    }

    func test_clamped_withFloatingPointAboveUpperBound_returnsUpperBound() {
        let value = 25.5
        let clampedValue = value.clamped(to: 10.0...20.0)
        XCTAssertEqual(clampedValue, 20.0)
    }
}
