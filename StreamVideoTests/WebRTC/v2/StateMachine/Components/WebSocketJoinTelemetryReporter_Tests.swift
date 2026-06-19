//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class WebSocketJoinTelemetryReporter_Tests: XCTestCase, @unchecked Sendable {

    func test_begin_reportsWSJoinWithDetails() async {
        var (subject, stack) = makeSubject()

        await subject.begin(
            sfuId: "sfu-1",
            callSessionId: "call-session-1",
            coordinatorConnectId: "coordinator-connect-1"
        )

        let begunStages = await stack.clientEventReporter.begunStages
        XCTAssertEqual(begunStages.count, 1)
        XCTAssertEqual(begunStages.first?.stage, .wsJoin)
        XCTAssertNil(begunStages.first?.peerConnection)
        XCTAssertEqual(begunStages.first?.details.sfuId, "sfu-1")
        XCTAssertEqual(begunStages.first?.details.callSessionId, "call-session-1")
        XCTAssertEqual(
            begunStages.first?.details.coordinatorConnectId,
            "coordinator-connect-1"
        )
    }

    func test_complete_afterBegin_reportsSuccessCompletionForSameAttempt() async {
        var (subject, stack) = makeSubject()

        await subject.begin(
            sfuId: "sfu-1",
            callSessionId: "call-session-1",
            coordinatorConnectId: "coordinator-connect-1"
        )
        await subject.complete(retryCount: 3)

        let begunStages = await stack.clientEventReporter.begunStages
        let completedStages = await stack.clientEventReporter.completedStages
        XCTAssertEqual(completedStages.count, 1)
        XCTAssertEqual(completedStages.first?.attempt.stage, .wsJoin)
        XCTAssertEqual(
            completedStages.first?.attempt.stageId,
            begunStages.first?.attempt.stageId
        )
        XCTAssertEqual(completedStages.first?.outcome, .success)
        XCTAssertEqual(completedStages.first?.retryCount, 3)
        XCTAssertNil(completedStages.first?.failure)
    }

    func test_fail_afterBegin_reportsFailureCompletionWithDetails() async {
        var (subject, stack) = makeSubject()

        await subject.begin(
            sfuId: "sfu-1",
            callSessionId: "call-session-1",
            coordinatorConnectId: "coordinator-connect-1"
        )
        await subject.fail(retryCount: 2, error: ClientError("join timed out"))

        let begunStages = await stack.clientEventReporter.begunStages
        let completedStages = await stack.clientEventReporter.completedStages
        XCTAssertEqual(completedStages.count, 1)
        XCTAssertEqual(completedStages.first?.attempt.stage, .wsJoin)
        XCTAssertEqual(
            completedStages.first?.attempt.stageId,
            begunStages.first?.attempt.stageId
        )
        XCTAssertEqual(completedStages.first?.outcome, .failure)
        XCTAssertEqual(completedStages.first?.retryCount, 2)
        XCTAssertEqual(completedStages.first?.details.sfuId, "sfu-1")
        XCTAssertEqual(completedStages.first?.details.callSessionId, "call-session-1")
        XCTAssertEqual(
            completedStages.first?.details.coordinatorConnectId,
            "coordinator-connect-1"
        )
        XCTAssertNotNil(completedStages.first?.failure)
    }

    func test_complete_withoutBegin_doesNotReportCompletion() async {
        var (subject, stack) = makeSubject()

        await subject.complete(retryCount: 1)

        let completedStages = await stack.clientEventReporter.completedStages
        XCTAssertTrue(completedStages.isEmpty)
    }

    // MARK: - Private

    private func makeSubject() -> (
        WebSocketJoinTelemetryReporter,
        MockWebRTCCoordinatorStack
    ) {
        let stack = MockWebRTCCoordinatorStack(videoConfig: .dummy())
        var subject = WebSocketJoinTelemetryReporter()
        subject.configure(
            stateAdapter: stack.coordinator.stateAdapter,
            clientEventReporter: stack.clientEventReporter
        )
        return (subject, stack)
    }
}
