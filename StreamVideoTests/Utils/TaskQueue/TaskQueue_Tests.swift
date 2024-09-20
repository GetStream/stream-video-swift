//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo // Replace with your module name
import XCTest

final class TaskQueueTests: XCTestCase {

    func testTaskQueueExecutesTasksWithConcurrencyLimit() async {
        let expectation1 = expectation(description: "Task 1 completed")
        let expectation2 = expectation(description: "Task 2 completed")
        let expectation3 = expectation(description: "Task 3 completed")

        let taskQueue = TaskQueue(maxConcurrentTasks: 2)

        var executedTasks: [Int] = []

        taskQueue.addTask {
            executedTasks.append(1)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            expectation1.fulfill()
        }

        taskQueue.addTask {
            executedTasks.append(2)
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate work
            expectation2.fulfill()
        }

        taskQueue.addTask {
            executedTasks.append(3)
            expectation3.fulfill()
        }

        // Wait for all expectations to be fulfilled with a timeout
        await fulfillment(of: [expectation1, expectation2, expectation3])

        // Assert that tasks were executed in the expected order
        XCTAssertEqual(executedTasks, [1, 2, 3], "Tasks executed in wrong order")
    }

    // Test that no more than maxConcurrentTasks are running at once
    func testTaskQueueRespectsMaxConcurrentTasks() async {
        let maxConcurrentTasks = 2
        let taskQueue = TaskQueue(maxConcurrentTasks: maxConcurrentTasks)
        var runningTasks = 0
        var completedTasks = 0
        func addTaskWithTracking(index: Int) {
            taskQueue.addTask {
                runningTasks += 1
                XCTAssertTrue(runningTasks <= maxConcurrentTasks)
                await self.wait(for: TimeInterval(index) * 0.2)
                runningTasks -= 1
            }
        }

        let totalTasks = 10
        await withTaskGroup(of: Void.self) { group in
            (1...totalTasks).forEach { index in
                group.addTask {
                    taskQueue.addTask {
                        runningTasks += 1
                        XCTAssertTrue(runningTasks <= maxConcurrentTasks)
                        await self.wait(for: TimeInterval(index) * 0.2)
                        runningTasks -= 1
                        completedTasks += 1
                    }
                }
            }
            await group.waitForAll()
        }
        await fulfillment { completedTasks == totalTasks }
    }
}
