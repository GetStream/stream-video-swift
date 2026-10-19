//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore
@testable import StreamVideo
import XCTest

final class WebRTCEventDecoder_Tests: XCTestCase, @unchecked Sendable {

    private var subject: WebRTCEventDecoder!

    override func setUp() {
        super.setUp()
        subject = WebRTCEventDecoder()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_decode_validProtobuf_returnsTypedPayload() throws {
        var participantCount = Stream_Video_Sfu_Models_ParticipantCount()
        participantCount.total = 2
        var healthCheck = Stream_Video_Sfu_Event_HealthCheckResponse()
        healthCheck.participantCount = participantCount
        var event = Stream_Video_Sfu_Event_SfuEvent()
        event.healthCheckResponse = healthCheck

        let result = try subject.decode(
            from: event.serializedData(partial: false)
        )

        XCTAssertEqual(
            result as? Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
            .healthCheckResponse(healthCheck)
        )
        XCTAssertEqual(result.healthcheck()?.participantCount, 2)
    }

    func test_decode_emptyProtobuf_throwsIgnoredEventType() throws {
        let event = Stream_Video_Sfu_Event_SfuEvent()

        XCTAssertThrowsError(
            try subject.decode(from: event.serializedData(partial: false))
        ) {
            XCTAssertTrue($0 is ClientError.IgnoredEventType)
        }
    }

    func test_decode_malformedProtobuf_throws() {
        XCTAssertThrowsError(
            try subject.decode(from: Data([0x0a]))
        )
    }

    func test_decode_errorProtobuf_returnsTypedTerminalPayload() throws {
        var error = Stream_Video_Sfu_Models_Error()
        error.message = .unique
        var errorEvent = Stream_Video_Sfu_Event_Error()
        errorEvent.error = error
        errorEvent.reconnectStrategy = .migrate
        var event = Stream_Video_Sfu_Event_SfuEvent()
        event.error = errorEvent

        let result = try subject.decode(
            from: event.serializedData(partial: false)
        )

        XCTAssertEqual(
            result as? Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
            .error(errorEvent)
        )
        XCTAssertEqual(
            result.error() as? Stream_Video_Sfu_Event_Error,
            errorEvent
        )
    }

    func test_decode_unspecifiedError_keepsSocketConnectedUntilTransportCloses_() async throws {
        for shouldRetry in [false, true] {
            let client = WebSocketClient(
                sessionConfiguration: .ephemeral,
                eventDecoder: subject,
                eventNotificationCenter: DefaultEventNotificationCenter(),
                webSocketClientType: .sfu,
                connectRequest: nil,
                requiresAuth: false
            )
            client.webSocketDidConnect()
            var healthCheck = Stream_Video_Sfu_Event_SfuEvent()
            healthCheck.healthCheckResponse = .init()
            client.webSocketDidReceiveMessage(try healthCheck.serializedData())

            var event = Stream_Video_Sfu_Event_SfuEvent()
            event.error.error.message = .unique
            event.error.error.shouldRetry = shouldRetry
            let received = expectation(description: "Unspecified error delivered")
            let cancellable = client.eventSubject.sink { payload in
                XCTAssertEqual(
                    payload as? Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload,
                    event.eventPayload
                )
                received.fulfill()
            }
            defer { cancellable.cancel() }

            client.webSocketDidReceiveMessage(try event.serializedData())

            await fulfillment(of: [received], timeout: defaultTimeout)
            guard case .connected = client.connectionState else {
                XCTFail("An unspecified SFU error must not disconnect the socket")
                continue
            }

            client.webSocketDidDisconnect(error: nil)

            XCTAssertEqual(
                client.connectionState,
                .disconnected(source: .serverInitiated(error: nil))
            )
        }
    }
}
