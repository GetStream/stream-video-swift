//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SwiftUI
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class ParticipantListButton_Tests: StreamVideoUITestCase {

    private lazy var viewModel: CallViewModel! = .init()

    override func setUp() {
        super.setUp()

        viewModel.startCall(
            callType: .default,
            callId: UUID().uuidString,
            members: [],
            ring: true
        )
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Rendering based on viewModel.callParticipants

    func test_subject_noParticipants_viewWasConfiguredCorrectly() throws {
        assertSubject(makeSubject)
    }

    func test_subject_withParticipants_viewWasConfiguredCorrectly() async throws {
        viewModel.call?.state.participantsMap = (0..<5).reduce(into: [String: CallParticipant]()) { partialResult, _ in
            let participant = CallParticipant.dummy()
            partialResult[participant.id] = participant
        }

        try await Task.sleep(nanoseconds: 1_000_000_000)

        assertSubject(makeSubject)
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func makeSubject() -> some View {
        ParticipantsListButton(viewModel: viewModel)
            .frame(width: 100, height: 50)
    }

    private func assertSubject(
        @ViewBuilder _ subject: () -> some View,
        file: StaticString = #file,
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

