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
final class ParticipantListButton_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private lazy var viewModel: CallViewModel! = .init()

    override func setUp() async throws {
        try await super.setUp()
        viewModel.setActiveCall(Call.dummy())
    }

    override func tearDown() async throws {
        viewModel = nil
        try await super.tearDown()
    }

    // MARK: - Rendering based on viewModel.callParticipants

    @MainActor
    func test_subject_noParticipants_viewWasConfiguredCorrectly() throws {
        assertSubject(makeSubject)
    }

    @MainActor
    func test_subject_withParticipants_viewWasConfiguredCorrectly() async throws {
        viewModel.call?.state.participants = (0..<5).map { _ in CallParticipant.dummy() }

        assertSubject(makeSubject)
    }

    // MARK: - Private Helpers

    @ViewBuilder
    @MainActor
    private func makeSubject() -> some View {
        ParticipantsListButton(viewModel: viewModel)
            .frame(width: 100, height: 50)
    }

    private func assertSubject(
        record: Bool = false,
        @ViewBuilder _ subject: () -> some View,
        file: StaticString = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        AssertSnapshot(
            subject(),
            variants: snapshotVariants,
            size: sizeThatFits,
            record: record,
            line: line,
            file: file,
            function: function
        )
    }
}
