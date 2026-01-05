//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class Moderation_VideoAdapterTests: XCTestCase, @unchecked Sendable {
    private var mockedStreamVideo: MockStreamVideo! = MockStreamVideo()
    private lazy var call: MockCall! = .init()
    private lazy var subject: Moderation.VideoAdapter! = .init(call)

    override func tearDown() async throws {
        subject = nil
        call = nil
        mockedStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - init

    func test_init_hasCorrectInitialState() {
        XCTAssertEqual(subject.policy.duration, 20)
        XCTAssertEqual(subject.policy.videoFilter, .blur)
    }

    // MARK: - didUpdateFilterPolicy

    func test_didUpdateFilterPolicy_wasUpdatedCorrectly() async {
        subject.didUpdateFilterPolicy(.init(duration: 11, videoFilter: .dummy(id: "stream-test")))

        await fulfilmentInMainActor {
            self.subject.policy.videoFilter.id == "stream-test"
                && self.subject.policy.duration == 11
        }
    }

    // MARK: - didUpdateVideoFilter

    func test_didUpdateVideoFilter_wasUpdatedCorrectly() async {
        subject.didUpdateVideoFilter(.dummy(id: "stream-test"))

        await fulfilmentInMainActor {
            self.subject.unmoderatedVideoFilter?.id == "stream-test"
        }
    }

    // MARK: - didReceive CallModerationBlurEvent

    func test_didReceiveCallModerationBlurEvent_callSetVideoFilterCorrectly() async {
        let eventSubject = PassthroughSubject<VideoEvent, Never>()
        call.stub(for: \.eventPublisher, with: eventSubject.eraseToAnyPublisher())
        _ = subject

        eventSubject.send(
            .typeCallModerationBlurEvent(
                CallModerationBlurEvent(
                    callCid: .unique,
                    createdAt: .distantPast,
                    custom: [:],
                    userId: "1"
                )
            )
        )

        await fulfilmentInMainActor {
            self.subject.isActive == true
                && self.call.timesCalled(.setVideoFilter) == 1
                && self.call.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.first == self.subject.policy.videoFilter
        }
    }

    func test_didReceiveCallModerationBlurEvent_withDuration_afterDurationEndsModerationVideoFilterDeactivates() async {
        let eventSubject = PassthroughSubject<VideoEvent, Never>()
        call.stub(for: \.eventPublisher, with: eventSubject.eraseToAnyPublisher())
        _ = subject
        subject.didUpdateFilterPolicy(.init(duration: 2, videoFilter: .dummy(id: "during")))
        subject.didUpdateVideoFilter(.dummy(id: "before"))

        eventSubject.send(
            .typeCallModerationBlurEvent(
                CallModerationBlurEvent(
                    callCid: .unique,
                    createdAt: .distantPast,
                    custom: [:],
                    userId: "1"
                )
            )
        )

        await fulfilmentInMainActor {
            self.subject.isActive == true
        }

        await fulfilmentInMainActor {
            self.subject.isActive == false
                && self.call.timesCalled(.setVideoFilter) == 2
                && self.call.recordedInputPayload(VideoFilter.self, for: .setVideoFilter)?.last?.id == "before"
        }
    }
}
