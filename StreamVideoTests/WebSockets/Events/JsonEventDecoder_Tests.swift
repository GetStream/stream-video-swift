//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class JsonEventDecoder_Tests: XCTestCase, @unchecked Sendable {

    private var subject: JsonEventDecoder!

    override func setUp() {
        super.setUp()
        subject = JsonEventDecoder()
    }

    override func tearDown() {
        subject = nil
        super.tearDown()
    }

    func test_decode_regularCoordinatorEvent_returnsWrappedEvent() throws {
        let expected = CallModerationBlurEvent(
            callCid: "default:123",
            createdAt: Date(timeIntervalSince1970: 0),
            custom: [:],
            userId: "user"
        )

        let result = try subject.decode(
            from: JSONEncoder.stream.encode(expected)
        )

        guard
            let wrappedEvent = result as? WrappedEvent,
            case let .coordinatorEvent(
                .typeCallModerationBlurEvent(event)
            ) = wrappedEvent
        else {
            return XCTFail("Expected a wrapped moderation blur event.")
        }
        XCTAssertEqual(event, expected)
    }

    func test_decode_connectedEvent_returnsConnectionId() throws {
        let connectionId = UUID().uuidString
        let date = Date(timeIntervalSince1970: 0)
        let event = ConnectedEvent(
            connectionId: connectionId,
            createdAt: date,
            me: .init(
                createdAt: date,
                custom: [:],
                devices: [],
                id: "user",
                language: "en",
                role: "user",
                teams: [],
                updatedAt: date
            )
        )

        let result = try subject.decode(
            from: JSONEncoder.stream.encode(event)
        )

        XCTAssertEqual(
            result.healthcheck(),
            .init(connectionId: connectionId)
        )
    }

    func test_decode_healthCheckEvent_returnsConnectionId() throws {
        let connectionId = UUID().uuidString
        let event = HealthCheckEvent(
            connectionId: connectionId,
            createdAt: Date(timeIntervalSince1970: 0)
        )

        let result = try subject.decode(
            from: JSONEncoder.stream.encode(event)
        )

        XCTAssertEqual(
            result.healthcheck(),
            .init(connectionId: connectionId)
        )
    }

    func test_decode_connectionErrorEvent_forwardsError() throws {
        let expected = APIError(
            code: 1,
            details: [],
            duration: "",
            message: "test",
            moreInfo: "",
            statusCode: 400
        )
        let event = ConnectionErrorEvent(
            connectionId: UUID().uuidString,
            createdAt: Date(timeIntervalSince1970: 0),
            error: expected
        )

        let result = try subject.decode(
            from: JSONEncoder.stream.encode(event)
        )

        XCTAssertEqual(result.error() as? APIError, expected)
    }

    func test_decode_malformedPayload_throwsDecodingError() {
        XCTAssertThrowsError(try subject.decode(from: Data("{".utf8))) {
            XCTAssertTrue($0 is DecodingError)
        }
    }

    func test_decode_unsupportedEventType_throwsTypeMismatch() {
        let data = Data(#"{"type":"unsupported"}"#.utf8)

        XCTAssertThrowsError(try subject.decode(from: data)) { error in
            guard case DecodingError.typeMismatch = error else {
                return XCTFail("Expected a type mismatch error.")
            }
        }
    }
}
