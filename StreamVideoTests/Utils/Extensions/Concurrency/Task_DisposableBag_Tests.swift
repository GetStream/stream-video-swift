//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class Task_DisposableBag_Tests: XCTestCase, @unchecked Sendable {

    func test_init_taskCompletes_removesTaskFromBag() async {
        let subject = DisposableBag()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = Task(disposableBag: subject) {
            for await _ in stream {
                return
            }
        }

        XCTAssertFalse(subject.isEmpty)

        continuation.yield()
        continuation.finish()
        await task.value

        XCTAssertTrue(subject.isEmpty)
    }

    /// Off an actor, a task body can finish before the initializer stores
    /// the task in the bag.
    func test_init_tasksFinishBeforeTheyAreStored_bagEndsEmpty() async {
        let subject = DisposableBag()

        // One creator leaves idle threads that can run a body at once.
        await Task.detached {
            var tasks: [Task<Void, Never>] = []
            for _ in 0..<50000 {
                tasks.append(Task(disposableBag: subject) {})
            }
            for task in tasks {
                await task.value
            }
        }.value

        XCTAssertTrue(subject.isEmpty)
    }

    func test_init_removeAll_cancelsTask() async {
        let subject = DisposableBag()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = Task(disposableBag: subject) {
            for await _ in stream {}
        }

        subject.removeAll()

        XCTAssertTrue(task.isCancelled)
        continuation.finish()
        await task.value
        XCTAssertTrue(subject.isEmpty)
    }

    func test_init_throwingTaskCompletes_removesTaskFromBag() async throws {
        let subject = DisposableBag()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = Task(disposableBag: subject) { () async throws -> Int in
            for await _ in stream {
                return 42
            }
            throw CancellationError()
        }

        XCTAssertFalse(subject.isEmpty)
        continuation.yield()
        continuation.finish()
        let value = try await task.value

        XCTAssertEqual(value, 42)
        XCTAssertTrue(subject.isEmpty)
    }

    func test_store_withoutIdentifier_removeAllCancelsTask() async {
        let subject = DisposableBag()
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        let task = Task {
            for await _ in stream {}
        }
        task.store(in: subject)

        subject.removeAll()

        XCTAssertTrue(task.isCancelled)
        continuation.finish()
        await task.value
        XCTAssertTrue(subject.isEmpty)
    }
}
