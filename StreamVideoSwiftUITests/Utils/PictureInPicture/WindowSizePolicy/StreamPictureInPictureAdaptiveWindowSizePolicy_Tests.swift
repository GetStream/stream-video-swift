//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideoSwiftUI
import XCTest

final class StreamPictureInPictureAdaptiveWindowSizePolicy_Tests: XCTestCase, @unchecked Sendable {

    private lazy var targetSize: CGSize! = .init(width: 100, height: 280)
    private lazy var subject: StreamPictureInPictureAdaptiveWindowSizePolicy! = .init()

    override func tearDown() async throws {
        targetSize = nil
        subject = nil
        try await super.tearDown()
    }

    // MARK: - didSetTrackSize

    @MainActor
    func test_didSetTrackSize_setsPreferredContentSizeOnController() async {
        let controller = MockStreamAVPictureInPictureViewControlling()
        subject.controller = controller

        subject.trackSize = targetSize

        await fulfilmentInMainActor {
            controller.preferredContentSize == self.targetSize
        }
    }
}
