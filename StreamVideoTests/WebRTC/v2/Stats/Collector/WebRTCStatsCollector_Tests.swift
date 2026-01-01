//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
@testable import StreamWebRTC
import XCTest

final class WebRTCStatsCollector_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var mockPublisher: MockRTCPeerConnectionCoordinator! = try! .init(
        peerType: .publisher,
        sfuAdapter: mockSFUStack.adapter
    )
    private lazy var mockSubscriber: MockRTCPeerConnectionCoordinator! = try! .init(
        peerType: .subscriber,
        sfuAdapter: mockSFUStack.adapter
    )
    private lazy var trackStorage: WebRTCTrackStorage! = .init()
    private lazy var interval: TimeInterval! = 1
    private lazy var subject: WebRTCStatsCollector! = .init(
        interval: interval,
        trackStorage: trackStorage
    )

    override func tearDown() async throws {
        subject = nil
        trackStorage = nil
        interval = nil
        mockSFUStack = nil
        try await super.tearDown()
    }

    func test_collectStats_generatesReportAndPublishesIt() async throws {
        trackStorage.addTrack(.dummy(kind: .audio, peerConnectionFactory: .mock()), type: .audio, for: "track-1")
        trackStorage.addTrack(.dummy(kind: .video, peerConnectionFactory: .mock()), type: .video, for: "track-2")
        mockPublisher.stub(for: .statsReport, with: StreamRTCStatisticsReport.dummy())
        mockSubscriber.stub(for: .statsReport, with: StreamRTCStatisticsReport.dummy())
        subject.publisher = mockPublisher
        subject.subscriber = mockSubscriber
        subject.sfuAdapter = mockSFUStack.adapter

        let publishedReport = try await subject
            .$report
            .compactMap { $0 }
            .nextValue(timeout: defaultTimeout)

        let report = try XCTUnwrap(publishedReport)
        XCTAssertEqual(report.datacenter, mockSFUStack.adapter.hostname)
        XCTAssertEqual(report.trackToKindMap, ["track-1": .audio, "track-2": .video])
    }

    func test_scheduleCollection_withZeroInterval_cancelsTimer() async throws {
        interval = 0
        trackStorage.addTrack(.dummy(kind: .audio, peerConnectionFactory: .mock()), type: .audio, for: "track-1")
        trackStorage.addTrack(.dummy(kind: .video, peerConnectionFactory: .mock()), type: .video, for: "track-2")
        mockPublisher.stub(for: .statsReport, with: StreamRTCStatisticsReport.dummy())
        mockSubscriber.stub(for: .statsReport, with: StreamRTCStatisticsReport.dummy())
        subject.publisher = mockPublisher
        subject.subscriber = mockSubscriber
        subject.sfuAdapter = mockSFUStack.adapter

        // Wait to ensure no report is published
        try await Task.sleep(nanoseconds: 500_000_000)

        // Since the timer should not run, report should remain nil
        let value = subject.report
        XCTAssertNil(value)
    }
}
