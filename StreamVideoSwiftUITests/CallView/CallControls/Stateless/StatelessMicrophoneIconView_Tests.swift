//
//  StatelessMicrophoneIconView_Tests.swift
//  StreamVideoSwiftUITests
//
//  Created by Ilias Pavlidakis on 1/5/24.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

final class StatelessMicrophoneIconView_Tests: StreamVideoUITestCase {

    // MARK: - Appearance

    @MainActor
    func test_appearance_micOn_wasConfiguredCorrectly() throws {
        AssertSnapshot(
            try makeSubject(
                true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_micOff_wasConfiguredCorrectly() throws {
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
        _ micOn: Bool,
        actionHandler: (() -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> StatelessMicrophoneIconView {
        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )
        call.state.update(
            from: .dummy(
                settings: .dummy(
                    audio: .dummy(micDefaultOn: micOn)
                )
            )
        )

        return .init(call: call, actionHandler: actionHandler)
    }
}

