//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable @preconcurrency import StreamVideo
import XCTest

final class TimerPublisher_Tests: XCTestCase, @unchecked Sendable {

    private var disposableBag: DisposableBag! = .init()
    private var receivedDates: [Date]! = []

    // MARK: - Emits values while active subscriptions exist

    func test_receive_whenSubscribed_emitsDates() async {
        let expectation = expectation(description: "Should emit at least one value")

        let subject = TimerPublisher(interval: 0.2)

        subject
            .prefix(3)
            .sink { [weak self] date in
                self?.receivedDates.append(date)
                if self?.receivedDates.count == 3 {
                    expectation.fulfill()
                }
            }
            .store(in: disposableBag)

        await fulfillment(of: [expectation])
    }

    // MARK: - Suspends timer when all subscriptions are cancelled

    func test_receive_whenSubscriptionCancelled_timerSuspends() async throws {
        let subject = TimerPublisher(interval: 0.2)

        let expectation = expectation(description: "Timer should suspend after cancel")

        subject
            .sink { [weak self] in self?.receivedDates.append($0) }
            .store(in: disposableBag)

        Task {
            try? await Task.sleep(nanoseconds: 250_000_000)
            disposableBag.removeAll()

            try? await Task.sleep(nanoseconds: 350_000_000)
            let countAfterCancel = receivedDates.count

            try? await Task.sleep(nanoseconds: 200_000_000)
            XCTAssertEqual(receivedDates.count, countAfterCancel)
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 1)
    }

    // MARK: - Resumes timer after new subscription

    func test_receive_whenResubscribed_timerResumes() async {
        let subject = TimerPublisher(interval: 0.2)

        let expectation = expectation(description: "Should receive values after resubscription")

        var cancellable = subject
            .log(.debug) { "Received value: \($0.millisecondsSince1970)" }
            .sink { [weak self] in self?.receivedDates.append($0) }

        await wait(for: 0.25)
        cancellable.cancel()

        XCTAssertEqual(receivedDates.count, 1)

        receivedDates = []

        await wait(for: 0.25)
        XCTAssertTrue(receivedDates.isEmpty)

        cancellable = subject
            .prefix(2)
            .sink { [weak self] in
                self?.receivedDates.append($0)
                if self?.receivedDates.count == 2 {
                    expectation.fulfill()
                }
            }

        await fulfillment(of: [expectation])
    }
}
