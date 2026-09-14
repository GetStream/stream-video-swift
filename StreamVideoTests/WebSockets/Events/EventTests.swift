//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore
@testable import StreamVideo
import XCTest

final class EventTests: XCTestCase, @unchecked Sendable {

    private lazy var customVideoEvent: CustomVideoEvent! = CustomVideoEvent(
        callCid: "123",
        createdAt: Date(),
        custom: [:],
        user: .init(
            blockedUserIds: [],
            createdAt: Date(),
            custom: [:],
            id: "456",
            language: "en",
            role: "admin",
            teams: [],
            updatedAt: Date()
        )
    )

    override func tearDown() {
        customVideoEvent = nil
        super.tearDown()
    }

    // MARK: - unwrap

    func test_unwrap_isVideoEvent_returnsExpected() {
        let videoEvent = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: .init()
            )
        )

        XCTAssertEqual(videoEvent.unwrap(), videoEvent)
    }

    func test_unwrap_isWrappedCoordinatorEvent_returnsExpected() {
        let videoEvent = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: .init()
            )
        )
        let wrappedEvent = WrappedEvent.coordinatorEvent(videoEvent)

        XCTAssertEqual(wrappedEvent.unwrap(), videoEvent)
    }

    func test_unwrap_isWrappedButNotCoordinatorEvent_returnsExpected() {
        let wrappedEvent = WrappedEvent.internalEvent(
            HealthCheckEvent(
                connectionId: UUID().uuidString,
                createdAt: Date()
            )
        )

        XCTAssertNil(wrappedEvent.unwrap())
    }

    func test_unwrap_isUnknownEvent_returnsExpected() {
        let subject = HealthCheckEvent(
            connectionId: UUID().uuidString,
            createdAt: Date()
        )

        XCTAssertNil(subject.unwrap())
    }

    // MARK: - forCall

    func test_forCall_isWSCallEventWithSameCID_returnsTrue() {
        let videoEvent = VideoEvent.typeCustomVideoEvent(customVideoEvent)

        XCTAssertTrue(videoEvent.forCall(cid: "123"))
    }

    func test_forCall_isWSCallEventWithDifferentCID_returnsFalse() {
        let videoEvent = VideoEvent.typeCustomVideoEvent(customVideoEvent)

        XCTAssertFalse(videoEvent.forCall(cid: "789"))
    }

    func test_forCall_isNotWSCallEvent_returnsFalse() {
        let subject = VideoEvent.typeHealthCheckEvent(
            .init(
                connectionId: UUID().uuidString,
                createdAt: Date()
            )
        )

        XCTAssertFalse(subject.forCall(cid: "123"))
    }

    func test_forCall_isNotVideoEvent_returnsFalse() {
        let subject = HealthCheckEvent(
            connectionId: UUID().uuidString,
            createdAt: Date()
        )

        XCTAssertFalse(subject.forCall(cid: "123"))
    }

    // MARK: - StreamCore compatibility

    func test_generatedCoordinatorEvent_isStreamCoreEvent() {
        let subject: any Event = HealthCheckEvent(
            connectionId: UUID().uuidString,
            createdAt: Date()
        )

        XCTAssertNil(subject.healthcheck())
        XCTAssertNil(subject.error())
    }

    func test_wrappedCoordinatorHealthCheck_returnsCoreHealthCheckInfo() {
        let connectionId = UUID().uuidString
        let subject: any Event = WrappedEvent.coordinatorEvent(
            .typeHealthCheckEvent(
                .init(
                    connectionId: connectionId,
                    createdAt: Date()
                )
            )
        )

        XCTAssertEqual(
            subject.healthcheck(),
            HealthCheckInfo(connectionId: connectionId)
        )
    }

    func test_wrappedCoordinatorError_returnsAPIError() {
        let event = ConnectionErrorEvent(
            connectionId: UUID().uuidString,
            createdAt: Date(),
            error: .init(
                code: 1,
                details: [],
                duration: "",
                message: "test",
                moreInfo: "",
                statusCode: 400
            )
        )
        let subject: any Event = WrappedEvent.coordinatorEvent(
            .typeConnectionErrorEvent(event)
        )

        guard let result = subject.error() else {
            return XCTFail("Expected an API error.")
        }
        XCTAssertTrue((result as AnyObject) === event.error)
    }

    func test_sendableProtobufEvents_serializeThroughStreamCoreProtocol() throws {
        var request = Stream_Video_Sfu_Event_SfuRequest()
        request.healthCheckRequest =
            Stream_Video_Sfu_Event_HealthCheckRequest()
        let subjects: [any SendableEvent] = [
            request,
            Stream_Video_Sfu_Event_HealthCheckRequest()
        ]

        for subject in subjects {
            XCTAssertNoThrow(try subject.serializedData(partial: false))
        }
    }
}
