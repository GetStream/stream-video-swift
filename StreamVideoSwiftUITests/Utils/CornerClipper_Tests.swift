//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import SwiftUI
@testable import StreamVideoSwiftUI
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class CornerClipper_Tests: XCTestCase {

    // MARK: - Single Corner

    func test_cornerClipper_cornerRadiusTopLeft() {
        assertCornerRadius(corners: [.topLeft])
    }

    func test_cornerClipper_cornerRadiusTopRight() {
        assertCornerRadius(corners: [.topRight])
    }

    func test_cornerClipper_cornerRadiusBottomLeft() {
        assertCornerRadius(corners: [.bottomLeft])
    }

    func test_cornerClipper_cornerRadiusBottomRight() {
        assertCornerRadius(corners: [.bottomRight])
    }

    // MARK: - Double Corner

    func test_cornerClipper_cornerRadiusTop() {
        assertCornerRadius(corners: [.topLeft, .topRight])
    }

    func test_cornerClipper_cornerRadiusBottom() {
        assertCornerRadius(corners: [.bottomLeft, .bottomRight])
    }

    func test_cornerClipper_cornerRadiusLeading() {
        assertCornerRadius(corners: [.topLeft, .bottomLeft])
    }

    func test_cornerClipper_cornerRadiusTrailing() {
        assertCornerRadius(corners: [.topRight, .bottomRight])
    }

    func test_cornerClipper_cornerRadiusLeadingDiagonal() {
        assertCornerRadius(corners: [.topLeft, .bottomRight])
    }

    func test_cornerClipper_cornerRadiusTrailingDiagonal() {
        assertCornerRadius(corners: [.topRight, .bottomLeft])
    }

    // MARK: - All Corners

    func test_cornerClipper_allCorners() {
        assertCornerRadius(corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
    }

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
            size: .init(width: 100, height: 100),
            line: line,
            file: file,
            function: function
        )
    }
}
