//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class StreamPictureInPictureAdapterTests: XCTestCase, @unchecked Sendable {

    private lazy var mockStreamVideo: MockStreamVideo! = .init()
    private lazy var mockCall: MockCall! = .init()
    private lazy var subject: StreamPictureInPictureAdapter! = .init()

    override func setUp() async throws {
        try await super.setUp()
        _ = mockStreamVideo
    }

    override func tearDown() async throws {
        subject = nil
        try await super.tearDown()
    }

    // MARK: - setCall

    func test_setCall_updatesTheSetSizeClosure() async {
        subject.call = mockCall

        await fulfilmentInMainActor {
            self.subject.onSizeUpdate != nil
        }
    }

    // MARK: - setSize

    func test_setSize_updateTrackSizeWasCalledOnCallWithExpectedInput() async throws {
        let size = CGSize(width: 10, height: 10)
        let participant = CallParticipant.dummy()
        let callState = CallState()
        callState.participants = [participant]
        mockCall.stub(for: \.state, with: callState)
        subject.call = mockCall

        await fulfilmentInMainActor {
            self.subject.onSizeUpdate != nil
        }

        subject.onSizeUpdate?(size, participant)

        await fulfilmentInMainActor {
            self.mockCall.timesCalled(.updateTrackSize) == 1
        }
        let input = try XCTUnwrap(
            mockCall
                .recordedInputPayload(
                    (CGSize, CallParticipant).self,
                    for: .updateTrackSize
                )?.first
        )
        XCTAssertEqual(input.0, size)
        XCTAssertEqual(input.1, participant)
    }
}
