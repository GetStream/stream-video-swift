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
final class ParticipantPopoverView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var call: Call! = .dummy()

    override func tearDown() async throws {
        call = nil
        try await super.tearDown()
    }

    func test_popover_withoutPinForEveryone_viewWasConfiguredCorrectly() {
        assertSubject(participant: .dummy())
    }

    func test_popover_withPinForEveryone_viewWasConfiguredCorrectly() {
        call.state.ownCapabilities = [.pinForEveryone]

        assertSubject(participant: .dummy())
    }

    // MARK: - Private Helpers

    private func assertSubject(
        participant: CallParticipant,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) {
        AssertSnapshot(
            ParticipantPopoverView(
                participant: participant,
                call: call,
                popoverShown: .constant(true)
            )
            .frame(width: 300, height: 200),
            variants: snapshotVariants,
            size: .init(width: 300, height: 200),
            line: line,
            file: file,
            function: function
        )
    }
}
