//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
@preconcurrency import XCTest

final class RTCTemporaryPeerConnection_Tests: XCTestCase, @unchecked Sendable {

    private lazy var peerConnectionFactory: PeerConnectionFactory! = .mock()
    private lazy var peerConnection: MockRTCPeerConnection! = .init()
    private lazy var audioTrack: RTCAudioTrack! = peerConnectionFactory.mockAudioTrack()
    private lazy var videoTrack: RTCVideoTrack! = peerConnectionFactory.mockVideoTrack(forScreenShare: false)
    private lazy var subject: RTCTemporaryPeerConnection! = .init(
        peerConnection: peerConnection,
        direction: .sendOnly,
        videoOptions: .init(),
        localAudioTrack: audioTrack,
        localVideoTrack: videoTrack
    )

    override func tearDown() {
        peerConnection.offerHandler = nil
        peerConnection.closeHandler = nil
        subject = nil
        audioTrack = nil
        videoTrack = nil
        peerConnection = nil
        peerConnectionFactory = nil
        super.tearDown()
    }

    func test_createOffer_success_disablesTracksAndAwaitsClose() async throws {
        let expectedOffer = RTCSessionDescription(type: .offer, sdp: .unique)
        let closeStarted = expectation(description: "Close started")
        let offerReturned = expectation(description: "Offer returned before close completed")
        offerReturned.isInverted = true
        let closeGate = Gate()
        peerConnection.offerHandler = { _ in expectedOffer }
        peerConnection.closeHandler = {
            closeStarted.fulfill()
            await closeGate.wait()
        }
        audioTrack.isEnabled = true
        videoTrack.isEnabled = true

        let task = Task {
            defer { offerReturned.fulfill() }
            return try await subject.createOffer()
        }
        await fulfillment(of: [closeStarted], timeout: 5)
        XCTAssertFalse(audioTrack.isEnabled)
        XCTAssertFalse(videoTrack.isEnabled)
        await fulfillment(of: [offerReturned], timeout: 0.1)
        await closeGate.open()

        let actualOffer = try await task.value
        XCTAssertEqual(actualOffer.type, expectedOffer.type)
        XCTAssertEqual(actualOffer.sdp, expectedOffer.sdp)
        XCTAssertEqual(peerConnection.timesCalled(.addTransceiver), 2)
        XCTAssertEqual(peerConnection.timesCalled(.close), 1)
    }

    func test_createOffer_error_disablesTracksAndAwaitsCloseBeforeRethrowing() async {
        let expectedError = OfferError()
        let closeStarted = expectation(description: "Close started")
        let offerReturned = expectation(description: "Offer returned before close completed")
        offerReturned.isInverted = true
        let closeGate = Gate()
        peerConnection.offerHandler = { _ in throw expectedError }
        peerConnection.closeHandler = {
            closeStarted.fulfill()
            await closeGate.wait()
        }
        audioTrack.isEnabled = true
        videoTrack.isEnabled = true

        let task = Task {
            defer { offerReturned.fulfill() }
            return try await subject.createOffer()
        }
        await fulfillment(of: [closeStarted], timeout: 5)
        XCTAssertFalse(audioTrack.isEnabled)
        XCTAssertFalse(videoTrack.isEnabled)
        await fulfillment(of: [offerReturned], timeout: 0.1)
        await closeGate.open()

        do {
            _ = try await task.value
            XCTFail("Expected offer failure")
        } catch {
            XCTAssertTrue(error as? OfferError === expectedError)
        }
        XCTAssertEqual(peerConnection.timesCalled(.close), 1)
    }

    func test_createOffer_cancelledDuringOffer_disablesTracksAndAwaitsClose() async {
        let offerStarted = expectation(description: "Offer started")
        let closeStarted = expectation(description: "Close started")
        let offerReturned = expectation(description: "Offer returned before close completed")
        offerReturned.isInverted = true
        let offerGate = Gate()
        let closeGate = Gate()
        peerConnection.offerHandler = { _ in
            offerStarted.fulfill()
            await offerGate.wait()
            try Task.checkCancellation()
            return RTCSessionDescription(type: .offer, sdp: .unique)
        }
        peerConnection.closeHandler = {
            closeStarted.fulfill()
            await closeGate.wait()
        }
        audioTrack.isEnabled = true
        videoTrack.isEnabled = true

        let task = Task {
            defer { offerReturned.fulfill() }
            return try await subject.createOffer()
        }
        await fulfillment(of: [offerStarted], timeout: 5)
        task.cancel()
        await offerGate.open()
        await fulfillment(of: [closeStarted], timeout: 5)
        XCTAssertFalse(audioTrack.isEnabled)
        XCTAssertFalse(videoTrack.isEnabled)
        await fulfillment(of: [offerReturned], timeout: 0.1)
        await closeGate.open()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch {
            XCTAssertTrue(error is CancellationError)
        }
        XCTAssertEqual(peerConnection.timesCalled(.close), 1)
    }
}

private final class OfferError: Error {}

private actor Gate {
    private var isOpen = false
    private var continuation: CheckedContinuation<Void, Never>?

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        guard !isOpen else { return }
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}
