//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class ClientEventDelivery_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockAPI: MockDefaultAPIEndpoints! = .init()
    private lazy var subject: ClientEventDelivery! = .init(
        api: mockAPI,
        retryPolicy: .init(maxRetries: 4, delay: { _ in 0 })
    )

    override func setUp() {
        super.setUp()
        mockAPI.stub(for: .clientCallEvent, with: ReportClientEventResponse(duration: "1ms"))
    }

    override func tearDown() {
        subject = nil
        mockAPI = nil
        super.tearDown()
    }

    func test_send_withSuccess_sendsRequestOnce() async {
        await subject.send(.init(eventType: "initiated", stage: "WSJoin"))

        XCTAssertEqual(mockAPI.timesCalled(.clientCallEvent), 1)
    }

    func test_send_retriesServerErrorsUpToPolicyLimit() async {
        mockAPI.stub(
            for: .clientCallEvent,
            with: APIError(
                code: 0,
                details: [],
                duration: "",
                message: "boom",
                moreInfo: "",
                statusCode: 500
            )
        )

        await subject.send(.init(eventType: "initiated", stage: "WSJoin"))

        XCTAssertEqual(mockAPI.timesCalled(.clientCallEvent), 5)
    }

    func test_send_doesNotRetryClientErrors() async {
        mockAPI.stub(
            for: .clientCallEvent,
            with: APIError(
                code: 0,
                details: [],
                duration: "",
                message: "bad request",
                moreInfo: "",
                statusCode: 400
            )
        )

        await subject.send(.init(eventType: "initiated", stage: "WSJoin"))

        XCTAssertEqual(mockAPI.timesCalled(.clientCallEvent), 1)
    }
}
