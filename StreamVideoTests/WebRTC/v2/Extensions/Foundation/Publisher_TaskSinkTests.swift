//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class PublisherTaskSinkTests: XCTestCase, @unchecked Sendable {

    private var disposableBag: DisposableBag! = .init()

    override func tearDown() {
        disposableBag.removeAll()
        disposableBag = nil
        super.tearDown()
    }

    // MARK: - sinkTask(queue:)

    func test_sinkTask_withSuccessfulCompletion() {
        let expectation = XCTestExpectation(description: "Publisher completes successfully")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let publisher = Just("Test")
            .setFailureType(to: Error.self)

        publisher.sinkTask(queue: queue, receiveCompletion: { completion in
            if case .finished = completion {
                expectation.fulfill()
            }
        }, receiveValue: { value in
            XCTAssertEqual(value, "Test")
        }).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_sinkTask_withFailureCompletion() {
        enum TestError: Error {
            case test
        }

        let expectation = XCTestExpectation(description: "Publisher completes with failure")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let publisher = Fail<String, TestError>(error: .test)

        publisher.sinkTask(queue: queue, receiveCompletion: { completion in
            if case let .failure(error) = completion {
                XCTAssertEqual(error, TestError.test)
                expectation.fulfill()
            }
        }, receiveValue: { _ in
            XCTFail("Should not receive value")
        }).store(in: disposableBag)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_sinkTask_withCancellation() {
        let expectation = XCTestExpectation(description: "Task is cancelled")
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let publisher = Just("Test")
            .setFailureType(to: Error.self)

        let cancellable = publisher.sinkTask(queue: queue, receiveCompletion: { completion in
            if case let .failure(error) = completion {
                // The operation couldn’t be completed. (Swift.CancellationError error 1.)
                XCTAssertTrue(error is CancellationError)
                expectation.fulfill()
            }
        }, receiveValue: { _ in
            throw CancellationError()
        })

        cancellable.store(in: disposableBag)
        cancellable.cancel()

        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - sinkTask(on:storeIn:)

    func test_sinkTaskOnActor_ownerReleased_disposableBagReleased() {
        var owner: SubscriptionOwner? = .init()
        weak var disposableBag: DisposableBag?
        disposableBag = owner?.disposableBag

        owner?.configure()
        owner = nil

        AssertAsync.willBeNil(disposableBag)
    }
}

// MARK: - Private Helpers

private final class SubscriptionOwner {
    let disposableBag: DisposableBag = .init()
    private let actor = TestActor()
    private let publisher = PassthroughSubject<Int, Never>()

    func configure() {
        publisher
            .sinkTask(on: actor, storeIn: disposableBag) { actor, value in
                await actor.consume(value)
            }
            .store(in: disposableBag)
    }
}

private actor TestActor {
    func consume(_ value: Int) {}
}
