//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class StatelessHangUpIconView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Appearance

    @MainActor
    func test_appearance_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: Private helpers

    @MainActor
    private func makeSubject(
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> StatelessHangUpIconView {
        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )

        return .init(call: call)
    }
}
