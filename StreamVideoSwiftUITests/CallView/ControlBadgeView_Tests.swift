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
final class ControlBadgeView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    func test_controlBadgeView_valueIsLessThanZero_viewWasConfiguredCorrectly() throws {
        assertSubject { makeSubject(-10) }
    }

    func test_controlBadgeView_valueIsZero_viewWasConfiguredCorrectly() throws {
        assertSubject { makeSubject(0) }
    }

    func test_controlBadgeView_valueIsLessThan100_viewWasConfiguredCorrectly() throws {
        assertSubject { makeSubject(88) }
    }

    func test_controlBadgeView_valueIsLessThan1000_viewWasConfiguredCorrectly() throws {
        assertSubject { makeSubject(888) }
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func makeSubject(_ value: Int) -> some View {
        ControlBadgeView("\(value)")
            .frame(width: 100, height: 50)
    }

    private func assertSubject(
        @ViewBuilder _ subject: () -> some View,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        AssertSnapshot(
            subject(),
            variants: snapshotVariants,
            size: sizeThatFits,
            line: line,
            file: file,
            function: function
        )
    }
}
