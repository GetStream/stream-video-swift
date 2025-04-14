//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class PublisherAsyncStreamTests: XCTestCase, @unchecked Sendable {

    func testPublisherToAsyncStream() async {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Receive values from async stream")
        var receivedValues: [Int] = []
        
        Task {
            for await value in asyncStream {
                receivedValues.append(value)
                if receivedValues.count == 3 {
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(3)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [1, 2, 3])
    }
    
    func testPublisherToAsyncStreamWithCompletion() async {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream completes")
        var receivedValues: [Int] = []
        
        Task {
            for await value in asyncStream {
                receivedValues.append(value)
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        publisher.send(completion: .finished)
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [1, 2])
    }
    
    func testPublisherToAsyncStreamWithCancellation() async {
        // Given
        let publisher = PassthroughSubject<Int, Never>()
        let asyncStream = publisher.eraseAsAsyncStream()
        
        // When
        let expectation = XCTestExpectation(description: "Stream is cancelled")
        var receivedValues: [Int] = []
        
        let task = Task {
            for await value in asyncStream {
                receivedValues.append(value)
            }
            expectation.fulfill()
        }
        
        // Then
        publisher.send(1)
        publisher.send(2)
        task.cancel()
        
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedValues, [1, 2])
    }
}
