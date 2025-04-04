//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class SerialActor_Tests: XCTestCase, @unchecked Sendable {

    private var subject: SerialActor! = .init()
    private var counter: Int = 0

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    // MARK: - execute

    func test_execute() async throws {
        let iterations = 10
        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<iterations {
                group.addTask {
                    try await self.subject.execute {
                        self.counter += 1
                    }
                }
            }

            try await group.waitForAll()
        }
        
        XCTAssertEqual(counter, 10)
    }

    // MARK: - cancel

    func test_cancel_cancelAllInflightTasks() async throws {
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                try? await self.subject.execute {
                    await self.wait(for: 0.5)
                    try Task.checkCancellation()
                    self.counter = -1
                }
            }

            group.addTask {
                await self.wait(for: 0.1)
                self.subject.cancel()
            }

            await group.waitForAll()
        }

        XCTAssertEqual(counter, 0)
    }
}
