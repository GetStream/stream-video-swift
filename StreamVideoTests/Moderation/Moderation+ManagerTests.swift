//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class Moderation_ManagerTests: XCTestCase, @unchecked Sendable {
    private var mockedStreamVideo: MockStreamVideo! = MockStreamVideo()
    private lazy var subject: Moderation.Manager! = .init(MockCall())

    override func tearDown() async throws {
        subject = nil
        mockedStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - setVideoFilter

    func test_setVideoFilter_videoAdapterWasUpdated() async {
        subject.setVideoFilter(.dummy(id: "stream-test"))

        await fulfilmentInMainActor {
            self.subject.video.unmoderatedVideoFilter?.id == "stream-test"
        }
    }

    // MARK: - setVideoPolicy

    func test_setVideoPolicy_videoAdapterWasUpdated() async {
        subject.setVideoPolicy(.init(duration: 11, videoFilter: .dummy(id: "stream-test")))

        await fulfilmentInMainActor {
            self.subject.video.policy.videoFilter.id == "stream-test"
                && self.subject.video.policy.duration == 11
        }
    }
}
