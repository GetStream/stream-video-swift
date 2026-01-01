//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class CollectionDelayedUpdateObserver_Tests: XCTestCase, @unchecked Sendable {

    func test_init_givenSmallCollection_whenInitializing_thenIntervalIsScreenRefreshRate() {
        // Given
        let collection: [Int] = Array(0..<10) // A small collection with less than 16 elements
        let publisher = PassthroughSubject<[Int], Never>().eraseToAnyPublisher()
        let scheduler = DispatchQueue(label: "test")

        // When
        let observer = CollectionDelayedUpdateObserver(
            publisher: publisher,
            initial: collection,
            mode: .debounce(scheduler: scheduler)
        )

        // Then
        XCTAssertEqual(
            observer.interval.value,
            ScreenPropertiesAdapter.currentValue.refreshRate,
            "Expected interval to be screen refresh rate for small collection."
        )
    }

    func test_init_givenMediumCollection_whenInitializing_thenIntervalIsMedium() {
        // Given
        let collection: [Int] = Array(0..<75) // A medium-sized collection with less than 100 elements
        let publisher = PassthroughSubject<[Int], Never>().eraseToAnyPublisher()
        let scheduler = DispatchQueue(label: "test")

        // When
        let observer = CollectionDelayedUpdateObserver(
            publisher: publisher,
            initial: collection,
            mode: .debounce(scheduler: scheduler)
        )

        // Then
        XCTAssertEqual(observer.interval.value, 0.5, "Expected interval to be medium for medium-sized collection.")
    }

    func test_configure_givenDebounceMode_whenNewValueIsPublished_thenUpdatesValueAfterDelay() {
        // Given
        let collection: [Int] = Array(0..<10)
        let publisher = PassthroughSubject<[Int], Never>()
        let scheduler = DispatchQueue(label: "test")
        let observer = CollectionDelayedUpdateObserver(
            publisher: publisher.eraseToAnyPublisher(),
            initial: collection,
            mode: .debounce(scheduler: scheduler)
        )
        
        let expectation = XCTestExpectation(description: "Wait for value update")
        let newCollection: [Int] = Array(0..<20)

        // When
        publisher.send(newCollection)

        // Dispatch some delay to simulate debounce
        scheduler.asyncAfter(deadline: .now() + 0.25) {
            // Then
            XCTAssertEqual(observer.value, newCollection, "Expected observer value to be updated after debounce.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func test_configure_givenThrottleMode_whenMultipleValuesArePublished_thenThrottlesUpdates() {
        // Given
        let collection: [Int] = Array(0..<10)
        let publisher = PassthroughSubject<[Int], Never>()
        let scheduler = DispatchQueue(label: "test")
        let observer = CollectionDelayedUpdateObserver(
            publisher: publisher.eraseToAnyPublisher(),
            initial: collection,
            mode: .throttle(scheduler: scheduler, latest: true)
        )

        let expectation = XCTestExpectation(description: "Wait for value update after throttle")
        let newCollection: [Int] = Array(0..<20)
        let secondCollection: [Int] = Array(0..<30)

        // When
        publisher.send(newCollection)
        publisher.send(secondCollection)

        // Dispatch some delay to simulate throttle
        scheduler.asyncAfter(deadline: .now() + 1) {
            // Then
            XCTAssertEqual(observer.value, secondCollection, "Expected observer value to be throttled to latest value.")
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }
}
