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
final class InviteParticipantsView_Tests: StreamVideoUITestCase,
    @unchecked Sendable {
    private lazy var call: Call! = streamVideoUI?.streamVideo.call(
        callType: callType,
        callId: callId
    )

    private let allVariants: [SnapshotVariant] = [
        .defaultLight,
        .defaultDark,
        .smallDark,
        .extraExtraExtraLargeLight
    ]

    override func tearDown() async throws {
        call = nil
        try await super.tearDown()
    }

    // MARK: - Full layout

    func test_inviteParticipants_withUsersAndSelection_snapshot() {
        let alice = makeUser(id: "user-1", name: "Alice", image: 1)
        let bob = makeUser(id: "user-2", name: "Bob", image: 2)
        let view = makeView(
            allUsers: [
                alice,
                bob,
                makeUser(id: "user-3", name: "Charlie", image: 3),
                makeUser(id: "user-4", name: "Diana", image: 4),
                makeUser(id: "user-5", name: "Eve", image: 5)
            ],
            selectedUsers: [alice, bob]
        )

        AssertSnapshot(view, variants: allVariants)
    }

    func test_inviteParticipants_noSelection_snapshot() {
        let view = makeView(
            allUsers: [
                makeUser(id: "user-1", name: "Alice", image: 1),
                makeUser(id: "user-2", name: "Bob", image: 2),
                makeUser(id: "user-3", name: "Charlie", image: 3),
                makeUser(id: "user-4", name: "Diana", image: 4)
            ]
        )

        AssertSnapshot(view, variants: allVariants)
    }

    func test_inviteParticipants_noUsers_snapshot() {
        let view = makeView(allUsers: [])

        AssertSnapshot(view, variants: allVariants)
    }

    // MARK: - Private Helpers

    private func makeUser(
        id: String,
        name: String,
        image: Int
    ) -> User {
        .dummy(
            id: id,
            name: name,
            imageURL: ImageFactory.get(image)
        )
    }

    private func makeView(
        allUsers: [User],
        selectedUsers: [User] = []
    ) -> some View {
        NavigationView {
            InviteParticipantsView(
                viewFactory: DefaultViewFactory.shared,
                viewModel: InviteParticipantsViewModel(
                    call: call,
                    allUsers: allUsers,
                    selectedUsers: selectedUsers
                ),
                inviteParticipantsShown: .constant(true)
            )
        }
        .navigationViewStyle(.stack)
    }
}

extension InviteParticipantsViewModel {
    convenience init(
        call: Call? = nil,
        allUsers: [User],
        selectedUsers: [User] = []
    ) {
        self.init(currentParticipants: [], call: call)
        self.allUsers = allUsers
        self.selectedUsers = selectedUsers
    }
}
