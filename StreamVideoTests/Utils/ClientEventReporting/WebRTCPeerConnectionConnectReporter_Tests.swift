//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class WebRTCPeerConnectionConnectReporter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var stateSubject: CurrentValueSubject<RTCPeerConnectionState, Never>! = .init(.new)
    private lazy var iceStateSubject: CurrentValueSubject<RTCIceConnectionState, Never>! = .init(.new)
    private lazy var mockReporter: MockClientEventReporter! = .init()
    private var subject: WebRTCPeerConnectionConnectReporter!

    override func tearDown() {
        subject = nil
        stateSubject = nil
        iceStateSubject = nil
        mockReporter = nil
        super.tearDown()
    }

    private func makeSubject(
        peerConnectionType: PeerConnectionType = .publisher,
        wasPreviouslyConnected: Bool = false
    ) {
        subject = .init(
            peerConnectionType: peerConnectionType,
            statePublisher: stateSubject.eraseToAnyPublisher(),
            iceStatePublisher: iceStateSubject.eraseToAnyPublisher(),
            reporter: mockReporter,
            wasPreviouslyConnected: wasPreviouslyConnected,
            details: .init(
                sfuId: "sfu-1",
                coordinatorConnectId: "85e8b199-d4ab-4eb7-a681-1d6916a86906"
            )
        )
    }

    func test_whenStateStaysNew_doesNotReportAnything() async {
        makeSubject()

        // Allow the observation task to spin up.
        try? await Task.sleep(nanoseconds: 200_000_000)

        let begun = await mockReporter.begunStages
        let completed = await mockReporter.completedStages
        XCTAssertTrue(begun.isEmpty)
        XCTAssertTrue(completed.isEmpty)
    }

    func test_whenConnecting_reportsInitiatedWithPublishMapping() async {
        makeSubject(peerConnectionType: .publisher, wasPreviouslyConnected: true)

        stateSubject.send(.connecting)

        await waitUntil { await self.mockReporter.begunStages.count == 1 }
        let begun = await mockReporter.begunStages.first
        XCTAssertEqual(begun?.stage, .peerConnectionConnect)
        XCTAssertEqual(begun?.peerConnection, .publish)
        XCTAssertEqual(begun?.details.wasPreviouslyConnected, true)
        XCTAssertEqual(begun?.details.sfuId, "sfu-1")
    }

    func test_whenConnected_reportsInitiatedThenSuccessfulCompletion() async {
        makeSubject(peerConnectionType: .subscriber)

        stateSubject.send(.connecting)
        stateSubject.send(.connected)
        iceStateSubject.send(.connected)

        await waitUntil { await self.mockReporter.completedStages.count == 1 }
        let begun = await mockReporter.begunStages
        let completed = await mockReporter.completedStages
        XCTAssertEqual(begun.count, 1)
        XCTAssertEqual(begun.first?.peerConnection, .subscribe)
        XCTAssertEqual(completed.first?.outcome, .success)
        XCTAssertEqual(completed.first?.details.iceState, .connected)
    }

    func test_whenConnectionConnectedButIceNotConnected_doesNotComplete() async {
        makeSubject()

        stateSubject.send(.connecting)
        stateSubject.send(.connected)

        try? await Task.sleep(nanoseconds: 200_000_000)
        let completed = await mockReporter.completedStages
        XCTAssertTrue(completed.isEmpty)
    }

    func test_whenConnectionFailedWithDisconnectedICE_reportsFailureCompletionWithoutFailureCode() async {
        makeSubject()

        stateSubject.send(.connecting)
        iceStateSubject.send(.disconnected)
        stateSubject.send(.failed)

        await waitUntil { await self.mockReporter.completedStages.count == 1 }
        let completed = await mockReporter.completedStages.first
        XCTAssertEqual(completed?.outcome, .failure)
        XCTAssertEqual(completed?.details.iceState, .failed)
        XCTAssertNil(completed?.failure)
    }

    func test_whenICEFailedBeforeConnectionConnected_reportsFailureCompletionWithICEFailure() async {
        makeSubject()

        stateSubject.send(.connecting)
        iceStateSubject.send(.checking)
        iceStateSubject.send(.failed)

        await waitUntil { await self.mockReporter.completedStages.count == 1 }
        let completed = await mockReporter.completedStages.first
        XCTAssertEqual(completed?.outcome, .failure)
        XCTAssertEqual(completed?.details.iceState, .failed)
        XCTAssertEqual(completed?.failure?.code, ClientEventFailureCode.iceConnectivityFailed.rawValue)
    }

    func test_jumpStraightToConnected_stillReportsInitiatedAndCompletion() async {
        makeSubject()

        // No `.connecting` intermediate state.
        stateSubject.send(.connected)
        iceStateSubject.send(.connected)

        await waitUntil { await self.mockReporter.completedStages.count == 1 }
        let begun = await mockReporter.begunStages
        XCTAssertEqual(begun.count, 1)
        let completed = await mockReporter.completedStages.first
        XCTAssertEqual(completed?.outcome, .success)
    }

    // MARK: - Helpers

    /// Polls `block` until it returns `true` (bounded), keeping observation
    /// deterministic in an async context.
    private func waitUntil(_ block: @escaping () async -> Bool) async {
        for _ in 0..<200 where await !block() {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
    }
}
