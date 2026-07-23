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
            XCTAssertTrue($0 is StreamCore.ClientError.IgnoredEventType)
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
            (result.error() as? Stream_Video_Sfu_Models_Error)?.message,
            error.message
        )
    }
}
