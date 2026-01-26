//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class VisibilityThresholdModifier_Tests: XCTestCase, @unchecked Sendable {

    private lazy var bounds: CGRect! = CGRect(x: 0, y: 0, width: 100, height: 100)

    override func tearDown() async throws {
        bounds = nil
        try await super.tearDown()
    }

    func test_visibilityFullyInsideBounds() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: 10, y: 10, width: 80, height: 80),
            expected: (true, true)
        )
    }

    func test_visibilityPartiallyOutsideBoundsTopLeft() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: -10, y: -10, width: 60, height: 60),
            expected: (true, true)
        )
    }

    func test_visibilityCompletelyOutsideBoundsTopLeft() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: -110, y: -110, width: 60, height: 60),
            expected: (false, false)
        )
    }

    func test_visibilityAtThreshold() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: 10, y: 10, width: 40, height: 40),
            expected: (true, true)
        )
    }

    func test_visibilityBelowThreshold() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.8,
            viewRect: CGRect(x: -35, y: -35, width: 40, height: 40),
            expected: (false, false)
        )
    }

    func test_visibilityPartiallyOutsideBoundsLeftFullyVisibleVertically() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: -10, y: 0, width: 60, height: 100),
            expected: (true, true)
        )
    }

    func test_visibilityCompletelyOutsideBoundsBottomFullyVisibleHorizontally() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: 0, y: 110, width: 100, height: 60),
            expected: (false, true)
        )
    }

    func test_visibilityCompletelyOutsideBoundsRightFullyVisibleVertically() {
        assertVisibilityCalculations(
            in: bounds,
            threshold: 0.5,
            viewRect: CGRect(x: 110, y: 0, width: 60, height: 100),
            expected: (true, false)
        )
    }

    // MARK: - Private Helpers

    @MainActor
    private func assertVisibilityCalculations(
        in bounds: CGRect,
        threshold: CGFloat,
        viewRect: CGRect,
        expected: (Bool, Bool),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let modifier = VisibilityThresholdModifier(in: bounds, threshold: threshold) { _ in }

        let (vertical, horizontal) = modifier.calculateVisibilityInBothAxis(in: viewRect)

        XCTAssertEqual(expected.0, vertical, "Vertical visibility doesn't match!", file: file, line: line)
        XCTAssertEqual(expected.1, horizontal, "Horizontal visibility doesn't", file: file, line: line)
    }
}
