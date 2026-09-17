//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class UnfairQueueTests: LogTestCase, @unchecked Sendable {

    private lazy var subject: UnfairQueue! = .init()
    private var sharedResource: Int! = 0

    // MARK: - Lifecycle

    override func tearDown() {
        subject = nil
        sharedResource = nil
        super.tearDown()
    }

    // MARK: - sync(_:)

    func test_sync_exclusiveAccess() {
        let iterations = 10
        let group = DispatchGroup()
        let queue = DispatchQueue(
            label: "io.getstream.UnfairQueueTests",
            attributes: .concurrent
        )
        // Swift tasks can share a thread, which is not the exclusion
        // this tests. Drive increments from a concurrent queue.
        for _ in 0..<iterations {
            group.enter()
            queue.async {
                self.subject.sync {
                    let currentValue = self.sharedResource!
                    self.sharedResource = currentValue + 1
                }
                group.leave()
            }
        }
        group.wait()
        XCTAssertEqual(sharedResource, iterations)
    }
}
