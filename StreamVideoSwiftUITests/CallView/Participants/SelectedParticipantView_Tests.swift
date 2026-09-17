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
final class SelectedParticipantView_Tests: StreamVideoUITestCase,
    @unchecked Sendable
{
    private let allVariants: [SnapshotVariant] = [
        .defaultLight,
        .defaultDark,
        .smallDark,
        .extraExtraExtraLargeLight
    ]

    // MARK: - Snapshots

    func test_selectedParticipantView_snapshot() {
        let user = User.dummy(
            id: "test-user",
            name: "John Doe"
        )
        let view = SelectedParticipantView(
            viewFactory: DefaultViewFactory.shared,
            user: user,
            onUserTapped: { _ in }
        )
        .frame(width: 80, height: 80)

        AssertSnapshot(view, variants: allVariants)
    }
}
