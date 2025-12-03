//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
@preconcurrency import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class ScreenSharingView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

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
