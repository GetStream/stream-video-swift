//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

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

    func test_sfuAdapterNotNil_updateToAnotherSFUAdapter_firstReportCollectionIsCancelledAndOnlyTheSecondOneCompletes(
    ) async throws {
        subject.sfuAdapter = mockSFUStack.adapter
        await wait(for: subject.interval - 0.5)

        let sfuStack = MockSFUStack()
        subject.sfuAdapter = sfuStack.adapter
        sfuStack.setConnectionState(to: .connected(healthCheckInfo: .init()))

        await wait(for: 0.5)
        XCTAssertNil(mockSFUStack.service.sendStatsWasCalledWithRequest)
        XCTAssertNil(sfuStack.service.sendStatsWasCalledWithRequest)

        await fulfillment { sfuStack.service.sendStatsWasCalledWithRequest != nil }
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
