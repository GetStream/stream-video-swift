//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class AsyncStreamPublisherTests: XCTestCase {
    func test_publishesElementsFromAsyncStream() {
        let expectation = XCTestExpectation(description: "Publisher emits all values")
        let asyncStream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.yield(2)
            continuation.yield(3)
            continuation.finish()
        }
        let publisher = AsyncStreamPublisher(asyncStream)
        var receivedValues: [Int] = []

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case .failure:
                    XCTFail("Publisher should not fail")
                }
            },
            receiveValue: { value in
                receivedValues.append(value)
            }
        )

        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [1, 2, 3])
        cancellable.cancel()
    }

    func test_publisherCompletesWhenAsyncStreamFinishes() {
        let expectation = XCTestExpectation(description: "Publisher completes")
        let asyncStream = AsyncStream<Int> { continuation in
            continuation.finish()
        }
        let publisher = AsyncStreamPublisher(asyncStream)

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .finished:
                    expectation.fulfill()
                case .failure:
                    XCTFail("Publisher should not fail")
                }
            },
            receiveValue: { _ in
                XCTFail("Publisher should not emit any values")
            }
        )

        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func test_publisherCancelsSubscription() {
        let expectation = XCTestExpectation(description: "Publisher cancels subscription")
        expectation.isInverted = true
        let asyncStream = AsyncStream<Int> { continuation in
            continuation.yield(1)
            continuation.finish()
        }
        let publisher = AsyncStreamPublisher(asyncStream)
        var receivedValues: [Int] = []

        let cancellable = publisher.sink(
            receiveCompletion: { _ in },
            receiveValue: { value in
                receivedValues.append(value)
                expectation.fulfill()
            }
        )
        cancellable.cancel()

        wait(for: [expectation], timeout: 0.5)
        XCTAssertEqual(receivedValues, [])
    }
}
