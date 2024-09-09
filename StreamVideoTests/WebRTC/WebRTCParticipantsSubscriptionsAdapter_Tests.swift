//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
@testable import StreamVideo
import XCTest

final class WebRTCParticipantsSubscriptionsAdapter_Tess: XCTestCase {

    private lazy var mockParticipantsPublisher: PassthroughSubject<[CallParticipant], Never>! = .init()
    private var mockSignalService: MockSignalServer!
    private var sfuAdapter: SFUAdapter!
    private var subject: WebRTCParticipantsSubscriptionsAdapter!

    override func setUp() {
        super.setUp()

        let mockSFUStack = SFUAdapter.mock(webSocketClientType: .sfu)
        mockSignalService = mockSFUStack.mockService
        sfuAdapter = mockSFUStack.sfuAdapter
        subject = .init(
            sessionId: "123",
            sfuAdapter: sfuAdapter,
            participantsPublisher: mockParticipantsPublisher.eraseToAnyPublisher()
        )
    }

    override func tearDown() {
        subject = nil
        sfuAdapter = nil
        mockSignalService = nil
        mockParticipantsPublisher = nil
        super.tearDown()
    }

    // MARK: - didUpdate

    func test_didUpdate_participantsUpdated_willUpdateSubscriptionsOnTheSFU() async throws {
        mockParticipantsPublisher.send([
            .dummy(id: "user-a", hasVideo: true, trackSize: .init(width: 30, height: 40)),
            .dummy(id: "user-b", hasAudio: true),
            .dummy(id: "user-c", isScreenSharing: true)
        ])

        await fulfillment { [weak mockSignalService] in
            mockSignalService?.stubbedFunctionInput[.updateSubscriptions]?.count == 1
        }

        let request = try XCTUnwrap(
            mockSignalService?.stubbedFunctionInput[.updateSubscriptions]?.first?
                .value(as: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest.self)
        )
        XCTAssertEqual(request.sessionID, "123")
        
        let userA = request.tracks.filter { $0.sessionID == "user-a" }
        let userB = request.tracks.filter { $0.sessionID == "user-b" }
        let userC = request.tracks.filter { $0.sessionID == "user-c" }

        XCTAssertEqual(userA.count, 1)
        XCTAssertEqual(userA.first?.trackType, .video)
        XCTAssertEqual(userA.first?.dimension.width, 30)
        XCTAssertEqual(userA.first?.dimension.height, 40)

        XCTAssertEqual(userB.count, 1)
        XCTAssertEqual(userB.first?.trackType, .audio)

        XCTAssertEqual(userC.count, 1)
        XCTAssertEqual(userC.first?.trackType, .screenShare)
    }
}
