//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import SwiftProtobuf
import XCTest

final class WebRTCTrace_Tests: XCTestCase, @unchecked Sendable {

    // MARK: - Tests

    func test_init_peerConnectionEvent() {
        let event = StreamRTCPeerConnection.CreateOfferEvent(sessionDescription: .init(type: .offer, sdp: .unique))

        let trace = WebRTCTrace(peerType: .publisher, event: event)

        XCTAssertEqual(trace.id, "publisher")
        XCTAssertEqual(trace.tag, "createOffer")
        XCTAssertEqual((trace.data?.value as? RTCSessionDescription)?.sdp, event.sessionDescription.sdp)
    }

    func test_init_peerConnectionStatsReport() {
        let stats = MutableRTCStatisticsReport(timestamp: 123, statistics: [:])

        let trace = WebRTCTrace(peerType: .subscriber, statsReport: stats)

        XCTAssertEqual(trace.id, "subscriber")
        XCTAssertEqual(trace.tag, "getstats")
        XCTAssertNotNil(trace.data)
    }

    func test_init_SFUAdapterEvent() {
        let event = SFUAdapter.CreateEvent(hostname: .unique)

        let trace = WebRTCTrace(event: event)

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "create")
        XCTAssertEqual((trace.data?.value as? [String: String])?["url"], event.hostname)
    }

    func test_init_protobufMessage() throws {
        let proto = Stream_Video_Sfu_Event_CallEnded()

        let trace = WebRTCTrace(tag: "proto", event: proto)

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "proto")
        XCTAssertEqual(trace.data?.value as? Stream_Video_Sfu_Event_CallEnded, proto)
    }

    func test_init_getUserMedia() {
        let callSettings = CallSettings(
            audioOn: true,
            videoOn: false,
            speakerOn: true,
            audioOutputOn: true,
            cameraPosition: .front
        )
        let audio = StreamAudioSession()

        let trace = WebRTCTrace(callSettings: callSettings, audioSession: audio)

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "navigator.mediaDevices.getUserMediaOnSuccess")
        XCTAssertNotNil(trace.data)
    }

    func test_init_networkStatus_available() {
        let trace = WebRTCTrace(status: .available(.great))

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "network.changed")
        XCTAssertEqual(trace.data?.value as? String, "online")
    }

    func test_init_networkStatus_unavailable() {
        let trace = WebRTCTrace(status: .unavailable)

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "network.changed")
        XCTAssertEqual(trace.data?.value as? String, "offline")
    }

    func test_init_networkStatus_unknown() {
        let trace = WebRTCTrace(status: .unknown)

        XCTAssertNil(trace.id)
        XCTAssertEqual(trace.tag, "network.changed")
        XCTAssertEqual(trace.data?.value as? String, "offline")
    }

    func test_equatable() throws {
        let trace1 = WebRTCTrace(id: "id", tag: "foo", data: .init("bar"), timestamp: 1)
        let trace2 = WebRTCTrace(id: "id", tag: "foo", data: .init("bar"), timestamp: 1)

        XCTAssertEqual(trace1, trace2)
    }
}
