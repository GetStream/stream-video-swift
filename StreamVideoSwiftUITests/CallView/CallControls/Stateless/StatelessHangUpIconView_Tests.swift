//
//  StatelessHangUpIconView.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 1/5/24.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class StatelessHangUpIconView_Tests: StreamVideoUITestCase {

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


