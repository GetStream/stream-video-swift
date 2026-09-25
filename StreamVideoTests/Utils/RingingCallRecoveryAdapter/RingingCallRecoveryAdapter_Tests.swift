//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import XCTest

@MainActor
final class RingingCallRecoveryAdapter_Tests: XCTestCase, @unchecked Sendable {

    private var streamVideo: MockStreamVideo!
    private var call: Call!
    private var api: MockDefaultAPIEndpoints!
    private let sessionId = "ring-session"

    override func setUp() async throws {
        try await super.setUp()
        streamVideo = .init()
        api = .init()
        api.stub(for: .rejectCall, with: RejectCallResponse(duration: "0"))
        call = Call(
            callType: "default",
            callId: "ring-test",
            coordinatorClient: api,
            callController: .dummy(defaultAPI: api)
        )
        call.ringingRecovery = .init(
            call,
            quietPeriod: 0.02,
            pollInterval: 0.02,
            finalReadGrace: 0.05
        )
        call.ringingRecovery.configure(on: streamVideo)
        call.state.createdBy = streamVideo.user
        call.state.session = .dummy(id: sessionId)
        call.state.settings = .dummy(
            ring: .init(
                autoCancelTimeoutMs: 500,
                incomingCallTimeoutMs: 500,
                missedCallTimeoutMs: 1000
            )
        )
    }

    override func tearDown() async throws {
        streamVideo.state.ringingCall = nil
        call = nil
        api = nil
        streamVideo = nil
        try await super.tearDown()
    }

    func test_outgoingRing_afterQuietPeriod_readsOriginalSessionAndMergesOutcome() async {
        let acceptedAt = Date(timeIntervalSince1970: 100)
        api.stub(for: .getCallRingState, with: response(acceptedBy: ["callee": acceptedAt]))
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.call.state.session?.acceptedBy["callee"] == acceptedAt
        }
        XCTAssertEqual(
            api.recordedInputPayload(
                (String, String, String).self,
                for: .getCallRingState
            )?.first?.2,
            sessionId
        )
    }

    func test_activeCall_ringWithoutMembers_startsRecovery() async throws {
        let acceptedAt = Date(timeIntervalSince1970: 100)
        api.stub(
            for: .ringCall,
            with: RingCallResponse(duration: "0", membersIds: [])
        )
        api.stub(for: .getCallRingState, with: response(acceptedBy: ["callee": acceptedAt]))
        streamVideo.state.activeCall = call

        try await call.ring(request: .init())

        await fulfilmentInMainActor {
            self.call.state.session?.acceptedBy["callee"] == acceptedAt
        }
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_createRing_historicalRosterAcceptance_continuesPollingAndTimesOut() async throws {
        let historicalAcceptance = ["previous-callee": Date(timeIntervalSince1970: 100)]
        api.stub(
            for: .getOrCreateCall,
            with: GetOrCreateCallResponse(
                call: .dummy(
                    cid: call.cId,
                    createdBy: .dummy(id: streamVideo.user.id),
                    id: call.callId,
                    session: .dummy(acceptedBy: historicalAcceptance, id: sessionId),
                    settings: try XCTUnwrap(call.state.settings),
                    type: call.callType
                ),
                created: false,
                duration: "0",
                members: [
                    .dummy(userId: "previous-callee"),
                    .dummy(userId: "invited-callee")
                ],
                ownCapabilities: []
            )
        )
        api.stub(for: .getCallRingState, with: response(acceptedBy: historicalAcceptance))

        try await call.create(members: [.init(userId: "invited-callee")], ring: true)

        await fulfilmentInMainActor {
            self.streamVideo.state.ringingCall == nil && self.api.timesCalled(.rejectCall) == 1
        }
        XCTAssertGreaterThan(api.timesCalled(.getCallRingState), 1)
        XCTAssertEqual(call.state.session?.acceptedBy, historicalAcceptance)
        XCTAssertNil(call.state.session?.endedAt)
        XCTAssertEqual(Set(call.state.members.map(\.id)), ["previous-callee", "invited-callee"])
    }

    func test_outgoingRing_http404_stopsPolling() async {
        await assertPermanentFailureStopsPolling(statusCode: 404)
    }

    func test_outgoingRing_http400_stopsPolling() async {
        await assertPermanentFailureStopsPolling(statusCode: 400)
    }

    private func assertPermanentFailureStopsPolling(statusCode: Int) async {
        api.getCallRingStateHandler = {
            throw APIError(
                code: 12345,
                details: [],
                duration: "0",
                message: "session missing",
                moreInfo: "",
                statusCode: statusCode
            )
        }
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.streamVideo.state.ringingCall == nil && self.api.timesCalled(.rejectCall) == 1
        }
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_outgoingRing_matchingWebSocketEvent_delaysPollUntilQuiet() async {
        let readStarted = expectation(description: "read after quiet period")
        let accepted = response(acceptedBy: ["callee": Date()])
        call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 2000))
        call.ringingRecovery = .init(call, quietPeriod: 0.3)
        call.ringingRecovery.configure(on: streamVideo)
        api.getCallRingStateHandler = {
            readStarted.fulfill()
            return accepted
        }
        streamVideo.state.ringingCall = call
        await wait(for: 0.15)
        let eventTime = ProcessInfo.processInfo.systemUptime
        streamVideo.process(.coordinatorEvent(.typeCallRejectedEvent(.init(
            call: .dummy(session: .dummy(id: sessionId)),
            callCid: call.cId,
            createdAt: Date(),
            user: .dummy(id: "other-callee")
        ))))

        await fulfillment(of: [readStarted], timeout: 2)

        XCTAssertGreaterThanOrEqual(ProcessInfo.processInfo.systemUptime - eventTime, 0.28)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_outgoingRing_clearedDuringRead_discardsResponse() async {
        let gate = RingStateResponseGate()
        let started = expectation(description: "read started")
        let result = response(acceptedBy: ["callee": Date()])
        api.getCallRingStateHandler = {
            started.fulfill()
            await gate.wait()
            return result
        }
        streamVideo.state.ringingCall = call
        await fulfillment(of: [started], timeout: 10)
        streamVideo.state.ringingCall = nil
        await gate.release()

        await wait(for: 0.1)
        XCTAssertNil(call.state.session?.acceptedBy["callee"])
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_outgoingRing_transientFailure_retriesAndAppliesOutcome() async {
        let api = api!
        let accepted = response(acceptedBy: ["callee": Date()])
        api.getCallRingStateHandler = {
            if api.timesCalled(.getCallRingState) == 1 {
                throw APIError(
                    code: 1, details: [], duration: "0", message: "unavailable",
                    moreInfo: "", statusCode: 503
                )
            }
            return accepted
        }
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor { self.call.state.session?.acceptedBy["callee"] != nil }

        XCTAssertEqual(api.timesCalled(.getCallRingState), 2)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
    }

    func test_outgoingRing_readCrossesDeadline_reusesReadAndAcceptsWithinGrace() async {
        let gate = RingStateResponseGate()
        let started = expectation(description: "read started")
        let accepted = response(acceptedBy: ["callee": Date()])
        call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 100))
        call.ringingRecovery = .init(call, quietPeriod: 0.01, finalReadGrace: 0.5)
        call.ringingRecovery.configure(on: streamVideo)
        api.getCallRingStateHandler = {
            started.fulfill()
            await gate.wait()
            return accepted
        }
        streamVideo.state.ringingCall = call
        await fulfillment(of: [started], timeout: 2)

        await wait(for: 0.15)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
        await gate.release()

        await fulfilmentInMainActor { self.call.state.session?.acceptedBy["callee"] != nil }
        XCTAssertTrue(streamVideo.state.ringingCall === call)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
    }

    func test_outgoingRing_sessionReplacedDuringRead_recoversNewSession() async {
        let gate = RingStateResponseGate()
        let started = expectation(description: "old session read started")
        let api = api!
        let oldResponse = response(acceptedBy: ["old-callee": Date()])
        let newResponse = response(acceptedBy: ["new-callee": Date()])
        newResponse.sessionId = "new-session"
        api.getCallRingStateHandler = {
            if api.timesCalled(.getCallRingState) == 1 {
                started.fulfill()
                await gate.wait()
                return oldResponse
            }
            return newResponse
        }
        streamVideo.state.ringingCall = call
        await fulfillment(of: [started], timeout: 2)

        call.state.session = .dummy(id: "new-session")
        await fulfilmentInMainActor { self.call.state.session?.acceptedBy["new-callee"] != nil }
        await gate.release()
        await wait(for: 0.05)

        XCTAssertEqual(call.state.session?.id, "new-session")
        XCTAssertNil(call.state.session?.acceptedBy["old-callee"])
        XCTAssertEqual(api.timesCalled(.getCallRingState), 2)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
    }

    func test_outgoingRing_responseForAnotherCall_ignoresAndRetries() async {
        let api = api!
        let wrongCall = response(acceptedBy: ["wrong-callee": Date()])
        wrongCall.callCid = "default:another-call"
        let accepted = response(acceptedBy: ["callee": Date()])
        api.getCallRingStateHandler = {
            api.timesCalled(.getCallRingState) == 1 ? wrongCall : accepted
        }
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor { self.call.state.session?.acceptedBy["callee"] != nil }

        XCTAssertNil(call.state.session?.acceptedBy["wrong-callee"])
        XCTAssertEqual(api.timesCalled(.getCallRingState), 2)
    }

    func test_outgoingRing_deadlineFinalReadFindsAcceptance_doesNotTimeout() async {
        call.state.settings = .dummy(
            ring: .init(
                autoCancelTimeoutMs: 30,
                incomingCallTimeoutMs: 30,
                missedCallTimeoutMs: 1000
            )
        )
        call.ringingRecovery = .init(call, quietPeriod: 0.1, finalReadGrace: 0.05)
        call.ringingRecovery.configure(on: streamVideo)
        api.stub(for: .getCallRingState, with: response(acceptedBy: ["callee": Date()]))
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor { self.call.state.session?.acceptedBy["callee"] != nil }
        XCTAssertTrue(streamVideo.state.ringingCall === call)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_outgoingRing_deadlineFinalReadFails_leavesWithoutServerEnd() async {
        call.state.settings = .dummy(
            ring: .init(
                autoCancelTimeoutMs: 30,
                incomingCallTimeoutMs: 30,
                missedCallTimeoutMs: 1000
            )
        )
        call.ringingRecovery = .init(call, quietPeriod: 0.1, finalReadGrace: 0.05)
        call.ringingRecovery.configure(on: streamVideo)
        api.getCallRingStateHandler = {
            throw APIError(
                code: 12345,
                details: [],
                duration: "0",
                message: "unavailable",
                moreInfo: "",
                statusCode: 503
            )
        }
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.streamVideo.state.ringingCall == nil && self.api.timesCalled(.rejectCall) == 1
        }
        XCTAssertNil(call.state.session?.endedAt)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
    }

    func test_outgoingRing_endedWithoutSession_doesNotReject() async {
        let left = expectation(
            forNotification: Notification.Name(CallNotification.callEnded),
            object: call
        )
        left.isInverted = true
        call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 30))
        call.state.session = nil
        call.state.endedAt = Date()
        streamVideo.state.ringingCall = call

        await fulfillment(of: [left], timeout: 0.2)

        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
        XCTAssertTrue(streamVideo.state.ringingCall === call)
    }

    func test_outgoingRing_sessionChangesDuringReasonLookup_doesNotRejectNewSession() async {
        let call = call!
        let lookedUpReason = expectation(description: "reason looked up")
        let left = expectation(
            forNotification: Notification.Name(CallNotification.callEnded),
            object: call
        )
        left.isInverted = true
        call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 30))
        api.stub(for: .getCallRingState, with: response(acceptedBy: [:]))
        streamVideo.rejectionReasonProvider = RingSessionChangingReasonProvider {
            call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 10000))
            call.state.session = .dummy(id: "replacement-session")
            lookedUpReason.fulfill()
        }
        streamVideo.state.ringingCall = call

        await fulfillment(of: [lookedUpReason], timeout: 2)
        await fulfillment(of: [left], timeout: 0.2)

        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
        XCTAssertTrue(streamVideo.state.ringingCall === call)
        XCTAssertEqual(call.state.session?.id, "replacement-session")
    }

    func test_outgoingRing_sessionNeverHydrates_timesOutWithoutRead() async {
        call.state.session = nil
        call.state.settings = .dummy(
            ring: .init(
                autoCancelTimeoutMs: 30,
                incomingCallTimeoutMs: 30,
                missedCallTimeoutMs: 1000
            )
        )
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.streamVideo.state.ringingCall == nil && self.api.timesCalled(.rejectCall) == 1
        }
        XCTAssertEqual(api.timesCalled(.getCallRingState), 0)
        XCTAssertNil(call.state.session)
    }

    func test_outgoingRing_sessionHydratesDuringReasonLookup_readsBeforeTimingOut() async {
        let call = call!
        let left = expectation(
            forNotification: Notification.Name(CallNotification.callEnded),
            object: call
        )
        left.isInverted = true
        call.state.session = nil
        call.state.settings = .dummy(ring: .dummy(autoCancelTimeoutMs: 30))
        api.stub(for: .getCallRingState, with: response(acceptedBy: ["callee": Date()]))
        streamVideo.rejectionReasonProvider = RingSessionChangingReasonProvider { [sessionId] in
            call.state.session = .dummy(id: sessionId)
        }
        streamVideo.state.ringingCall = call

        await fulfillment(of: [left], timeout: 0.2)

        XCTAssertTrue(streamVideo.state.ringingCall === call)
        XCTAssertNotNil(call.state.session?.acceptedBy["callee"])
        XCTAssertEqual(api.timesCalled(.getCallRingState), 1)
        XCTAssertEqual(api.timesCalled(.rejectCall), 0)
    }

    func test_outgoingRing_stalledFinalRead_timesOutWithinGraceAndDiscardsLateResult() async {
        let gate = RingStateResponseGate()
        let result = response(acceptedBy: ["callee": Date()])
        call.state.settings = .dummy(
            ring: .init(
                autoCancelTimeoutMs: 30,
                incomingCallTimeoutMs: 30,
                missedCallTimeoutMs: 1000
            )
        )
        call.ringingRecovery = .init(call, quietPeriod: 0.1, finalReadGrace: 0.05)
        call.ringingRecovery.configure(on: streamVideo)
        api.getCallRingStateHandler = {
            await gate.wait()
            return result
        }
        streamVideo.state.ringingCall = call

        await fulfilmentInMainActor {
            self.streamVideo.state.ringingCall == nil && self.api.timesCalled(.rejectCall) == 1
        }
        await gate.release()
        await wait(for: 0.05)
        XCTAssertNil(call.state.session?.acceptedBy["callee"])
        XCTAssertNil(call.state.session?.endedAt)
    }

    func test_incomingRing_reconnect_refreshesStateWithoutCallerPollDelay() async {
        call.state.createdBy = .dummy(id: "caller")
        let acceptedAt = Date(timeIntervalSince1970: 100)
        api.stub(for: .getCall, with: GetCallResponse(
            call: .dummy(
                cid: call.cId,
                createdBy: .dummy(id: "caller"),
                id: call.callId,
                session: .dummy(acceptedBy: [streamVideo.user.id: acceptedAt], id: sessionId),
                type: call.callType
            ),
            duration: "0",
            members: [],
            ownCapabilities: []
        ))
        call.ringingRecovery = .init(call)
        call.ringingRecovery.configure(on: streamVideo)
        streamVideo.state.ringingCall = call
        await Task.yield()

        streamVideo.process(.internalEvent(WSConnected()))

        await fulfilmentInMainActor(timeout: 2) {
            self.call.state.session?.acceptedBy[self.streamVideo.user.id] == acceptedAt
        }
        XCTAssertEqual(api.timesCalled(.getCall), 1)
        XCTAssertEqual(api.timesCalled(.getCallRingState), 0)
    }

    func test_outgoingRing_rejectionStalls_leavesBeforeRequestCompletes() async {
        let gate = RingStateResponseGate()
        let started = expectation(description: "reject started")
        api.stub(for: .getCallRingState, with: response(acceptedBy: [:]))
        api.rejectCallHandler = {
            started.fulfill()
            await gate.wait()
            return RejectCallResponse(duration: "0")
        }
        streamVideo.state.ringingCall = call

        await fulfillment(of: [started], timeout: 2)
        await fulfilmentInMainActor(timeout: 2) { self.streamVideo.state.ringingCall == nil }
        XCTAssertNil(call.state.session?.endedAt)
        XCTAssertEqual(
            api.recordedInputPayload((String, String, RejectCallRequest).self, for: .rejectCall)?.first?.2.reason,
            "cancel"
        )
        await gate.release()
    }

    private func response(acceptedBy: [String: Date]) -> GetCallRingStateResponse {
        GetCallRingStateResponse(
            acceptedBy: acceptedBy,
            callCid: call.cId,
            createdByUserId: streamVideo.user.id,
            duration: "0",
            missedBy: [:],
            rejectedBy: [:],
            sessionId: sessionId
        )
    }
}

private struct RingSessionChangingReasonProvider: RejectionReasonProviding {
    let updateSession: @MainActor @Sendable () -> Void

    @MainActor
    func reason(for callCid: String, ringTimeout: Bool) async -> String? {
        updateSession()
        return "cancel"
    }
}

private actor RingStateResponseGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var released = false

    func wait() async {
        if released { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func release() {
        released = true
        continuation?.resume()
        continuation = nil
    }
}
