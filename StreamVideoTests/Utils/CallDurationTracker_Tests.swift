//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

@MainActor
final class CallDurationTracker_Tests: XCTestCase, @unchecked Sendable {

    private var disposableBag: DisposableBag! = .init()
    private var duration: TimeInterval! = 0
    private var startedAt: Date?
    private var subject: CallDurationTracker! = .init()

    override func setUp() async throws {
        try await super.setUp()
        subject
            .durationPublisher
            .sink { [weak self] in self?.duration = $0 }
            .store(in: disposableBag)
        subject
            .startedAtPublisher
            .sink { [weak self] in self?.startedAt = $0 }
            .store(in: disposableBag)
    }

    override func tearDown() {
        disposableBag = nil
        duration = nil
        startedAt = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - didUpdate(session:)

    func test_didUpdate_withoutStartedSession_keepsDurationReset() {
        subject.didUpdate(.dummy())

        XCTAssertNil(startedAt)
        XCTAssertEqual(duration, 0)
    }

    func test_didUpdate_withStartedAt_anchorsDurationToSessionStart() {
        let sessionStartedAt = Date(timeIntervalSinceNow: -95)

        subject.didUpdate(
            .dummy(
                liveStartedAt: Date(timeIntervalSinceNow: -120),
                startedAt: sessionStartedAt
            )
        )

        XCTAssertEqual(startedAt, sessionStartedAt)
        XCTAssertEqual(
            duration,
            Date().timeIntervalSince(sessionStartedAt),
            accuracy: 1
        )
    }

    func test_didUpdate_withOnlyLiveStartedAt_anchorsDurationToLiveStart() {
        let liveStartedAt = Date(timeIntervalSinceNow: -42)

        subject.didUpdate(.dummy(liveStartedAt: liveStartedAt))

        XCTAssertEqual(startedAt, liveStartedAt)
        XCTAssertEqual(
            duration,
            Date().timeIntervalSince(liveStartedAt),
            accuracy: 1
        )
    }

    func test_didUpdate_withEndedSession_resetsDuration() {
        let sessionStartedAt = Date(timeIntervalSinceNow: -30)
        subject.didUpdate(.dummy(startedAt: sessionStartedAt))

        subject.didUpdate(.dummy(endedAt: Date(), startedAt: sessionStartedAt))

        XCTAssertNil(startedAt)
        XCTAssertEqual(duration, 0)
    }

    // MARK: - startOverride

    func test_startOverride_whenSet_anchorsDurationToOverride() {
        let sessionStartedAt = Date(timeIntervalSinceNow: -95)
        subject.didUpdate(.dummy(startedAt: sessionStartedAt))

        let override = Date(timeIntervalSinceNow: -5)
        subject.startOverride = override

        XCTAssertEqual(
            duration,
            Date().timeIntervalSince(override),
            accuracy: 1
        )
        XCTAssertEqual(startedAt, sessionStartedAt)
    }

    func test_startOverride_sessionUpdates_doNotReanchorDuration() {
        let override = Date(timeIntervalSinceNow: -5)
        subject.startOverride = override

        let sessionStartedAt = Date(timeIntervalSinceNow: -95)
        subject.didUpdate(.dummy(startedAt: sessionStartedAt))

        XCTAssertEqual(
            duration,
            Date().timeIntervalSince(override),
            accuracy: 1
        )
        XCTAssertEqual(startedAt, sessionStartedAt)
    }

    func test_startOverride_withoutStartedSession_anchorsDurationToOverride() {
        subject.didUpdate(.dummy())

        let override = Date(timeIntervalSinceNow: -5)
        subject.startOverride = override

        XCTAssertEqual(
            duration,
            Date().timeIntervalSince(override),
            accuracy: 1
        )
        XCTAssertNil(startedAt)
    }

    func test_startOverride_withEndedSession_resetClearsOverride() {
        subject.didUpdate(.dummy(startedAt: Date(timeIntervalSinceNow: -30)))
        subject.startOverride = Date(timeIntervalSinceNow: -5)

        subject.didUpdate(.dummy(endedAt: Date()))

        XCTAssertNil(subject.startOverride)
        XCTAssertNil(startedAt)
        XCTAssertEqual(duration, 0)
    }
}
