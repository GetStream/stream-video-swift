//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class WebRTCStatsAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var trackStorage: WebRTCTrackStorage! = .init()
    private lazy var mockCollector: MockWebRTCStatsCollector! = .init()
    private lazy var mockReporter: MockWebRTCStatsReporter! = .init()
    private lazy var mockTraces: MockWebRTCTracesAdapter! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var subject: WebRTCStatsAdapter! = .init(
        sessionID: .unique,
        unifiedSessionID: .unique,
        isTracingEnabled: true,
        trackStorage: trackStorage,
        collector: mockCollector,
        reporter: mockReporter,
        traces: mockTraces
    )

    override func tearDown() {
        subject = nil
        mockCollector = nil
        mockReporter = nil
        mockTraces = nil
        trackStorage = nil
        mockSFUStack = nil
        super.tearDown()
    }

    // MARK: - Tests

    func test_scheduleStatsReporting_triggersReporter() {
        subject.scheduleStatsReporting()

        XCTAssertEqual(mockReporter.timesCalled(.triggerDelivery), 1)
    }

    func test_trace_forwardsToTracesAdapter() {
        let trace = WebRTCTrace(id: "id", tag: "tag", data: nil, timestamp: 123)
        subject.trace(trace)
        let called = mockTraces.stubbedFunctionInput[.trace]?.compactMap {
            if case let .trace(t) = $0 { return t } else { return nil }
        }
        XCTAssertTrue(called?.contains(trace) ?? false)
    }

    func test_setPublisher_setsOnCollectorAndTraces() throws {
        let mockPub = try MockRTCPeerConnectionCoordinator(
            peerType: .publisher,
            sfuAdapter: mockSFUStack.adapter
        )
        subject.publisher = mockPub
        XCTAssertTrue(mockCollector.publisher === mockPub)
        XCTAssertTrue(mockTraces.publisher === mockPub)
    }

    func test_setSubscriber_setsOnCollectorAndTraces() throws {
        let mockSub = try MockRTCPeerConnectionCoordinator(
            peerType: .subscriber,
            sfuAdapter: mockSFUStack.adapter
        )
        subject.subscriber = mockSub
        XCTAssertTrue(mockCollector.subscriber === mockSub)
        XCTAssertTrue(mockTraces.subscriber === mockSub)
    }

    func test_setSFU_setsOnCollectorReporterTraces() {
        let sfu = mockSFUStack.adapter
        subject.sfuAdapter = sfu
        XCTAssertTrue(mockCollector.sfuAdapter === sfu)
        XCTAssertTrue(mockReporter.sfuAdapter === sfu)
        XCTAssertTrue(mockTraces.sfuAdapter === sfu)
    }

    func test_deliveryInterval_setsReporterInterval() {
        subject.deliveryInterval = 42
        XCTAssertEqual(mockReporter.interval, 42)
    }

    func test_isTracingEnabled_setsTracesIsEnabled() {
        subject.isTracingEnabled = false
        XCTAssertFalse(mockTraces.isEnabled)
        subject.isTracingEnabled = true
        XCTAssertTrue(mockTraces.isEnabled)
    }
}
