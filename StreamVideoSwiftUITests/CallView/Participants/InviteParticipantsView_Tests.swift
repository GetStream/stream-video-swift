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
    @unchecked Sendable
{
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

    // MARK: - UsersHeaderView

    func test_usersHeaderView_snapshot() {
        let view = UsersHeaderView()
            .frame(width: 390)

        AssertSnapshot(view, variants: allVariants)
    }

    // MARK: - VideoUserView

    func test_videoUserView_unselected_snapshot() {
        let user = User.dummy(
            id: "test-user",
            name: "John Doe"
        )
        let view = VideoUserView(
            viewFactory: DefaultViewFactory.shared,
            user: user,
            isSelected: false
        )
        .frame(width: 390)

        AssertSnapshot(view, variants: allVariants)
    }

    func test_videoUserView_selected_snapshot() {
        let user = User.dummy(
            id: "test-user",
            name: "John Doe"
        )
        let view = VideoUserView(
            viewFactory: DefaultViewFactory.shared,
            user: user,
            isSelected: true
        )
        .frame(width: 390)

        AssertSnapshot(view, variants: allVariants)
    }

    // MARK: - SelectedParticipantView (in horizontal scroll context)

    func test_selectedParticipants_multipleUsers_snapshot() {
        let users = [
            User.dummy(id: "user-1", name: "Alice"),
            User.dummy(id: "user-2", name: "Bob"),
            User.dummy(id: "user-3", name: "Charlie")
        ]
        let view = ScrollView(.horizontal) {
            HStack(spacing: 16) {
                ForEach(users) { user in
                    SelectedParticipantView(
                        viewFactory: DefaultViewFactory.shared,
                        user: user,
                        onUserTapped: { _ in }
                    )
                }
            }
            .padding(.all, 16)
        }
        .frame(width: 390, height: 100)

        AssertSnapshot(view, variants: allVariants)
    }
}
