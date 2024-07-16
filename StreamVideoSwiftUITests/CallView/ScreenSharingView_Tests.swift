//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class ScreenSharingView_Tests: StreamVideoUITestCase {
    
    @MainActor
    func test_screenSharingView_snapshot() async throws {
        let viewModel = MockCallViewModel()

        let session = ScreenSharingSession(
            track: nil,
            participant: viewModel.participants[1]
        )
        let view = ScreenSharingView(
            viewModel: viewModel,
            screenSharing: session,
            availableFrame: .init(origin: .zero, size: defaultScreenSize),
            isZoomEnabled: false
        )
        AssertSnapshot(view, variants: snapshotVariants)
    }
}

private final class MockCallViewModel: CallViewModel {

    var _participants: [CallParticipant] = ParticipantFactory.get(4)

    override var participants: [CallParticipant] { _participants }
}
