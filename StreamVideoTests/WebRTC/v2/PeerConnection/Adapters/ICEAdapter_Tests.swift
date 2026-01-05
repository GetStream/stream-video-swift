//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class ICEAdapterTests: XCTestCase, @unchecked Sendable {

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
        try await assertSFUTrickleTriggered(
            connectionState: .connected(healthCheckInfo: .init()),
            { await self.subject.trickle(self.iceCandidate) }
        ) { request in
            XCTAssertEqual(request.peerType, .publisherUnspecified)
            XCTAssertEqual(request.sessionID, self.sessionId)
            XCTAssertFalse(request.iceCandidate.isEmpty)
        }
    }

    func test_trickle_disconnected_calledWithCandidate_doesNotTrickleToSFU() async throws {
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
        mockPeerConnection.stub(for: \.remoteDescription, with: RTCSessionDescription(type: .offer, sdp: ""))

        await subject.add(iceCandidate)

        await fulfillment { [mockPeerConnection] in
            mockPeerConnection!.timesCalled(.addCandidate) > 0
        }

        XCTAssertEqual(mockPeerConnection.timesCalled(.addCandidate), 1)
    }

    // MARK: - didGenerateICECandidateEvent

    func test_didGenerateICECandidateEvent_eventReceivedWhileConnecting_tricklesToSFU() async throws {
        try await assertSFUTrickleTriggered(
            connectionState: .connected(healthCheckInfo: .init()),
            {
                self
                    .mockPeerConnection
                    .subject
                    .send(
                        StreamRTCPeerConnection.DidGenerateICECandidateEvent(
                            candidate: self.iceCandidate
                        )
                    )
            }
        ) { request in
            XCTAssertEqual(request.peerType, .publisherUnspecified)
            XCTAssertEqual(request.sessionID, self.sessionId)
            XCTAssertFalse(request.iceCandidate.isEmpty)
        }
    }

    // MARK: - hasRemoteDescription

    func test_hasRemoteDescriptionEvent_eventReceived_addsTrickledCandidatesOnPeerConnection() async throws {
        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))
        _ = subject
        await wait(for: 0.5)
        var candidate = Stream_Video_Sfu_Models_ICETrickle()
        candidate.iceCandidate = iceCandidate.sdp
        mockSFUStack.receiveEvent(.sfuEvent(.iceTrickle(candidate)))
        await wait(for: 1.0) // Wait until the event has been processed from the ICEAdapter

        mockPeerConnection
            .subject
            .send(StreamRTCPeerConnection.HasRemoteDescription(sessionDescription: .init(type: .answer, sdp: .unique)))

        await fulfillment { self.mockPeerConnection.timesCalled(.addCandidate) == 1 }
    }

    // MARK: - connectionState

    func test_connectionState_whileDisconnectedTrickles_whenConnectedWillTrickleAnyUntrickledCandidates() async throws {
        mockSFUStack.setConnectionState(to: .disconnected(source: .noPongReceived))
        _ = subject
        await wait(for: 0.5)
        await subject.trickle(iceCandidate)
        await wait(for: 1)
        XCTAssertNil(mockSFUStack.service.iCETrickleWasCalledWithRequest)

        mockSFUStack.setConnectionState(to: .connected(healthCheckInfo: .init()))

        await fulfillment { self.mockSFUStack.service.iCETrickleWasCalledWithRequest != nil }
    }

    // MARK: - iCETrickle

    func test_iCETrickle_eventReceived_candidateIsAddedOnPeerConnection() async throws {
        _ = subject
        await wait(for: 0.5)
        mockPeerConnection.stub(
            for: \.remoteDescription,
            with: RTCSessionDescription(
                type: .answer,
                sdp: .unique
            )
        )

        var event = Stream_Video_Sfu_Models_ICETrickle()
        let sdp = String.unique
        event.iceCandidate = """
        {
            "candidate":"\(sdp)"
        }
        """
        event.sessionID = .unique
        mockSFUStack.receiveEvent(.sfuEvent(.iceTrickle(event)))

        await fulfillment { self.mockPeerConnection.timesCalled(.addCandidate) == 1 }
        let candidate = try XCTUnwrap(
            mockPeerConnection.recordedInputPayload(
                RTCIceCandidate.self,
                for: .addCandidate
            )?.first
        )
        XCTAssertEqual(candidate.sdp, sdp)
        XCTAssertEqual(candidate.sdpMLineIndex, 0)
        XCTAssertNil(candidate.sdpMid)
    }

    // MARK: - Private helpers

    private func assertSFUTrickleTriggered(
        connectionState: WebSocketConnectionState,
        file: StaticString = #file,
        line: UInt = #line,
        _ operation: @escaping () async throws -> Void,
        _ validationHandler: @escaping (Stream_Video_Sfu_Models_ICETrickle) -> Void
    ) async throws {
        _ = subject
        await wait(for: 0.5)
        mockSFUStack.setConnectionState(to: connectionState)

        // When
        try await operation()
        await fulfillment(file: file, line: line) { [service = mockSFUStack.service] in
            service.iCETrickleWasCalledWithRequest != nil
        }

        // Then
        let request = try XCTUnwrap(
            mockSFUStack.service.iCETrickleWasCalledWithRequest,
            file: file,
            line: line
        )
        validationHandler(request)
    }
}
