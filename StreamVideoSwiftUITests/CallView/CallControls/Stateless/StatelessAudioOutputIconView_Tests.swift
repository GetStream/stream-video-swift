//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class StatelessAudioOutputIconView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Appearance

    @MainActor
    func test_appearance_audioOutputOn_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_audioOutputOff_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: Private helpers

    @MainActor
    private func makeSubject(
        _ audioOutputOn: Bool,
        actionHandler: (() -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> StatelessAudioOutputIconView {
        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )

        call.state.callSettings = .init(audioOutputOn: audioOutputOn)

        return .init(call: call, actionHandler: actionHandler)
    }
}
