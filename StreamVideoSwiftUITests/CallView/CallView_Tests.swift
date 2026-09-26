//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() async throws {
        mockPermissions = nil
        try await super.tearDown()
    }

    func test_callView_twoParticipants_snapshot() {
        let viewModel = MockCallViewModel()

        AssertSnapshot(
            CallView(viewFactory: TestViewFactory(), viewModel: viewModel),
            variants: snapshotVariants
        )
    }

    func test_callView_participantEvent_snapshot() {
        let viewModel = MockCallViewModel()
        viewModel.participantEvent = .init(
            id: "test1",
            callCid: callCid,
            action: .join,
            user: "1 Test",
            imageURL: nil
        )

        AssertSnapshot(
            CallView(viewFactory: TestViewFactory(), viewModel: viewModel),
            variants: snapshotVariants
        )
    }
}

private final class MockCallViewModel: CallViewModel {

    var _participants: [CallParticipant] = ParticipantFactory.get(2, withAudio: true)

    override var participants: [CallParticipant] { _participants }
}
