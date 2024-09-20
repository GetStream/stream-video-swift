//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

final class TaskQueue {
    // A serial DispatchQueue to ensure thread-safe access to the queue
    private let queue = DispatchQueue(label: "io.getstream.taskqueue")
    private var taskQueue: [() async -> Void] = []

    // Maximum number of concurrent tasks
    private let maxConcurrentTasks: Int

    // Number of currently executing tasks
    private var runningTasks = 0

    // Initializer to set the maxConcurrentTasks
    init(maxConcurrentTasks: Int = 1) {
        self.maxConcurrentTasks = maxConcurrentTasks
    }

    // Function to add a new Task to the queue
    func addTask(operation: @escaping () async -> Void) {
        queue.sync {
            taskQueue.append(operation)
            checkAndStartTasks()
        }
    }

    // Function to check and start tasks if conditions are met
    private func checkAndStartTasks() {
        queue.async {
            while self.runningTasks < self.maxConcurrentTasks, !self.taskQueue.isEmpty {
                let operation = self.taskQueue.removeFirst()
                self.runningTasks += 1

                // Start the task
                Task {
                    await operation()
                    self.taskDidComplete()
                }
            }
        }
    }

    // Function to be called when a task completes
    private func taskDidComplete() {
        queue.async {
            self.runningTasks -= 1
            self.checkAndStartTasks() // Start next task if available
        }
    }

    func removeAll() {
        queue.sync {
            taskQueue = []
            checkAndStartTasks()
        }
    }
}
