//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCStatsReporter_Tests: XCTestCase {

    private var mockSFUAdapter: SFUAdapter!
    private var mockSFUService: MockSignalServer!
    private var mockWebSocketClient: MockWebSocketClient!
    private lazy var sessionID: String! = .unique
    private lazy var subject: WebRTCStatsReporter! = .init(
        interval: 2,
        sessionID: sessionID
    )

    override func setUp() {
        super.setUp()
        let mockSFUStack = SFUAdapter.mock(webSocketClientType: .sfu)
        mockSFUAdapter = mockSFUStack.sfuAdapter
        mockSFUService = mockSFUStack.mockService
        mockWebSocketClient = mockSFUStack.mockWebSocketClient

        mockWebSocketClient.simulate(state: .connected(healthCheckInfo: .init()))
    }

    override func tearDown() {
        sessionID = nil
        mockSFUAdapter = nil
        mockWebSocketClient = nil
        mockSFUService = nil
        subject = nil
        super.tearDown()
    }

    // MARK: -

    func test_sfuAdapterNil_reportWasNotCollectedAndSentCorrectly() async throws {
        await wait(for: subject.interval + 1)

        XCTAssertNil(mockSFUService.sendStatsWasCalledWithRequest)
    }

    func test_sfuAdapterNotNil_reportWasCollectedAndSentCorrectly() async throws {
        subject.sfuAdapter = mockSFUAdapter

        await wait(for: subject.interval + 1)

        let request = try XCTUnwrap(mockSFUService.sendStatsWasCalledWithRequest)
        XCTAssertTrue(request.subscriberStats.isEmpty)
        XCTAssertTrue(request.publisherStats.isEmpty)
        XCTAssertEqual(request.sessionID, sessionID)
    }

    func test_sfuAdapterNotNil_updateToAnotherSFUAdapter_firstReportCollectionIsCancelledAndOnlyTheSecondOneCompletes(
    ) async throws {
        subject.sfuAdapter = mockSFUAdapter
        await wait(for: subject.interval - 1)
        
        let sfuStack = SFUAdapter.mock(webSocketClientType: .sfu)
        subject.sfuAdapter = sfuStack.sfuAdapter
        sfuStack.mockWebSocketClient.simulate(state: .connected(healthCheckInfo: .init()))

        await wait(for: 1)
        XCTAssertNil(mockSFUService.sendStatsWasCalledWithRequest)
        XCTAssertNil(sfuStack.mockService.sendStatsWasCalledWithRequest)

        await wait(for: subject.interval)
        XCTAssertNil(mockSFUService.sendStatsWasCalledWithRequest)
        XCTAssertNotNil(sfuStack.mockService.sendStatsWasCalledWithRequest)
    }
}

extension XCTestCase {

    func wait(for interval: TimeInterval) async {
        let waitExpectation = expectation(description: "Waiting for \(interval) seconds...")
        waitExpectation.isInverted = true
        await fulfillment(of: [waitExpectation], timeout: interval)
    }
}
