//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCPeerConnectionEvent_AllEvents_Tests: XCTestCase, @unchecked Sendable {

    func test_HasRemoteDescription_traceValues() {
        let sdp = RTCSessionDescription(type: .offer, sdp: "v=0")
        let event = StreamRTCPeerConnection.HasRemoteDescription(sessionDescription: sdp)
        XCTAssertEqual(event.traceTag, "hasRemoteDescription")
        XCTAssertEqual((event.traceData.value as? RTCSessionDescription)?.sdp, "v=0")
    }

    func test_ShouldNegotiateEvent_traceValues() {
        let event = StreamRTCPeerConnection.ShouldNegotiateEvent()
        XCTAssertEqual(event.traceTag, "shouldNegotiate")
    }

    func test_ICERestartEvent_traceValues() {
        let event = StreamRTCPeerConnection.ICERestartEvent()
        XCTAssertEqual(event.traceTag, "ICERestart")
    }

    func test_SignalingStateChangedEvent_traceValues() {
        let event = StreamRTCPeerConnection.SignalingStateChangedEvent(state: .stable)
        XCTAssertEqual(event.traceTag, "signalingstatechange")
        XCTAssertEqual(event.traceData.value as? String, "stable")
    }

    func test_PeerConnectionStateChangedEvent_traceValues() {
        let event = StreamRTCPeerConnection.PeerConnectionStateChangedEvent(state: .disconnected)
        XCTAssertEqual(event.traceTag, "connectionstatechange")
        XCTAssertEqual(event.traceData.value as? String, "disconnected")
    }

    func test_ICEConnectionChangedEvent_traceValues() {
        let event = StreamRTCPeerConnection.ICEConnectionChangedEvent(state: .new)
        XCTAssertEqual(event.traceTag, "iceconnectionstatechange")
        XCTAssertEqual(event.traceData.value as? String, "new")
    }

    func test_ICEGatheringChangedEvent_traceValues() {
        let event = StreamRTCPeerConnection.ICEGatheringChangedEvent(state: .complete)
        XCTAssertEqual(event.traceTag, "ICEGatheringStateChange")
        XCTAssertEqual(event.traceData.value as? String, "complete")
    }

    func test_ICECandidatesRemovedEvent_traceValues() {
        let candidates = [RTCIceCandidate(sdp: "c", sdpMLineIndex: 0, sdpMid: "0")]
        let event = StreamRTCPeerConnection.ICECandidatesRemovedEvent(candidates: candidates)
        XCTAssertEqual(event.traceTag, "ICECandidatesRemoved")
        XCTAssertEqual(event.traceData.value as? [RTCIceCandidate], candidates)
    }

    func test_ICECandidateFailedToGatherEvent_traceValues() {
        let error = RTCIceCandidateErrorEvent()
        let event = StreamRTCPeerConnection.ICECandidateFailedToGatherEvent(errorEvent: error)
        XCTAssertEqual(event.traceTag, "ICECandidateFailedToGather")
        XCTAssertEqual(event.traceData.value as? RTCIceCandidateErrorEvent, error)
    }

    func test_DidChangeStandardizedICEConnectionStateEvent_traceValues() {
        let event = StreamRTCPeerConnection.DidChangeStandardizedICEConnectionStateEvent(state: .checking)
        XCTAssertEqual(event.traceTag, "didChangeStandardizedICEConnectionState")
        XCTAssertEqual(event.traceData.value as? String, "checking")
    }

    func test_DidChangeConnectionStateEvent_traceValues() {
        let event = StreamRTCPeerConnection.DidChangeConnectionStateEvent(state: .failed)
        XCTAssertEqual(event.traceTag, "didChangeConnectionState")
        XCTAssertEqual(event.traceData.value as? String, "failed")
    }

    func test_DidChangeLocalCandidateEvent_traceValues() {
        let candidate = RTCIceCandidate(sdp: "abc", sdpMLineIndex: 0, sdpMid: "mid")
        let event = StreamRTCPeerConnection.DidChangeLocalCandidateEvent(candidate: candidate)
        XCTAssertEqual(event.traceTag, "didChangeLocalCandidate")
        XCTAssertEqual(event.traceData.value as? RTCIceCandidate, candidate)
    }

    func test_DidChangeRemoteCandidateEvent_traceValues() {
        let candidate = RTCIceCandidate(sdp: "def", sdpMLineIndex: 0, sdpMid: "mid")
        let event = StreamRTCPeerConnection.DidChangeRemoteCandidateEvent(candidate: candidate)
        XCTAssertEqual(event.traceTag, "didChangeRemoteCandidate")
        XCTAssertEqual(event.traceData.value as? RTCIceCandidate, candidate)
    }

    func test_DidGenerateICECandidateEvent_traceValues() {
        let candidate = RTCIceCandidate(sdp: "gen", sdpMLineIndex: 0, sdpMid: "0")
        let event = StreamRTCPeerConnection.DidGenerateICECandidateEvent(candidate: candidate)
        XCTAssertEqual(event.traceTag, "didGenerateICECandidate")
        XCTAssertEqual(event.traceData.value as? RTCIceCandidate, candidate)
    }

    func test_DidRemoveICECandidatesEvent_traceValues() {
        let candidates = [RTCIceCandidate(sdp: "a", sdpMLineIndex: 0, sdpMid: "0")]
        let event = StreamRTCPeerConnection.DidRemoveICECandidatesEvent(candidates: candidates)
        XCTAssertEqual(event.traceTag, "didRemoveICECandidates")
        XCTAssertEqual(event.traceData.value as? [RTCIceCandidate], candidates)
    }

    func test_DidChangeLocalCandidateWithRemoteEvent_traceValues() {
        let local = RTCIceCandidate(sdp: "loc", sdpMLineIndex: 0, sdpMid: "mid")
        let remote = RTCIceCandidate(sdp: "rem", sdpMLineIndex: 0, sdpMid: "mid")
        let event = StreamRTCPeerConnection.DidChangeLocalCandidateWithRemoteEvent(
            localCandidate: local,
            remoteCandidate: remote,
            lastDataReceivedMs: 9999,
            reason: "test"
        )
        XCTAssertEqual(event.traceTag, "didChangeLocalCandidateWithRemote")
        XCTAssertEqual((
            event.traceData.value as? StreamRTCPeerConnection
                .DidChangeLocalCandidateWithRemoteEvent
        )?.reason, "test")
    }

    func test_CreatedEvent_traceValues() {
        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        let event = StreamRTCPeerConnection.CreatedEvent(configuration: config, hostname: "host.test")
        XCTAssertEqual(event.traceTag, "create")
        guard let data = event.traceData.value as? [String: AnyEncodable] else {
            return XCTFail("Expected dictionary traceData")
        }
        XCTAssertEqual(data["url"]?.value as? String, "host.test")
    }

    func test_CreateOfferEvent_traceValues() {
        let sdp = RTCSessionDescription(type: .offer, sdp: "v=0")
        let event = StreamRTCPeerConnection.CreateOfferEvent(sessionDescription: sdp)
        XCTAssertEqual(event.traceTag, "createOffer")
        XCTAssertEqual((event.traceData.value as? RTCSessionDescription)?.sdp, "v=0")
    }

    func test_CreateAnswerEvent_traceValues() {
        let sdp = RTCSessionDescription(type: .answer, sdp: "v=1")
        let event = StreamRTCPeerConnection.CreateAnswerEvent(sessionDescription: sdp)
        XCTAssertEqual(event.traceTag, "createAnswer")
        XCTAssertEqual((event.traceData.value as? RTCSessionDescription)?.sdp, "v=1")
    }

    func test_SetLocalDescriptionEvent_traceValues() {
        let sdp = RTCSessionDescription(type: .offer, sdp: "abc")
        let event = StreamRTCPeerConnection.SetLocalDescriptionEvent(sessionDescription: sdp)
        XCTAssertEqual(event.traceTag, "setLocalDescription")
        XCTAssertEqual((event.traceData.value as? RTCSessionDescription)?.sdp, "abc")
    }

    func test_SetRemoteDescriptionEvent_traceValues() {
        let sdp = RTCSessionDescription(type: .answer, sdp: "xyz")
        let event = StreamRTCPeerConnection.SetRemoteDescriptionEvent(sessionDescription: sdp)
        XCTAssertEqual(event.traceTag, "setRemoteDescription")
        XCTAssertEqual((event.traceData.value as? RTCSessionDescription)?.sdp, "xyz")
    }

    func test_CloseEvent_traceValues() {
        let event = StreamRTCPeerConnection.CloseEvent()
        XCTAssertEqual(event.traceTag, "close")
    }

    func test_RestartICEEvent_traceValues() {
        let event = StreamRTCPeerConnection.RestartICEEvent()
        XCTAssertEqual(event.traceTag, "restartICE")
    }
}
