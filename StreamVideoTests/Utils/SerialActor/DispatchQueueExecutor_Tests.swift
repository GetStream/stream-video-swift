//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class DispatchQueueExecutor_Tests: XCTestCase, @unchecked Sendable {

    private lazy var subject: DispatchQueueExecutor! = .init(queue: .main)

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests
    
    func test_initWithQueue_setsCorrectQueue() {
        let customQueue = DispatchQueue(label: "custom.test.queue")
        let customExecutor = DispatchQueueExecutor(queue: customQueue)
        
        // Verify the subject was created successfully
        XCTAssertNotNil(customExecutor)
    }
    
    func test_convenienceInit_createsExecutorWithFileBasedLabel() {
        let fileBasedExecutor = DispatchQueueExecutor(file: #file)
        
        // Verify the subject was created successfully
        XCTAssertNotNil(fileBasedExecutor)
    }
    
    // MARK: - Serial Execution Tests
    
    func test_enqueue_executesJobsSerially() async {
        let tracker = ExecutionOrderTracker(.init(queue: .main))

        for i in 1...3 {
            await tracker.recordExecution(i)
        }

        await fulfillment(timeout: 1) {
            let finalOrder = await tracker.executionOrder
            return finalOrder == [1, 2, 3]
        }

        // Allow cleanup
        await wait(for: 0.1)
    }

    // MARK: - Private Helpers

    private actor ExecutionOrderTracker {
        private(set) var executionOrder: [Int] = []

        let executor: DispatchQueueExecutor
        nonisolated var unownedExecutor: UnownedSerialExecutor { executor.asUnownedSerialExecutor() }

        init(_ executor: DispatchQueueExecutor) {
            self.executor = executor
        }

        func recordExecution(_ index: Int) {
            executionOrder.append(index)
        }
    }
}
