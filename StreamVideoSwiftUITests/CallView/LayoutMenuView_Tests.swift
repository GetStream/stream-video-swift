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
final class LayoutMenuView_Tests: StreamVideoUITestCase,
    @unchecked Sendable
{
    private lazy var callViewModel: CallViewModel! = {
        let vm = CallViewModel()
        vm.startCall(callType: callType, callId: callId, members: [])
        return vm
    }()

    private let allVariants: [SnapshotVariant] = [
        .defaultLight,
        .defaultDark,
        .smallDark,
        .extraExtraExtraLargeLight
    ]

    override func tearDown() async throws {
        callViewModel = nil
        try await super.tearDown()
    }

    // MARK: - Snapshots

    func test_layoutMenuView_snapshot() {
        let view = LayoutMenuView(
            viewModel: callViewModel,
            size: 44
        )
        .frame(width: 60, height: 60)

        AssertSnapshot(view, variants: allVariants)
    }
}
