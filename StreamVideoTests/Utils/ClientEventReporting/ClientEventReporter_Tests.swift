//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@preconcurrency import XCTest

final class ClientEventReporter_Tests: XCTestCase, @unchecked Sendable {

    /// Mutable clock shared with the reporter so tests can drive `elapsed_time`.
    private final class DateHolder: @unchecked Sendable {
        var date = Date(timeIntervalSince1970: 1000)
    }

    private lazy var mockAPI: MockDefaultAPIEndpoints! = .init()
    private lazy var dateHolder: DateHolder! = .init()
    private lazy var noDelayRetryPolicy: RetryPolicy! = .init(maxRetries: 4, delay: { _ in 0 })
    private lazy var subject: ClientEventReporter! = .init(
        api: mockAPI,
        context: .init(userId: "user-1", callType: "default", callId: "call-1"),
        retryPolicy: noDelayRetryPolicy,
        currentDate: { [dateHolder] in dateHolder!.date }
    )

    override func setUp() {
        super.setUp()
        mockAPI.stub(for: .clientCallEvent, with: ReportClientEventResponse(duration: "1ms"))
    }

    override func tearDown() {
        subject = nil
        mockAPI = nil
        dateHolder = nil
        noDelayRetryPolicy = nil
        super.tearDown()
    }

    // MARK: - JoinInitiated

    func test_reportJoinInitiated_sendsJoinInitiatedEventWithCommonFields() async {
        await subject.reportJoinInitiated()

        await waitForEventCount(1)
        let joinInitiated = event(stage: "JoinInitiated", type: "initiated")
        XCTAssertEqual(joinInitiated?.userId, "user-1")
        XCTAssertEqual(joinInitiated?.type, "default")
        XCTAssertEqual(joinInitiated?.id, "call-1")
        XCTAssertEqual(joinInitiated?.sdkVersion, SystemEnvironment.version)
        XCTAssertEqual(joinInitiated?.userAgent, SystemEnvironment.xStreamClientHeader)
        XCTAssertNotNil(joinInitiated?.joinAttemptId)
        XCTAssertEqual(joinInitiated?.joinAttemptId, joinInitiated?.joinAttemptId?.lowercased())
        // JoinInitiated has no stage_id / outcome.
        XCTAssertNil(joinInitiated?.stageId)
        XCTAssertNil(joinInitiated?.outcome)
    }

    func test_reportJoinInitiated_withDetails_includesCoordinatorConnectId() async {
        await subject.reportJoinInitiated(
            details: .init(
                coordinatorConnectId: "85e8b199-d4ab-4eb7-a681-1d6916a86906"
            )
        )

        await waitForEventCount(1)
        let joinInitiated = event(stage: "JoinInitiated", type: "initiated")
        XCTAssertEqual(
            joinInitiated?.coordinatorConnectId,
            "85e8b199-d4ab-4eb7-a681-1d6916a86906"
        )
    }

    func test_reportJoinInitiated_calledTwice_regeneratesJoinAttemptId() async {
        await subject.reportJoinInitiated()
        let firstId = await subject.joinAttemptId
        await subject.reportJoinInitiated()
        let secondId = await subject.joinAttemptId

        XCTAssertNotEqual(firstId, secondId)

        await waitForEventCount(2)
        XCTAssertEqual(Set(recordedEvents().compactMap(\.joinAttemptId)), [firstId, secondId])
    }

    // MARK: - Stage pairs

    func test_beginStage_sendsInitiatedEventCarryingStageId() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(.coordinatorJoin)

        await waitForEventCount(2)
        let initiated = event(stage: "CoordinatorJoin", type: "initiated")
        XCTAssertEqual(initiated?.stageId, attempt.stageId)
        XCTAssertEqual(initiated?.stageId, initiated?.stageId?.lowercased())
        XCTAssertNil(initiated?.outcome)
    }

    func test_completeStage_success_emitsCompletionSharingStageId() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(.wsJoin)
        dateHolder.date = dateHolder.date.addingTimeInterval(0.414)
        await subject.completeStage(attempt, outcome: .success, retryCount: 2)

        await waitForEventCount(3)
        let completed = event(stage: "WSJoin", type: "completed")
        XCTAssertEqual(completed?.stageId, attempt.stageId)
        XCTAssertEqual(completed?.outcome, "success")
        XCTAssertEqual(completed?.retryCountAttempt, 2)
        XCTAssertEqual(completed?.elapsedTime, 414)
        XCTAssertNil(completed?.retryFailureCode)
    }

    func test_completeStage_success_mergesCompletionDetails() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(
            .coordinatorJoin,
            peerConnection: nil,
            details: .init(coordinatorConnectId: "coordinator-connect-id")
        )

        await subject.completeStage(
            attempt,
            outcome: .success,
            retryCount: 0,
            details: .init(callSessionId: "call-session-id"),
            failure: nil
        )

        await waitForEventCount(3)
        let completed = event(stage: "CoordinatorJoin", type: "completed")
        XCTAssertEqual(completed?.coordinatorConnectId, "coordinator-connect-id")
        XCTAssertEqual(completed?.callSessionId, "call-session-id")
    }

    func test_completeStage_afterUpdateStage_includesPersistedDetails() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(
            .peerConnectionConnect,
            peerConnection: .publish,
            details: .init(sfuId: "sfu-1", wasPreviouslyConnected: false)
        )
        // Persist a field the completion does not resend; it must survive.
        await subject.updateStage(attempt, details: .init(iceState: .notConnected))
        await subject.completeStage(attempt, outcome: .success)

        await waitForEventCount(3)
        let completed = event(stage: "PeerConnectionConnect", type: "completed")
        XCTAssertEqual(completed?.iceState, "NOT_CONNECTED")
    }

    func test_beginStage_withJoinReason_includesJoinReason() async {
        await subject.reportJoinInitiated()

        _ = await subject.beginStage(
            .coordinatorJoin,
            peerConnection: nil,
            details: .init(joinReason: .fullRejoin)
        )

        await waitForEventCount(2)
        let initiated = event(stage: "CoordinatorJoin", type: "initiated")
        XCTAssertEqual(initiated?.joinReason, "full-rejoin")
    }

    func test_eventsOfSameAttempt_shareJoinAttemptId() async {
        await subject.reportJoinInitiated()
        let attemptId = await subject.joinAttemptId
        let attempt = await subject.beginStage(.coordinatorJoin)
        await subject.completeStage(attempt, outcome: .success)

        await waitForEventCount(3)
        XCTAssertEqual(Set(recordedEvents().compactMap(\.joinAttemptId)), [attemptId])
    }

    func test_reportEvent_sendsInitiatedEventWithoutPendingCompletion() async {
        await subject.reportJoinInitiated()
        let attemptId = await subject.joinAttemptId
        await subject.reportEvent(
            .firstVideoFrame,
            details: .init(sfuId: "sfu-1", trackId: "track-1")
        )

        await waitForEventCount(2)
        let event = event(stage: "FirstVideoFrame", type: "initiated")
        XCTAssertEqual(event?.joinAttemptId, attemptId)
        XCTAssertNotNil(event?.stageId)
        XCTAssertEqual(event?.sfuId, "sfu-1")
        XCTAssertEqual(event?.trackId, "track-1")

        await subject.abortPendingStages(failure: .init(code: .clientAborted))
        await assertEventCountStaysAt(2)
    }

    // MARK: - PeerConnection

    func test_peerConnectionStage_mapsToWireValueAndCarriesDetails() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(
            .peerConnectionConnect,
            peerConnection: .publish,
            details: .init(
                sfuId: "sfu-1",
                callSessionId: "call-session-1",
                coordinatorConnectId: "85e8b199-d4ab-4eb7-a681-1d6916a86906",
                wasPreviouslyConnected: false
            )
        )
        await subject.completeStage(attempt, outcome: .success)

        await waitForEventCount(3)
        let pcEvents = recordedEvents().filter { $0.stage == "PeerConnectionConnect" }
        XCTAssertEqual(pcEvents.count, 2)
        XCTAssertTrue(pcEvents.allSatisfy { $0.peerConnection == "publish" })
        XCTAssertTrue(pcEvents.allSatisfy { $0.wasPreviouslyConnected == false })
        XCTAssertTrue(pcEvents.allSatisfy { $0.sfuId == "sfu-1" })
        XCTAssertTrue(
            pcEvents.allSatisfy {
                $0.coordinatorConnectId == "85e8b199-d4ab-4eb7-a681-1d6916a86906"
            }
        )
        XCTAssertTrue(pcEvents.allSatisfy { $0.callSessionId == "call-session-1" })
    }

    // MARK: - Failure completion

    func test_completeStage_failure_includesFailureFields() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(.peerConnectionConnect, peerConnection: .subscribe)
        await subject.completeStage(
            attempt,
            retryCount: 5,
            details: .init(sfuId: "sfu-9", iceState: .failed),
            failure: .init(code: .iceConnectivityFailed)
        )

        await waitForEventCount(3)
        let completed = event(stage: "PeerConnectionConnect", type: "completed")
        XCTAssertEqual(completed?.outcome, "failure")
        XCTAssertEqual(completed?.retryCountAttempt, 5)
        XCTAssertEqual(completed?.retryFailureCode, "ICE_CONNECTIVITY_FAILED")
        XCTAssertEqual(completed?.retryFailureReason, "ICE connectivity failed")
        XCTAssertEqual(completed?.iceState, "FAILED")
        XCTAssertEqual(completed?.sfuId, "sfu-9")
        XCTAssertEqual(completed?.peerConnection, "subscribe")
    }

    // MARK: - Abort handling

    func test_abortPendingStages_completesInFlightStagesAsFailure() async {
        await subject.reportJoinInitiated()
        let coordinatorJoin = await subject.beginStage(.coordinatorJoin)
        let wsJoin = await subject.beginStage(.wsJoin)
        await waitForEventCount(3) // join + 2 initiated

        await subject.abortPendingStages(failure: .init(code: .backendLeave))

        await waitForEventCount(5)
        let completions = recordedEvents().filter { $0.eventType == "completed" }
        XCTAssertEqual(completions.count, 2)
        XCTAssertTrue(completions.allSatisfy { $0.outcome == "failure" })
        XCTAssertTrue(completions.allSatisfy { $0.retryFailureCode == "BACKEND_LEAVE" })
        XCTAssertEqual(
            Set(completions.compactMap(\.stageId)),
            [coordinatorJoin.stageId, wsJoin.stageId]
        )
    }

    func test_completeStage_afterAbort_doesNotEmitDuplicateCompletion() async {
        await subject.reportJoinInitiated()
        let attempt = await subject.beginStage(.coordinatorJoin)
        await subject.abortPendingStages(failure: .init(code: .clientAborted))
        await waitForEventCount(3) // join + initiated + aborted completion

        await subject.completeStage(attempt, outcome: .success)

        // No additional completion is emitted for an already-resolved stage.
        await assertEventCountStaysAt(3)
    }

    func test_abortPendingStages_whenReporterIsReleased_stillDeliversFailureCompletion() async {
        var reporter: ClientEventReporter? = .init(
            api: mockAPI,
            context: .init(userId: "user-1", callType: "default", callId: "call-1"),
            retryPolicy: noDelayRetryPolicy,
            currentDate: { [dateHolder] in dateHolder!.date }
        )

        await reporter?.reportJoinInitiated()
        _ = await reporter?.beginStage(.wsJoin)
        await reporter?.abortPendingStages(failure: .init(code: .clientAborted))
        reporter = nil

        await waitForEventCount(3)
        let completed = event(stage: "WSJoin", type: "completed")
        XCTAssertEqual(completed?.outcome, "failure")
        XCTAssertEqual(completed?.retryFailureCode, "CLIENT_ABORTED")
    }

    // MARK: - Retry policy

    func test_send_retriesOnServerError_upToFiveAttempts() async {
        mockAPI.stub(
            for: .clientCallEvent,
            with: APIError(code: 0, details: [], duration: "", message: "boom", moreInfo: "", statusCode: 500)
        )

        await subject.reportJoinInitiated()

        await waitForCallCount(5)
        await assertCallCountStaysAt(5)
    }

    func test_send_doesNotRetryOnClientError() async {
        mockAPI.stub(
            for: .clientCallEvent,
            with: APIError(code: 0, details: [], duration: "", message: "bad request", moreInfo: "", statusCode: 400)
        )

        await subject.reportJoinInitiated()

        await waitForCallCount(1)
        await assertCallCountStaysAt(1)
    }

    func test_send_retriesOnNetworkError() async {
        mockAPI.stub(
            for: .clientCallEvent,
            with: URLError(.notConnectedToInternet)
        )

        await subject.reportJoinInitiated()

        await waitForCallCount(5)
        await assertCallCountStaysAt(5)
    }

    // MARK: - Description

    func test_clientEventDescription_ignoresNilFields() {
        let subject = ClientEvent(
            elapsedTime: 414,
            eventType: "completed",
            stage: "WSJoin",
            wasPreviouslyConnected: false
        )
        subject.type = "default"

        let description = subject.description

        XCTAssertTrue(description.contains("elapsedTime: 414"))
        XCTAssertTrue(description.contains("eventType: completed"))
        XCTAssertTrue(description.contains("stage: WSJoin"))
        XCTAssertTrue(description.contains("type: default"))
        XCTAssertTrue(description.contains("wasPreviouslyConnected: false"))
        XCTAssertFalse(description.contains("callSessionId"))
        XCTAssertFalse(description.contains("nil"))
    }

    func test_clientEvent_encodeToJSON_includesJoinReason() {
        let subject = ClientEvent(
            eventType: "initiated",
            joinReason: "first-attempt",
            stage: "CoordinatorJoin"
        )

        let data = try? CodableHelper.jsonEncoder.encode(subject)
        let json = data
            .flatMap { try? JSONSerialization.jsonObject(with: $0) as? [String: Any] }

        XCTAssertEqual(json?["join_reason"] as? String, "first-attempt")
    }

    // MARK: - Helpers

    private func recordedEvents() -> [ClientEvent] {
        (mockAPI.recordedInputPayload(ReportClientEventRequest.self, for: .clientCallEvent) ?? [])
            .flatMap(\.events)
    }

    private func event(stage: String, type: String) -> ClientEvent? {
        recordedEvents().first { $0.stage == stage && $0.eventType == type }
    }

    /// Polls until the recorded event count reaches `expected`, then asserts it
    /// equals `expected`. Deterministic in an async context (no main-thread
    /// `XCTNSPredicateExpectation`).
    private func waitForEventCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        for _ in 0..<200 where recordedEvents().count < expected {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        XCTAssertEqual(recordedEvents().count, expected, file: file, line: line)
    }

    private func waitForCallCount(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        for _ in 0..<200 where mockAPI.timesCalled(.clientCallEvent) < expected {
            try? await Task.sleep(nanoseconds: 25_000_000)
        }
        XCTAssertEqual(mockAPI.timesCalled(.clientCallEvent), expected, file: file, line: line)
    }

    private func assertEventCountStaysAt(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Give any spurious extra delivery a chance to land, then assert the
        // count did not grow.
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(recordedEvents().count, expected, file: file, line: line)
    }

    private func assertCallCountStaysAt(
        _ expected: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        try? await Task.sleep(nanoseconds: 300_000_000)
        XCTAssertEqual(mockAPI.timesCalled(.clientCallEvent), expected, file: file, line: line)
    }
}
