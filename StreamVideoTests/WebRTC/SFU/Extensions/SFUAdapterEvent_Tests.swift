//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class SFUAdapterEvent_Tests: XCTestCase, @unchecked Sendable {

    func test_CreateEvent() {
        let event = SFUAdapter.CreateEvent(hostname: "example.com")
        XCTAssertEqual(event.traceTag, "create")
        XCTAssertEqual(event.traceData?.value as? [String: String], ["url": "example.com"])
    }

    func test_ConnectEvent() {
        let event = SFUAdapter.ConnectEvent(hostname: "example.com")
        XCTAssertEqual(event.traceTag, "connect")
    }

    func test_DisconnectEvent() {
        let event = SFUAdapter.DisconnectEvent(hostname: "example.com", payload: nil)
        XCTAssertEqual(event.traceTag, "disconnect")
    }

    func test_JoinEvent() {
        let payload = Stream_Video_Sfu_Event_JoinRequest()
        let event = SFUAdapter.JoinEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "join")
        XCTAssertNotNil(event.traceData)
    }

    func test_LeaveEvent() {
        let payload = Stream_Video_Sfu_Event_LeaveCallRequest()
        let event = SFUAdapter.LeaveEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "leave")
        XCTAssertNotNil(event.traceData)
    }

    func test_UpdateTrackMuteStateEvent() {
        let payload = Stream_Video_Sfu_Signal_UpdateMuteStatesRequest()
        let event = SFUAdapter.UpdateTrackMuteStateEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "updateTrackMuteState")
        XCTAssertNotNil(event.traceData)
    }

    func test_StartNoiseCancellationEvent() {
        let payload = Stream_Video_Sfu_Signal_StartNoiseCancellationRequest()
        let event = SFUAdapter.StartNoiseCancellationEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "startNoiseCancellation")
        XCTAssertNotNil(event.traceData)
    }

    func test_StopNoiseCancellationEvent() {
        let payload = Stream_Video_Sfu_Signal_StopNoiseCancellationRequest()
        let event = SFUAdapter.StopNoiseCancellationEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "stopNoiseCancellation")
        XCTAssertNotNil(event.traceData)
    }

    func test_SetPublisherEvent() {
        let payload = Stream_Video_Sfu_Signal_SetPublisherRequest()
        let event = SFUAdapter.SetPublisherEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "setPublisher")
        XCTAssertNotNil(event.traceData)
    }

    func test_UpdateSubscriptionsEvent() {
        let payload = Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest()
        let event = SFUAdapter.UpdateSubscriptionsEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "updateSubscriptions")
        XCTAssertNotNil(event.traceData)
    }

    func test_SendAnswerEvent() {
        let payload = Stream_Video_Sfu_Signal_SendAnswerRequest()
        let event = SFUAdapter.SendAnswerEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "sendAnswer")
        XCTAssertNotNil(event.traceData)
    }

    func test_ICETrickleEvent() {
        let payload = Stream_Video_Sfu_Models_ICETrickle()
        let event = SFUAdapter.ICETrickleEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "iceTrickle")
        XCTAssertNotNil(event.traceData)
    }

    func test_RestartICEEvent() {
        let payload = Stream_Video_Sfu_Signal_ICERestartRequest()
        let event = SFUAdapter.RestartICEEvent(hostname: "example.com", payload: payload)
        XCTAssertEqual(event.traceTag, "iceRestart")
        XCTAssertNotNil(event.traceData)
    }
}
