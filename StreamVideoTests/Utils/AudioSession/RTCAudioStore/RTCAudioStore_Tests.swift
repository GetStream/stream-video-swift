//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCAudioStore_Tests: XCTestCase, @unchecked Sendable {

    private final class SpyReducer: RTCAudioStoreReducer, @unchecked Sendable {
        var reduceError: Error?
        private(set) var reduceWasCalled: (state: RTCAudioStore.State, action: RTCAudioStoreAction, calledAt: DispatchTime)?
        func reduce(
            state: RTCAudioStore.State,
            action: RTCAudioStoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) throws -> RTCAudioStore.State {
            reduceWasCalled = (state, action, DispatchTime.now())
            guard let reduceError else {
                return state
            }
            throw reduceError
        }
    }

    private final class SpyMiddleware: RTCAudioStoreMiddleware, @unchecked Sendable {
        private(set) var applyWasCalled: (state: RTCAudioStore.State, action: RTCAudioStoreAction, calledAt: DispatchTime)?
        func apply(
            state: RTCAudioStore.State,
            action: RTCAudioStoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            applyWasCalled = (state, action, DispatchTime.now())
        }
    }

    // MARK: - Properties

    private lazy var subject: RTCAudioStore! = .init()

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_RTCAudioSessionReducerHasBeenAdded() {
        _ = subject

        XCTAssertNotNil(subject.reducers.first(where: { $0 is RTCAudioSessionReducer }))
    }

    func test_init_stateWasUpdatedCorrectly() async {
        _ = subject

        await fulfillment {
            self.subject.state.prefersNoInterruptionsFromSystemAlerts == true
                && self.subject.state.useManualAudio == true
                && self.subject.state.isAudioEnabled == false
        }
    }

    // MARK: - dispatch

    func test_dispatch_middlewareWasCalledBeforeReducer() async throws {
        let reducer = SpyReducer()
        let middleware = SpyMiddleware()
        subject.add(reducer)
        subject.add(middleware)

        subject.dispatch(.audioSession(.isActive(true)))
        await fulfillment { middleware.applyWasCalled != nil && reducer.reduceWasCalled != nil }

        let middlewareWasCalledAt = try XCTUnwrap(middleware.applyWasCalled?.calledAt)
        let reducerWasCalledAt = try XCTUnwrap(reducer.reduceWasCalled?.calledAt)
        let diff = middlewareWasCalledAt.distance(to: reducerWasCalledAt)
        switch diff {
        case .never:
            XCTFail()
        case let .nanoseconds(value):
            return XCTAssertTrue(value > 0)
        default:
            XCTFail("It shouldn't be that long.")
        }
    }

    // MARK: - dispatchAsync

    func test_dispatchAsync_middlewareWasCalledBeforeReducer() async throws {
        let reducer = SpyReducer()
        let middleware = SpyMiddleware()
        subject.add(reducer)
        subject.add(middleware)

        try await subject.dispatchAsync(.audioSession(.isActive(true)))

        let middlewareWasCalledAt = try XCTUnwrap(middleware.applyWasCalled?.calledAt)
        let reducerWasCalledAt = try XCTUnwrap(reducer.reduceWasCalled?.calledAt)
        let diff = middlewareWasCalledAt.distance(to: reducerWasCalledAt)
        switch diff {
        case .never:
            XCTFail()
        case let .nanoseconds(value):
            return XCTAssertTrue(value > 0)
        default:
            XCTFail("It shouldn't be that long.")
        }
    }

    func test_dispatchAsync_reducerThrowsError_rethrowsError() async throws {
        let expected = ClientError(.unique)
        let reducer = SpyReducer()
        reducer.reduceError = expected
        subject.add(reducer)

        do {
            try await subject.dispatchAsync(.audioSession(.isActive(true)))
            XCTFail()
        } catch {
            XCTAssertEqual((error as? ClientError)?.localizedDescription, expected.localizedDescription)
        }
    }
}
