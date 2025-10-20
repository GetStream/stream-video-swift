//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class Store_Tests: XCTestCase, @unchecked Sendable {

    private lazy var middlewareA: MockMiddleware<TestStoreNamespace>! = .init()
    private lazy var middlewareB: MockMiddleware<TestStoreNamespace>! = .init()
    private lazy var reducerA: TestStoreReducer! = .init()
    private lazy var reducerB: TestStoreReducer! = .init()
    private lazy var coordinator: TestStoreCoordinator! = .init()

    private lazy var subject: Store<TestStoreNamespace>! = TestStoreNamespace.store(
        initialState: .init(),
        coordinator: coordinator
    )

    override func setUp() {
        super.setUp()

        subject.add(middlewareA)
        subject.add(middlewareB)

        subject.add(reducerA)
        subject.add(reducerB)
    }

    override func tearDown() {
        subject = nil
        middlewareA = nil
        middlewareB = nil
        reducerA = nil
        reducerB = nil
        super.tearDown()
    }

    // MARK: - Dispatch

    func test_dispatch_allMiddlewareWereCalled() async {
        subject.dispatch(.callReducersWithStep)

        await fulfillment {
            self.middlewareA.actionsReceived.endIndex == 1
                && self.middlewareB.actionsReceived.endIndex == 1
        }
    }

    func test_dispatch_allReduceresWereCalled() async {
        subject.dispatch(.callReducersWithStep)

        await fulfillment {
            self.reducerA.timesCalled == 1
                && self.reducerB.timesCalled == 1
                && self.subject.state.reducersCalled == 2
        }
    }

    func test_dispatch_verifyReducersAccess() async {
        reducerA.identifier = "A"
        reducerB.identifier = "B"

        subject.dispatch(.verifyReducersOrder)

        await fulfillment {
            self.subject.state.reducersAccessVerification == "A_B"
        }
    }

    func test_dispatch_coordinatorSkipsUnnecessaryAction() async {
        coordinator.shouldExecuteNextAction = false
        subject.dispatch(.callReducersWithStep)
        await wait(for: 1)

        XCTAssertEqual(reducerA.timesCalled, 0)
        XCTAssertEqual(reducerB.timesCalled, 0)
        XCTAssertEqual(subject.state.reducersCalled, 0)
    }
}

// MARK: - Private Types

private struct TestStoreState: Equatable {
    var reducersCalled: Int = 0
    var reducersAccessVerification: String = ""
}

private enum TestStoreAction: Sendable, StoreActionBoxProtocol {
    case callReducersWithStep
    case verifyReducersOrder
}

private final class TestStoreReducer: Reducer<TestStoreNamespace>, @unchecked Sendable {
    private(set) var timesCalled: Int = 0

    var identifier: String = .unique

    override func reduce(
        state: TestStoreState,
        action: TestStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) async throws -> TestStoreState {
        defer { timesCalled += 1 }

        var updatedState = state

        switch action {
        case .callReducersWithStep:
            updatedState.reducersCalled += 1

        case .verifyReducersOrder:
            if updatedState.reducersAccessVerification.isEmpty {
                updatedState.reducersAccessVerification = identifier
            } else {
                updatedState.reducersAccessVerification += "_\(identifier)"
            }
        }

        return updatedState
    }
}

private final class TestStoreCoordinator: StoreCoordinator<TestStoreNamespace>, @unchecked Sendable {
    var shouldExecuteNextAction = true

    override func shouldExecute(
        action: TestStoreAction,
        state: TestStoreState
    ) -> Bool {
        shouldExecuteNextAction
    }
}

private enum TestStoreNamespace: StoreNamespace, Sendable {
    typealias State = TestStoreState

    typealias Action = TestStoreAction

    static let identifier: String = .unique
}
