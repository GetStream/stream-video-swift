//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

actor SerialActor: @unchecked Sendable {
    // The underlying serial queue and custom executor
    private let serialExecutor: DispatchQueueExecutor

    init(file: StaticString = #file) {
        self.serialExecutor = .init(queue: DispatchQueue(label: "io.getstream.serial.actor.\(file)"))
    }

    deinit {
        print("SerialActor deinitialized")
    }

    // Conform to the new SerialExecutor protocol
    nonisolated var unownedExecutor: UnownedSerialExecutor {
        serialExecutor.asUnownedSerialExecutor()
    }

    /// Schedules the block to run serially on the actor's executor.
    func execute<T: Sendable>(
        _ block: @Sendable @escaping () async throws -> T
    ) async rethrows -> T {
        try await block()
    }

    nonisolated func cancel() {
        // TODO:
    }
}

final class DispatchQueueExecutor: SerialExecutor, @unchecked Sendable {
    private final class CancelToken: @unchecked Sendable {
        private(set) var isCancelled = false
        func cancel() { isCancelled = true }
    }

    private let queue: DispatchQueue
    @Atomic private var enqueuedJobs: [UUID: CancelToken] = [:]

    convenience init(file: StaticString = #file) {
        self.init(queue: DispatchQueue(label: "io.getstream.serial.actor.\(file)"))
    }

    init(queue: DispatchQueue) {
        self.queue = queue
    }

    func enqueue(_ job: UnownedJob) {
        let identifier = UUID()
        enqueuedJobs[identifier] = CancelToken()

        queue.async { [weak self] in
            guard
                let self,
                enqueuedJobs[identifier]?.isCancelled == false
            else { return }

            job.runSynchronously(on: self.asUnownedSerialExecutor())

            enqueuedJobs.removeValue(forKey: identifier)
        }
    }

    func asUnownedSerialExecutor() -> UnownedSerialExecutor {
        UnownedSerialExecutor(ordinary: self)
    }

    func checkIsolated() {
        dispatchPrecondition(condition: .onQueue(queue))
    }

    func cancelAll() { enqueuedJobs.removeAll() }
}
