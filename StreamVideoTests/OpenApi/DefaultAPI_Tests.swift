//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

final class DefaultAPI_Tests: XCTestCase, @unchecked Sendable {

    private lazy var transport: HTTPClient_Mock! = .init()
    private lazy var subject: DefaultAPI! = DefaultAPI(
        basePath: "https://example.com",
        transport: transport,
        middlewares: []
    )

    override func tearDown() {
        subject = nil
        transport = nil
        super.tearDown()
    }

    // MARK: - reportClientCallEvent

    func test_reportClientCallEvent_requestsV2Path() async {
        _ = try? await subject.reportClientCallEvent(reportClientEventRequest: .init(events: []))

        XCTAssertEqual(transport.requests.last?.url.path, "/api/v2/video/call_client_event")
    }

    // MARK: - getCallRingState

    func test_getCallRingState_requestsV2Path() async {
        _ = try? await subject.getCallRingState(type: "default", id: "123", callSessionId: "session")

        XCTAssertEqual(transport.requests.last?.url.path, "/api/v2/video/call/default/123/ring_state")
    }

    // MARK: - Coding directions

    func test_models_conformOnlyToTheCodingDirectionTheAPIUses() {
        XCTAssertFalse((GetCallResponse.self as Any.Type) is Encodable.Type)
        XCTAssertFalse((CallCreatedEvent.self as Any.Type) is Encodable.Type)
        XCTAssertFalse((GetOrCreateCallRequest.self as Any.Type) is Decodable.Type)
    }
}
