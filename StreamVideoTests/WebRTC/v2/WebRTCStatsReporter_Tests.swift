//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@preconcurrency import XCTest

final class WebRTCStatsReporter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var sessionID: String! = .unique
    private lazy var subject: WebRTCStatsReporter! = .init(
        interval: 2,
        sessionID: sessionID
    )

    override func setUp() {
        super.setUp()
        mockSFUStack
            .setConnectionState(to: .connected(healthCheckInfo: .init()))
    }

    override func tearDown() {
        sessionID = nil
        mockSFUStack = nil
        subject = nil
        super.tearDown()
    }

    // MARK: -

    func test_sfuAdapterNil_reportWasNotCollectedAndSentCorrectly() async throws {
        await wait(for: subject.interval + 1)

        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
    }

    func test_sfuAdapterNotNil_reportWasCollectedAndSentCorrectly() async throws {
        subject.sfuAdapter = mockSFUStack.adapter

        await wait(for: subject.interval + 1)

        let request = try XCTUnwrap(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    func test_sfuAdapterNotNil_thermalStateWillBeIncluded_reportWasCollectedAndSentCorrectly() async throws {
        InjectedValues[\.thermalStateObserver] = ThermalStateObserver { .critical }

        subject.sfuAdapter = mockSFUStack.adapter

        await wait(for: subject.interval + 1)

        let request = try XCTUnwrap(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
        XCTAssertEqual(request.deviceState?.thermalState, .critical)
    }

    func test_sfuAdapterNotNil_updateToAnotherSFUAdapter_firstReportCollectionIsCancelledAndOnlyTheSecondOneCompletes(
    ) async throws {
        subject.sfuAdapter = mockSFUStack.adapter
        await wait(for: subject.interval - 1)
        
        let sfuStack = MockSFUStack()
        subject.sfuAdapter = sfuStack.adapter
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))

        await wait(for: 1)
        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertNil(sfuStack.service.sendStatsWasCalledWithRequest)

        await wait(for: subject.interval)
        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertNotNil(sfuStack.service.sendStatsWasCalledWithRequest)
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

extension XCTestCase {

    func wait(for interval: TimeInterval) async {
        let waitExpectation = expectation(description: "Waiting for \(interval) seconds...")
        waitExpectation.isInverted = true
        await fulfillment(of: [waitExpectation], timeout: interval)
    }
}
