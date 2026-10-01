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
final class ScreensharingControls_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()

    override func setUp() async throws {
        try await super.setUp()
        viewModel.setActiveCall(Call.dummy())
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    func test_screenshareIconView_notScreensharing_viewWasConfiguredCorrectly() {
        viewModel.call?.state.isCurrentUserScreensharing = false

        assertSubject { ScreenshareIconView(viewModel: viewModel).frame(width: 100, height: 50) }
    }

    func test_screenshareIconView_screensharing_viewWasConfiguredCorrectly() {
        viewModel.call?.state.isCurrentUserScreensharing = true

        assertSubject { ScreenshareIconView(viewModel: viewModel).frame(width: 100, height: 50) }
    }

    func test_broadcastIconView_viewWasConfiguredCorrectly() {
        assertSubject {
            BroadcastIconView(viewModel: viewModel, preferredExtension: "")
                .frame(width: 100, height: 50)
        }
    }

    // MARK: - Private Helpers

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
