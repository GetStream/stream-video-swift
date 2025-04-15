//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class PublisherAsyncStreamTests: XCTestCase, @unchecked Sendable {

    private final class ReceivedValuesStorage<Element>: @unchecked Sendable {
        private var values: [Element] = []

        func append(_ element: Element) {
            values.append(element)
        }

        var count: Int { values.count }

        var array: [Element] { values }
    }

    func testPublisherToAsyncStream() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Receive values from async stream")

        Task {
            for await value in asyncStream {
                storage.append(value)
                if storage.count == 3 {
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2, 3])
    }
    
    func testPublisherToAsyncStreamWithCompletion() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream completes")
        
        Task {
            for await value in asyncStream {
                storage.append(value)
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(completion: .finished)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2])
    }
    
    func testPublisherToAsyncStreamWithCancellation() async {
        // Given
        let storage = ReceivedValuesStorage<Int>()
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream is cancelled")
        
        let task = Task {
            for await value in asyncStream {
                storage.append(value)
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(storage.array, [1, 2])
    }
}
