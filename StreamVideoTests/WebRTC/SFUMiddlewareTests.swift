//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

final class SFUMiddlewareTests: XCTestCase {

//    private lazy var sessionID: String! = .unique
//    private lazy var user: User! = .init(id: .unique)
//    private lazy var state: WebRTCClient.State! = .init()
//    private lazy var signalService: Stream_Video_Sfu_Signal_SignalServer! = .init(
//        httpClient: HTTPClient_Mock(),
//        apiKey: .unique,
//        hostname: .unique,
//        token: .unique
//    )
//    private lazy var participantThreshold: Int! = 10
//
//    private lazy var subject: SfuMiddleware! = .init(
//        sessionID: sessionID,
//        user: user,
//        state: state,
//        signalService: signalService,
//        participantThreshold: participantThreshold
//    )
//
//    override func tearDown() {
//        subject = nil
//        user = nil
//        state = nil
//        signalService = nil
//        participantThreshold = nil
//        super.tearDown()
//    }
//
//    // MARK: - handle(event:)
//
//    func test_handle_healthCheck_passesCorrectValuesForParticipantsAndAnonymous() async throws {
//        var participantCount = Stream_Video_Sfu_Models_ParticipantCount()
//        participantCount.total = 10
//        participantCount.anonymous = 3
//        var healthCheckInfo = Stream_Video_Sfu_Event_HealthCheckResponse()
//        healthCheckInfo.participantCount = participantCount
//        let participantsCountExpectation = expectation(description: "onParticipantCountUpdated was called")
//        let anonymousCountExpectation = expectation(description: "onAnonymousParticipantCountUpdated was called")
//        subject.onParticipantCountUpdated = {
//            XCTAssertEqual($0, participantCount.total)
//            participantsCountExpectation.fulfill()
//        }
//        subject.onAnonymousParticipantCountUpdated = {
//            XCTAssertEqual($0, participantCount.anonymous)
//            anonymousCountExpectation.fulfill()
//        }
//
//        _ = subject.handle(event: .sfuEvent(.healthCheckResponse(healthCheckInfo)))
//
//        await fulfillment(of: [participantsCountExpectation, anonymousCountExpectation])
//    }
}
