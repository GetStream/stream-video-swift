//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class CallParticipantsInfoView_Tests: StreamVideoUITestCase,
    @unchecked Sendable
{
    private lazy var call: Call! = streamVideoUI?.streamVideo.call(
        callType: callType,
        callId: callId
    )

    override func tearDown() async throws {
        call = nil
        try await super.tearDown()
    }

    // MARK: - Full sheet

    func test_participantsSheet_withParticipants_snapshot() {
        let participants = ParticipantFactory.get(3, withAudio: true)
        let view = makeSheet(participants: participants)

        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_participantsSheet_withMutedParticipants_snapshot() {
        let participants = ParticipantFactory.get(
            3,
            withAudio: false
        )
        let view = makeSheet(participants: participants)

        AssertSnapshot(view, variants: snapshotVariants)
    }

    func test_participantsSheet_noParticipants_snapshot() {
        let view = makeSheet(participants: [])

        AssertSnapshot(view, variants: snapshotVariants)
    }

    // MARK: - Private Helpers

    @ViewBuilder
    private func makeSheet(
        participants: [CallParticipant]
    ) -> some View {
        CallParticipantsViewContainer(
            viewFactory: DefaultViewFactory.shared,
            viewModel: CallParticipantsInfoViewModel(call: call),
            participants: participants,
            call: call,
            blockedUsers: [],
            callSettings: CallSettings(),
            inviteParticipantsShown: .constant(false),
            inviteTapped: {},
            muteTapped: {},
            closeTapped: {}
        )
    }
}
