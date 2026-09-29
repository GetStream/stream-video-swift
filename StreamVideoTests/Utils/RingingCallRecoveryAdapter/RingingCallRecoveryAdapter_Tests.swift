//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class RingingCallRecoveryAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private var mockCall: MockCall!
    private var subject: RingingCallRecoveryAdapter!

    override func setUp() async throws {
        try await super.setUp()
        mockCall = .init(.dummy())
        mockCall.stub(for: .get, with: GetCallResponse.dummy())
    }

    override func tearDown() async throws {
        subject = nil
        mockCall = nil
        mockStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - reconnect

    func test_wsConnected_ringingCallSet_getIsCalled() async {
        mockStreamVideo.state.ringingCall = mockCall

        mockStreamVideo.eventNotificationCenter.process(
            WrappedEvent.internalEvent(WSConnected())
        )

        await fulfilmentInMainActor {
            self.mockCall.stubbedFunctionInput[.get]?.isEmpty == false
        }
    }

    func test_wsConnected_noRingingCall_getIsNotCalled() async {
        mockStreamVideo.eventNotificationCenter.process(
            WrappedEvent.internalEvent(WSConnected())
        )

        await wait(for: defaultTimeoutForInversedExpecations)

        XCTAssertTrue(mockCall.stubbedFunctionInput[.get]?.isEmpty ?? true)
    }

    // MARK: - serial execution

    func test_twoActions_secondStartsAfterFirstCompletes() async {
        let policy = StubPolicy()
        let recorder = Recorder()
        let (release, releaseContinuation) = AsyncStream<Void>.makeStream()
        subject = .init(policies: [policy])

        policy.subject.send {
            await recorder.append("first-started")
            for await _ in release { break }
            await recorder.append("first-completed")
        }
        policy.subject.send { await recorder.append("second-started") }

        await fulfilmentInMainActor { recorder.entries == ["first-started"] }
        await wait(for: defaultTimeoutForInversedExpecations)
        XCTAssertEqual(recorder.entries, ["first-started"])

        releaseContinuation.yield()

        await fulfilmentInMainActor {
            recorder.entries == [
                "first-started",
                "first-completed",
                "second-started"
            ]
        }
    }
}

// MARK: - Private Helpers

private final class StubPolicy: RingingRecoveryPolicy {
    let subject = PassthroughSubject<RingingRecoveryAction, Never>()
    var actionPublisher: AnyPublisher<RingingRecoveryAction, Never> {
        subject.eraseToAnyPublisher()
    }
}

@MainActor
private final class Recorder {
    private(set) var entries: [String] = []
    func append(_ entry: String) { entries.append(entry) }
}
