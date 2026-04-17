//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import XCTest

final class WebRTCTracesAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var reportSubject: PassthroughSubject<CallStatsReport, Never>! = .init()
    private lazy var disposableBag: DisposableBag! = .init()
    private lazy var subject: WebRTCTracesAdapter! = .init(latestReportPublisher: reportSubject.eraseToAnyPublisher())

    override func tearDown() {
        subject = nil
        reportSubject = nil
        disposableBag = nil
        super.tearDown()
    }

    func test_trace_withPeerConnectionId_goesToPeerConnectionBucket() throws {
        let expected = WebRTCTrace.dummy(id: "peer-id", tag: "offer")

        subject.trace(expected)

        let flushed = subject.flushTraces()
        XCTAssertEqual(flushed.endIndex, 3)
        let actual = try XCTUnwrap(flushed.first(where: { $0.tag == "offer" }))
        XCTAssertEqual(actual, expected)
    }

    func test_trace_withNilId_goesToSFUBucket() throws {
        let expected = WebRTCTrace.dummy(id: nil, tag: "sfu-event")

        subject.trace(expected)

        let flushed = subject.flushTraces()
        XCTAssertEqual(flushed.endIndex, 3)
        let actual = try XCTUnwrap(flushed.first(where: { $0.tag == "sfu-event" }))
        XCTAssertEqual(actual, expected)
    }

    func test_flushTraces_clearsBothBuckets() throws {
        let trace1 = WebRTCTrace.dummy(id: "peer1", tag: "t1")
        let trace2 = WebRTCTrace.dummy(id: nil, tag: "t2")

        subject.trace(trace1)
        subject.trace(trace2)

        let allTraces = subject.flushTraces()
        XCTAssertEqual(allTraces.count, 4)

        XCTAssertTrue(subject.flushTraces().isEmpty)
    }

    func test_isEnabled_false_flushesAllBuckets() throws {
        let trace1 = WebRTCTrace.dummy(id: "peerX", tag: "test")
        let trace2 = WebRTCTrace.dummy(id: nil, tag: "test2")

        subject.trace(trace1)
        subject.trace(trace2)

        subject.isEnabled = false

        XCTAssertTrue(subject.flushTraces().isEmpty)
        XCTAssertTrue(subject.flushEncoderPerformanceStats().isEmpty)
        XCTAssertTrue(subject.flushDecoderPerformanceStats().isEmpty)
    }

    func test_restore_insertsPeerConnectionTracesAtFront() throws {
        let trace1 = WebRTCTrace.dummy(id: "peerA", tag: "foo")
        let trace2 = WebRTCTrace.dummy(id: "peerA", tag: "bar")
        let trace3 = WebRTCTrace.dummy(id: "peerA", tag: "baz")

        subject.trace(trace3)
        subject.restore([trace1, trace2])

        let traces = subject.flushTraces()

        guard let idx1 = traces.firstIndex(where: { $0.tag == "foo" }),
              let idx2 = traces.firstIndex(where: { $0.tag == "bar" }),
              let idx3 = traces.firstIndex(where: { $0.tag == "baz" }) else {
            XCTFail("Restored traces not found")
            return
        }
        XCTAssertTrue(idx1 < idx3 && idx2 < idx3)
    }

    func test_publisher_whenSameCoordinatorIsReassigned_doesNotEmitDuplicateCreateTrace_() throws {
        let coordinator = try makeCoordinator(peerType: .publisher)

        subject.publisher = coordinator

        XCTAssertEqual(createTraces(for: "publisher", in: subject.flushTraces()).count, 1)

        subject.publisher = coordinator

        XCTAssertTrue(createTraces(for: "publisher", in: subject.flushTraces()).isEmpty)
    }

    func test_subscriber_whenSameCoordinatorIsReassigned_doesNotEmitDuplicateCreateTrace_() throws {
        let coordinator = try makeCoordinator(peerType: .subscriber)

        subject.subscriber = coordinator

        XCTAssertEqual(createTraces(for: "subscriber", in: subject.flushTraces()).count, 1)

        subject.subscriber = coordinator

        XCTAssertTrue(createTraces(for: "subscriber", in: subject.flushTraces()).isEmpty)
    }

    func test_publisher_whenCoordinatorChanges_emitsCreateTraceForReplacement_() throws {
        let first = try makeCoordinator(peerType: .publisher)
        let second = try makeCoordinator(peerType: .publisher)

        subject.publisher = first
        _ = subject.flushTraces()

        subject.publisher = second

        XCTAssertEqual(createTraces(for: "publisher", in: subject.flushTraces()).count, 1)
    }

    func test_subscriber_whenCleared_stopsObservingEventsFromPreviousCoordinator_() throws {
        let coordinator = try makeCoordinator(peerType: .subscriber)

        subject.subscriber = coordinator
        _ = subject.flushTraces()

        subject.subscriber = nil
        coordinator.stubEventSubject.send(StreamRTCPeerConnection.CloseEvent())

        XCTAssertFalse(
            subject.flushTraces().contains {
                $0.id == "subscriber" && $0.tag == "close"
            }
        )
    }

    // MARK: - Helpers

    private func makeCoordinator(
        peerType: PeerConnectionType
    ) throws -> MockRTCPeerConnectionCoordinator {
        let sfuStack = MockSFUStack()
        return try XCTUnwrap(
            MockRTCPeerConnectionCoordinator(
                peerType: peerType,
                sfuAdapter: sfuStack.adapter
            )
        )
    }

    private func createTraces(
        for id: String,
        in traces: [WebRTCTrace]
    ) -> [WebRTCTrace] {
        traces.filter { $0.id == id && $0.tag == "create" }
    }
}
