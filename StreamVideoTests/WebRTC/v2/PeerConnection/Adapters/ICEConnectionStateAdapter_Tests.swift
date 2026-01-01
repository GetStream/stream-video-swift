//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class ICEConnectionStateAdapter_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var mockRTCPeerConnectionCoordinator: MockRTCPeerConnectionCoordinator! = try! .init(
        peerType: .publisher,
        sfuAdapter: mockSFUStack.adapter,
        iceConnectionStateAdapter: subject
    )
    private lazy var subject: ICEConnectionStateAdapter! = .init(
        scheduleICERestartInterval: 1
    )

    override func setUp() {
        super.setUp()
        _ = subject
    }

    override func tearDown() {
        subject = nil
        mockRTCPeerConnectionCoordinator = nil
        mockSFUStack = nil
        super.tearDown()
    }

    func test_didUpdate_givenStateIsConnected_whenInvoked_thenCancelsScheduledICE() async {
        mockRTCPeerConnectionCoordinator
            .stubEventSubject
            .send(StreamRTCPeerConnection.ICEConnectionChangedEvent(state: .disconnected))
        await wait(for: 0.1)

        mockRTCPeerConnectionCoordinator
            .stubEventSubject
            .send(StreamRTCPeerConnection.ICEConnectionChangedEvent(state: .connected))

        await wait(for: 1)
        XCTAssertEqual(mockRTCPeerConnectionCoordinator.timesCalled(.restartICE), 0)
    }

    func test_didUpdate_givenStateIsDisconnected_whenInvoked_thenSchedulesRestartICE() async {
        mockRTCPeerConnectionCoordinator
            .stubEventSubject
            .send(StreamRTCPeerConnection.ICEConnectionChangedEvent(state: .disconnected))
        await wait(for: 1)

        XCTAssertEqual(mockRTCPeerConnectionCoordinator.timesCalled(.restartICE), 1)
    }

    func test_didUpdate_givenStateIsFailed_whenInvoked_thenRestartsICEImmediately() async {
        mockRTCPeerConnectionCoordinator
            .stubEventSubject
            .send(StreamRTCPeerConnection.ICEConnectionChangedEvent(state: .failed))

        await fulfillment { self.mockRTCPeerConnectionCoordinator.timesCalled(.restartICE) == 1 }
    }
}
