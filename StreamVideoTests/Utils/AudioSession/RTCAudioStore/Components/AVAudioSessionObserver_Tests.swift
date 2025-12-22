//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Combine
import StreamSwiftTestHelpers
@testable import StreamVideo
import XCTest

final class AVAudioSessionObserver_Tests: XCTestCase, @unchecked Sendable {

    private var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        cancellables = []
    }

    override func tearDown() {
        cancellables = nil
        super.tearDown()
    }

    func test_startObserving_emitsSnapshotsFromTimer() async {
        let observer = AVAudioSessionObserver()
        let expectation = expectation(description: "snapshots")
        expectation.expectedFulfillmentCount = 2

        observer.publisher
            .prefix(2)
            .sink { snapshot in
                XCTAssertEqual(snapshot.category, AVAudioSession.sharedInstance().category)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        observer.startObserving()

        await fulfillment(of: [expectation], timeout: 1)
        observer.stopObserving()
    }

    func test_stopObserving_preventsFurtherEmissions() async throws {
        try XCTSkipIf(
            TestRunnerEnvironment.isCI,
            "https://linear.app/stream/issue/IOS-1326/cifix-failing-test-on-ios-15-and-16-only-which-passes-locally"
        )
        let observer = AVAudioSessionObserver()
        let firstTwo = expectation(description: "first snapshots")
        let noMoreSnapshots = expectation(description: "no extra snapshots")
        noMoreSnapshots.isInverted = true

        observer.publisher
            .prefix(2)
            .sink(
                receiveCompletion: { _ in firstTwo.fulfill() },
                receiveValue: { _ in }
            )
            .store(in: &cancellables)

        observer.publisher
            .dropFirst(2)
            .sink { _ in noMoreSnapshots.fulfill() }
            .store(in: &cancellables)

        observer.startObserving()
        await fulfillment(of: [firstTwo], timeout: 1)

        observer.stopObserving()
        await fulfillment(of: [noMoreSnapshots], timeout: 0.3)
    }
}
