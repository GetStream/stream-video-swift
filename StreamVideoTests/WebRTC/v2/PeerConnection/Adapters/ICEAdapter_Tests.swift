//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class ICEAdapterTests: XCTestCase {

    private lazy var sessionId: String! = .unique
    private lazy var mockPeerConnection: MockRTCPeerConnection! = .init()
    private lazy var mockSFUStack: MockSFUStack! = .init()
    private lazy var subject: ICEAdapter! = .init(
        sessionID: sessionId,
        peerType: .publisher,
        peerConnection: mockPeerConnection,
        sfuAdapter: mockSFUStack.adapter
    )

    private lazy var iceCandidate: RTCIceCandidate! = .init(
        sdp: """
        {
            "candidate": "test-candidate-sdp"
        }
        """,
        sdpMLineIndex: 0,
        sdpMid: nil
    )

    override func tearDown() {
        subject = nil
        iceCandidate = nil
        subject = nil
        mockSFUStack = nil
        mockPeerConnection = nil
        sessionId = nil
        super.tearDown()
    }

    // MARK: - trickle(_:)

    func test_trickle_connected_calledWithCandidate_tricklesToSFU() async throws {
        // Given
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))

        // When
        await subject.trickle(iceCandidate)
        await fulfillment { [service = mockSFUStack.service] in
            service.iCETrickleWasCalledWithRequest != nil
        }

        // Then
        let request = try XCTUnwrap(mockSFUStack.service.iCETrickleWasCalledWithRequest)
        XCTAssertEqual(request.peerType, .publisherUnspecified)
        XCTAssertEqual(request.sessionID, sessionId)
        XCTAssertFalse(request.iceCandidate.isEmpty)
    }

    func test_trickle_disconnected_calledWithCandidate_tricklesToSFU() async throws {
        // Given
        mockSFUStack.setConnectionState(to: .disconnected(source: .userInitiated))

        // When
        await subject.trickle(iceCandidate)
        await wait(for: 1)

        // Then
        XCTAssertNil(mockSFUStack.service.iCETrickleWasCalledWithRequest)
    }

    // MARK: - add(_:)

    func test_add_peerConnectionWithoutRemoteDescription_noTaskWasTriggered() async throws {
        await subject.add(iceCandidate)

        await wait(for: 1)
        XCTAssertNil(mockSFUStack.service.iCETrickleWasCalledWithRequest)
    }

    func test_add_peerConnectionWithRemoteDescription_taskWasTriggered() async throws {
        _ = subject
        await wait(for: 1) // Wait for object configuration to complete.
        mockPeerConnection.remoteDescription = .init(type: .offer, sdp: "")

        await subject.add(iceCandidate)

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection!.timesCalled(.addCandidate) > 0
        }

        XCTAssertEqual(mockPeerConnection.timesCalled(.addCandidate), 1)
    }
}
