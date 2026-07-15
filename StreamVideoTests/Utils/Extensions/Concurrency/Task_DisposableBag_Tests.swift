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
}
