//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
@preconcurrency import XCTest

final class WebRTCStatsReporter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockPublisher: MockRTCPeerConnectionCoordinator! = try! MockRTCPeerConnectionCoordinator(
        peerType: .publisher,
        sfuAdapter: mockSFUStack.adapter
    )
    private lazy var mockSubscriber: MockRTCPeerConnectionCoordinator! = try! MockRTCPeerConnectionCoordinator(
        peerType: .subscriber,
        sfuAdapter: mockSFUStack.adapter
    )
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var sessionID: String! = .unique
    private lazy var input: WebRTCStatsReporter.Input! = .init(
        sessionID: sessionID,
        unifiedSessionID: .unique,
        report: .dummy(),
        peerConnectionTraces: [],
        encoderPerformanceStats: [],
        decoderPerformanceStats: [],
        onError: { _ in }
    )
    private lazy var subject: WebRTCStatsReporter! = .init(
        interval: 1,
        provider: { self.input }
    )

    override func setUp() {
        super.setUp()
        mockSFUStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))
    }

    override func tearDown() {
        mockPublisher = nil
        mockSubscriber = nil
        sessionID = nil
        mockSFUStack = nil
        subject = nil
        super.tearDown()
    }

    // MARK: - delivery

    func test_triggerDelivery_withoutSFU_doesNotRequestInput() {
        var providerCallsCount = 0
        subject = .init(interval: 100) {
            providerCallsCount += 1
            return nil
        }

        subject.triggerDelivery()
        subject.sfuAdapter = mockSFUStack.adapter
        subject.sfuAdapter = nil
        subject.triggerDelivery()

        XCTAssertEqual(providerCallsCount, 0)
    }

    func test_sfuAdapter_detached_doesNotRequestInputOnTimer() async {
        await assertDetachedTimerDoesNotRequestInput(changeInterval: false)
    }

    func test_interval_changedWhileDetached_doesNotRequestInputOnTimer() async {
        await assertDetachedTimerDoesNotRequestInput(changeInterval: true)
    }

    private func assertDetachedTimerDoesNotRequestInput(changeInterval: Bool) async {
        let timerStarted = expectation(description: "Attached reporter requested input")
        let inputRequested = expectation(description: "Detached reporter requested input")
        inputRequested.isInverted = true
        let inputRequests = PassthroughSubject<Void, Never>()
        let initialSubscription = inputRequests.prefix(1).sink { timerStarted.fulfill() }
        defer { initialSubscription.cancel() }
        subject = .init(interval: 0.01) {
            inputRequests.send(())
            return nil
        }
        subject.sfuAdapter = mockSFUStack.adapter

        await fulfillment(of: [timerStarted], timeout: 2)

        subject.sfuAdapter = nil
        if changeInterval {
            subject.interval = 0.02
        }
        let subscription = inputRequests.prefix(1).sink { inputRequested.fulfill() }
        defer { subscription.cancel() }

        // DefaultTimer allows one second of timer leeway.
        await fulfillment(of: [inputRequested], timeout: 2)
        subject.interval = 0
    }

    func test_sfuAdapter_reattached_resumesReporting() async {
        subject.sfuAdapter = mockSFUStack.adapter
        subject.sfuAdapter = nil
        subject.sfuAdapter = mockSFUStack.adapter
        subject.interval = 0.01

        await fulfillment {
            self.mockSFUStack.service.sendStatsWasCalledWithRequest != nil
        }
    }

    func test_sfuAdapterNil_reportWasNotSentCorrectly() async throws {
        await wait(for: subject.interval + 1)

        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
    }

    func test_sfuAdapterNotNil_reportWasSentCorrectly() async throws {
        subject.sfuAdapter = mockSFUStack.adapter

        await fulfillment { self.mockSFUStack.service.sendStatsWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    func test_sfuAdapterNotNil_thermalStateWillBeIncluded_reportWasSentCorrectly() async throws {
        InjectedValues[\.thermalStateObserver] = ThermalStateObserver { .critical }

        subject.sfuAdapter = mockSFUStack.adapter

        await fulfillment { self.mockSFUStack.service.sendStatsWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.deviceState?.thermalState, .critical)
    }

    func test_triggerDelivery_whileDeliveryIsActive_doesNotRequestNewInput() {
        mockSFUStack.service.sendStatsDelay = 1
        var providerCallsCount = 0
        subject = WebRTCStatsReporter(
            interval: 100,
            provider: {
                providerCallsCount += 1
                return self.input
            }
        )
        subject.sfuAdapter = mockSFUStack.adapter

        subject.triggerDelivery()
        subject.triggerDelivery()

        XCTAssertEqual(providerCallsCount, 1)
    }

    func test_sfuAdapterNotNil_updateToAnotherSFUAdapter_firstReportCollectionIsCancelledAndOnlyTheSecondOneCompletes(
    ) async throws {
        try XCTSkipIf(true, "https://linear.app/stream/issue/IOS-904/reenable-skipped-tests")
        let sfuStackA = MockSFUStack()
        let sfuStackB = MockSFUStack()

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.wait(for: 0.2)
                self.subject.sfuAdapter = sfuStackB.adapter
            }

            group.addTask {
                await self.wait(for: self.subject.interval)
                XCTAssertNil(sfuStackA.service.sendStatsWasCalledWithRequest)
                XCTAssertNil(sfuStackB.service.sendStatsWasCalledWithRequest)

                await self.fulfillment { sfuStackB.service.sendStatsWasCalledWithRequest != nil }
                XCTAssertNil(sfuStackA.service.sendStatsWasCalledWithRequest)
                XCTAssertNotNil(sfuStackB.service.sendStatsWasCalledWithRequest)
            }

            await group.waitForAll()
        }
    }

    // MARK: - setInterval

    func test_setInterval_withSFUAdapterIntervalMoreThanZero_reportWasCollectedAndSentCorrectly() async throws {
        subject.sfuAdapter = mockSFUStack.adapter
        subject.interval = 1

        await fulfillment { self.mockSFUStack.service.sendStatsWasCalledWithRequest != nil }

        let request = try XCTUnwrap(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    func test_setInterval_withSFUAdapterIntervalMoreThanZeroThenResetsToZero_secondReportWasNotCollectedAndSentCorrectly(
    ) async throws {
        subject.sfuAdapter = mockSFUStack.adapter
        subject.interval = 1
        await fulfillment { self.mockSFUStack.service.sendStatsWasCalledWithRequest != nil }
        subject.interval = 0
        mockSFUStack.service.sendStatsWasCalledWithRequest = nil

        await wait(for: subject.interval + 0.5)

        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
    }
}
