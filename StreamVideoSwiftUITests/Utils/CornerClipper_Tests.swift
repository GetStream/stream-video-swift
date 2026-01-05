//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

final class CornerClipper_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Single Corner

    @MainActor
    func test_cornerClipper_cornerRadiusTopLeft() {
        assertCornerRadius(corners: [.topLeft])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusTopRight() {
        assertCornerRadius(corners: [.topRight])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusBottomLeft() {
        assertCornerRadius(corners: [.bottomLeft])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusBottomRight() {
        assertCornerRadius(corners: [.bottomRight])
    }

    // MARK: - Double Corner

    @MainActor
    func test_cornerClipper_cornerRadiusTop() {
        assertCornerRadius(corners: [.topLeft, .topRight])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusBottom() {
        assertCornerRadius(corners: [.bottomLeft, .bottomRight])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusLeading() {
        assertCornerRadius(corners: [.topLeft, .bottomLeft])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusTrailing() {
        assertCornerRadius(corners: [.topRight, .bottomRight])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusLeadingDiagonal() {
        assertCornerRadius(corners: [.topLeft, .bottomRight])
    }

    @MainActor
    func test_cornerClipper_cornerRadiusTrailingDiagonal() {
        assertCornerRadius(corners: [.topRight, .bottomLeft])
    }

    // MARK: - All Corners

    @MainActor
    func test_cornerClipper_allCorners() {
        assertCornerRadius(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
    }

    @MainActor
    private func assertCornerRadius(
        _ radius: CGFloat = 24,
        corners: UIRectCorner,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        AssertSnapshot(
            Text("Hello World!")
                .frame(width: 100, height: 100)
                .cornerRadius(
                    radius,
                    corners: corners,
                    backgroundColor: .red
                ),
            variants: snapshotVariants,
            size: .init(width: 100, height: 100),
            line: line,
            file: file,
            function: function
        )
    }
}
