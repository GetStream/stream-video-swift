//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class RingingCallRecoveryAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var mockStreamVideo: MockStreamVideo! = .init()
    private var mockCall: MockCall!

    override func setUp() async throws {
        try await super.setUp()
        mockCall = .init(.dummy())
        mockCall.stub(for: .get, with: GetCallResponse.dummy())
    }

    override func tearDown() async throws {
        mockCall = nil
        mockStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - reconnect

    func test_wsConnected_ringingCallSet_getIsCalled() async {
        mockStreamVideo.state.ringingCall = mockCall

        mockStreamVideo.eventNotificationCenter.process(
            WrappedEvent.internalEvent(WSConnected())
        )

        await fulfilmentInMainActor {
            self.mockCall.stubbedFunctionInput[.get]?.isEmpty == false
        }
    }

    func test_wsConnected_noRingingCall_getIsNotCalled() async {
        mockStreamVideo.eventNotificationCenter.process(
            WrappedEvent.internalEvent(WSConnected())
        )

        await wait(for: defaultTimeoutForInversedExpecations)

        XCTAssertTrue(mockCall.stubbedFunctionInput[.get]?.isEmpty ?? true)
    }
}
