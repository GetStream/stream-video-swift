//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class OrderedCapacityQueueTests: XCTestCase, @unchecked Sendable {
    private lazy var queue: OrderedCapacityQueue<Int>! = .init(capacity: 5, removalTime: 1)
    private var cancellables: Set<AnyCancellable>! = .init()

    override func tearDown() {
        queue = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - init

    func test_init_givenInitialCapacity_whenInitialized_thenCapacityIsSet() {
        XCTAssertEqual(queue.capacity, 5)
    }

    func test_init_givenInitialRemovalTime_whenInitialized_thenRemovalTimeIsSet() {
        XCTAssertEqual(queue.removalTime, 1)
    }

    // MARK: - append

    func test_append_givenElements_whenAdded_thenElementsAreInQueue() {
        queue.append(1)
        queue.append(2)
        XCTAssertEqual(queue.toArray(), [1, 2])
    }

    func test_append_givenExceedingCapacity_whenAdded_thenOldestElementsAreRemoved() {
        for i in 1...6 {
            queue.append(i)
        }
        XCTAssertEqual(queue.toArray(), [2, 3, 4, 5, 6])
    }

    // MARK: - removalTime

    func test_removalTime_givenTimeInterval_whenElapsed_thenElementsAreRemoved() async {
        queue.append(1)
        queue.append(2)

        await wait(for: 2)

        XCTAssertTrue(queue.toArray().isEmpty)
    }

    // MARK: - publisher

    func test_publisher_givenElements_whenAdded_thenPublishesChanges() async {
        var receivedElements: [[Int]] = []
        queue
            .publisher
            .sink { receivedElements.append($0) }
            .store(in: &cancellables)
        
        queue.append(1)
        await wait(for: 0.5)
        queue.append(2)
        await wait(for: 0.75)

        XCTAssertEqual(receivedElements, [[1], [1, 2], [2]])
    }
}
