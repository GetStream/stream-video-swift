//
//  SerialActor_Tests.swift
//  StreamVideoTests
//
//  Created by Ilias Pavlidakis on 4/10/23.
//

import Foundation
import XCTest
@testable import StreamVideo

final class SerialActor_Tests: XCTestCase {

    private var count = 0

    // Test to ensure tasks are executed serially.
    func testSerialExecution() async throws {
        let actor = SerialActor()

        let expectationA = expectation(description: "Task A")
        let expectationB = expectation(description: "Task B")

        let incrementCount: @Sendable (XCTestExpectation) async throws -> Void = { [weak self] expectation in
            for _ in 0..<10 {
                self?.count += 1
                try await Task.sleep(nanoseconds: 1_000_000)  // Sleep for 1ms
            }
            expectation.fulfill()
        }

        // Enqueue two tasks.
        try await actor.enqueue { try await incrementCount(expectationA) }
        try await actor.enqueue { try await incrementCount(expectationB) }

        await fulfillment(of: [expectationA, expectationB], timeout: defaultTimeout)

        // Assert that count is incremented to 20 after both tasks.
        XCTAssertEqual(count, 20)
    }
}

