//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import CallKit
import Foundation
@testable import StreamVideo
@preconcurrency import XCTest

final class CallKitServiceTests: XCTestCase, @unchecked Sendable {

    private var completionError: Error?
    private lazy var subject: CallKitService! = .init()
    private lazy var uuidFactory: MockUUIDFactory! = .init()
    private lazy var callController: MockCXCallController! = .init()
    private lazy var callProvider: MockCXProvider! = .init()
    private lazy var mockApplicationStateAdapter: MockAppStateAdapter! = .init()
    private lazy var user: User! = .init(id: "test")
    private lazy var cid: String! = "default:\(callId)"
    private var callId: String = String(UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(10))
    private var localizedCallerName: String! = "Test Caller"
    private var callerId: String! = "test@example.com"
    private var mockAudioStore: MockRTCAudioStore! = .init()
    private lazy var mockPermissions: MockPermissionsStore! = .init()
    private lazy var mockedStreamVideo: MockStreamVideo! = MockStreamVideo(
        stubbedProperty: [
            MockStreamVideo.propertyKey(for: \.state): MockStreamVideo.State(user: user)
        ],
        user: user
    )
    private lazy var defaultGetCallResponse: GetCallResponse! = .dummy(
        call: .dummy(
            cid: cid,
            id: callId,
            settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
            type: .default
        )
    )

    override func setUp() {
        super.setUp()
        _ = mockPermissions
        _ = mockedStreamVideo
        InjectedValues[\.uuidFactory] = uuidFactory
        mockAudioStore.makeShared()
        mockApplicationStateAdapter.makeShared()
        subject.callController = callController
        subject.callProvider = callProvider
        callProvider.setDelegate(subject, queue: nil)
    }

    override func tearDown() {
        mockApplicationStateAdapter.dismante()
        mockPermissions.dismantle()
        subject = nil
        uuidFactory = nil
        callController = nil
        callProvider = nil
        user = nil
        cid = nil
        mockedStreamVideo = nil
        localizedCallerName = nil
        callerId = nil
        mockAudioStore = nil
        completionError = nil
        super.tearDown()
    }

    // MARK: - reportIncomingCall

    @MainActor
    func test_reportIncomingCall_hasVideoTrue_callUpdateWasConfiguredCorrectly() throws {
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: true
        ) { _ in }

        let invocation = try XCTUnwrap(callProvider.invocations.first)

        switch invocation {
        case let .reportNewIncomingCall(_, update, _):
            XCTAssertTrue(update.hasVideo)
        default:
            XCTFail()
        }
    }

    @MainActor
    func test_reportIncomingCall_hasVideoFalse_callUpdateWasConfiguredCorrectly() throws {
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        let invocation = try XCTUnwrap(callProvider.invocations.first)

        switch invocation {
        case let .reportNewIncomingCall(_, update, _):
            XCTAssertFalse(update.hasVideo)
        default:
            XCTFail()
        }
    }

    @MainActor
    func test_reportIncomingCall_withIconTemplateImageData_callUpdateWasConfiguredCorrectly() throws {
        subject = .init()
        let expectedData = String.unique.data(using: .utf8)
        subject.iconTemplateImageData = expectedData

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        XCTAssertEqual(subject.callProvider.configuration.iconTemplateImageData, expectedData)
    }

    @MainActor
    func test_reportIncomingCall_withoutIconTemplateImageData_callUpdateWasConfiguredCorrectly() throws {
        subject = .init()

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        XCTAssertNil(subject.callProvider.configuration.iconTemplateImageData)
    }

    @MainActor
    func test_reportIncomingCall_callProviderWasCalledWithExpectedValues() {
        // Given
        let expectation = self.expectation(description: "Report Incoming Call")

        // When
        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { error in
            self.completionError = error
            expectation.fulfill()
        }

        // Then
        waitForExpectations(timeout: defaultTimeout, handler: nil)
        XCTAssertNil(completionError)

        guard case let .reportNewIncomingCall(_, update, _) = callProvider.invocations.last else {
            return XCTFail()
        }

        XCTAssertEqual(update.localizedCallerName, localizedCallerName)
        XCTAssertEqual(update.remoteHandle?.value, callerId)
    }

    func test_reportIncomingCall_streamVideoIsNil_noCallWasCreatedAndNoActionIsBeingPerformed() async throws {
        try await assertWithoutRequestTransaction {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    @MainActor
    func test_reportIncomingCall_streamVideoDisconnectedAndThrowsError_callWasEnded() async throws {
        struct ConnectionError: Error {}
        stubConnectionState(to: .disconnected(error: nil))
        mockedStreamVideo.stub(for: .connect, with: ConnectionError())
        _ = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsAccepted_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasAccepted: true)
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsRejected_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasRejected: true)
    }

    func test_reportIncomingCall_streamVideoReconnectsAndCallIsRejectedByEveryoneElse_callWasEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))

        try await assertCallWasHandled(wasRejectedByEveryoneElse: true)
    }

    func test_reportIncomingCall_streamVideoReconnectsCallerDidNotReject_callWasNotEnded() async throws {
        stubConnectionState(to: .disconnected(error: nil))
        await stubCall(
            response: .dummy(
                call: .dummy(
                    session: .dummy(
                        acceptedBy: [:],
                        rejectedBy: [:]
                    )
                ),
                members: [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertNotRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsAccepted_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasAccepted: true)
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsRejected_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasRejected: true)
    }

    func test_reportIncomingCall_streamVideoConnectedAndCallIsRejectedByEveryoneElse_callWasEnded() async throws {
        stubConnectionState(to: .connected)

        try await assertCallWasHandled(wasRejectedByEveryoneElse: true)
    }

    @MainActor
    func test_reportIncomingCall_ringingTimeElapsed_callWasEnded() async throws {
        let ringingTimeoutSeconds = 1
        stubCall(
            response: .dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    settings: .dummy(
                        ring: .dummy(autoCancelTimeoutMs: ringingTimeoutSeconds * 1000)
                    ),
                    type: .default
                )
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }

            let waitExpectation = self.expectation(description: "Wait expectation")
            waitExpectation.isInverted = true
            wait(for: [waitExpectation], timeout: TimeInterval(ringingTimeoutSeconds * 2))
        }
    }

    @MainActor
    func test_reportIncomingCall_stateIsIdleAndCallWasAlreadyHandled_callWasEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    session: .dummy(acceptedBy: [user.id: Date()]),
                    settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
                    type: .default
                ),
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    @MainActor
    func test_reportIncomingCall_stateIsNotIdle_callWasEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000))),
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertWithoutRequestTransaction {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }

            let waitExpectationA = self.expectation(description: "a")
            waitExpectationA.isInverted = true
            wait(for: [waitExpectationA], timeout: 3)

            /// Receive another call while we are ringing the first one
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    // MARK: missingPermissionPolicy

    @MainActor
    func test_reportIncomingCall_hasNoMicrophonePermission_missingPermissionPolicyIsNone_callWasNotEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(
                    session: .dummy(
                        acceptedBy: [:],
                        rejectedBy: [:]
                    )
                ),
                members: [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo
        subject.missingPermissionPolicy = .none
        mockPermissions.stubMicrophonePermission(.denied)

        try await assertNotRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    @MainActor
    func test_reportIncomingCall_hasNoMicrophonePermission_missingPermissionPolicyIsEndCall_callWasEnded() async throws {
        stubCall(
            response: .dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    type: .default
                )
            )
        )
        subject.streamVideo = mockedStreamVideo
        subject.missingPermissionPolicy = .endCall
        mockPermissions.stubMicrophonePermission(.denied)

        try await assertRequestTransaction(CXEndCallAction.self) {
            self.subject.reportIncomingCall(
                self.cid,
                localizedCallerName: self.localizedCallerName,
                callerId: self.callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    // MARK: - accept

    @MainActor
    func test_accept_callWasJoinedAsExpected() async throws {
        let customCallSettings = CallSettings(audioOn: false, videoOn: true)
        subject.callSettings = customCallSettings

        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 1)

        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        await waitExpectation(timeout: 1)

        XCTAssertEqual(call.stubbedFunctionInput[.join]?.count, 1)
        let input = try XCTUnwrap(call.stubbedFunctionInput[.join]?.first)
        switch input {
        case let .join(_, _, _, _, callSettings):
            XCTAssertEqual(callSettings, customCallSettings)
        case .updateTrackSize:
            XCTFail()
        case .callKitActivated:
            XCTFail()
        case .reject:
            XCTFail()
        case .ring:
            XCTFail()
        case .setVideoFilter(videoFilter: let videoFilter):
            XCTFail()
        }
    }

    // MARK: - mute

    @MainActor
    func test_mute_hasMicrophonePermission_callWasMutedAsExpected() async throws {
        mockApplicationStateAdapter.stubbedState = .background
        let customCallSettings = CallSettings(audioOn: true, videoOn: true)
        subject.callSettings = customCallSettings
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo
        subject.missingPermissionPolicy = .none

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }
        await waitExpectation(timeout: 1)
        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(call: firstCallUUID)
        )
        await waitExpectation(timeout: 1)
        XCTAssertEqual(call.stubbedFunctionInput[.join]?.count, 1)
        let input = try XCTUnwrap(call.stubbedFunctionInput[.join]?.first)
        switch input {
        case let .join(_, _, _, _, callSettings):
            XCTAssertEqual(callSettings, customCallSettings)
        case .updateTrackSize:
            XCTFail()
        case .callKitActivated:
            XCTFail()
        case .reject:
            XCTFail()
        case .ring:
            XCTFail()
        case .setVideoFilter:
            XCTFail()
        }
        XCTAssertEqual(call.microphone.status, .enabled)

        // Once we have joined the call
        subject.provider(
            callProvider,
            perform: CXSetMutedCallAction(call: firstCallUUID, muted: true)
        )

        await fulfillment { call.microphone.status == .disabled }
    }

    @MainActor
    func test_mute_noMicrophonePermission_attemptsToUnmute_actionFails() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo
        subject.missingPermissionPolicy = .none
        let callStateWithMicOff = CallState()
        callStateWithMicOff.callSettings = .init(audioOn: false)
        call.stub(for: \.state, with: callStateWithMicOff)
        mockPermissions.stubMicrophonePermission(.denied)

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 1)
        XCTAssertEqual(call.state.callSettings.audioOn, false)

        // Once we have joined the call
        subject.provider(
            callProvider,
            perform: CXSetMutedCallAction(call: firstCallUUID, muted: false)
        )

        await waitExpectation(timeout: 1)
        XCTAssertEqual(call.state.callSettings.audioOn, false)
    }

    // MARK: - callAccepted

    @MainActor
    func test_callAccepted_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await assertReportCallEnded(.answeredElsewhere) {
            subject.callAccepted(
                .dummy(
                    call: .dummy(
                        cid: cid,
                        id: callId,
                        type: .default
                    ),
                    callCid: cid,
                    user: .dummy(id: user.id)
                )
            )
        }
    }

    @MainActor
    func test_callAccepted_fromAnotherUser_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await assertNoAction {
            subject.callAccepted(
                .dummy(
                    call: .dummy(
                        cid: cid,
                        id: callId,
                        type: .default
                    ),
                    callCid: cid
                )
            )
        }
    }

    // MARK: - callRejected

    @MainActor
    func test_callRejected_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await assertReportCallEnded(.declinedElsewhere) {
            subject.callRejected(
                .dummy(
                    call: .dummy(id: callId),
                    callCid: cid,
                    user: .dummy(id: user.id)
                )
            )
        }
    }

    @MainActor
    func test_callRejected_fromAnotherUser_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await assertNoAction {
            subject.callRejected(
                .dummy(
                    call: .dummy(id: callId),
                    callCid: cid
                )
            )
        }
    }

    @MainActor
    func test_callRejected_whileInCall_expectedTransactionWasRequestedAndRemainsInCall() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        await waitExpectation()

        XCTAssertEqual(subject.callCount, 1)

        // Stub with the new call
        let secondCallUUID = UUID()
        uuidFactory.getResult = secondCallUUID
        let secondCallId = "default:test-call-2"
        stubCall(overrideCallId: secondCallId, response: .dummy(
            call: .dummy(
                cid: callCid(from: secondCallId, callType: .default),
                id: secondCallId,
                settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10 * 1000)),
                type: .default
            )
        ))

        subject.reportIncomingCall(
            secondCallId,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        XCTAssertEqual(subject.callCount, 2)

        subject.provider(
            callProvider,
            perform: CXEndCallAction(
                call: secondCallUUID
            )
        )

        await fulfillment { [weak subject] in subject?.callCount == 1 }

        XCTAssertEqual(subject.callCount, 1)
    }

    // MARK: - callEnded

    @MainActor
    func test_callEnded_expectedTransactionWasRequested() async throws {
        stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callEnded(cid, ringingTimedOut: false)
        }
    }

    @MainActor
    func test_callEnded_ringingTimedOutTrue_expectedTransactionWasRequested() async throws {
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callEnded(cid, ringingTimedOut: true)
        }

        await fulfillment { call.timesCalled(.reject) == 1 }

        let reason = try XCTUnwrap(call.recordedInputPayload(String.self, for: .reject)?.first)
        XCTAssertEqual(reason, "timeout")
    }

    // MARK: - callParticipantLeft

    @MainActor
    func test_callParticipantLeft_participantsLeftMoreThanOne_callWasNotEnded() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 2)

        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        let callState = CallState()
        callState.participants = [.dummy(), .dummy()]
        call.stub(for: \.state, with: callState)
        try await assertNotRequestTransaction(CXEndCallAction.self) {
            subject.callParticipantLeft(.dummy(callCid: call.cId))
        }
    }

    @MainActor
    func test_callParticipantLeft_participantsLeftOnlyOne_callNotEnded() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(
            response: .dummy(
                call: defaultGetCallResponse.call,
                duration: "100",
                members: [],
                ownCapabilities: []
            )
        )
        subject.streamVideo = mockedStreamVideo

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 2)

        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        let callState = CallState()
        callState.participants = [.dummy()]
        call.stub(for: \.state, with: callState)

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.callParticipantLeft(.dummy(callCid: cid))
        }
    }

    // MARK: - didActivate

    @MainActor
    func test_didActivate_audioSessionWasConfiguredCorrectly() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        _ = stubCall(response: defaultGetCallResponse)
        subject.streamVideo = mockedStreamVideo
        let mockMiddleware = MockMiddleware<RTCAudioStore.Namespace>()
        mockAudioStore.audioStore.add(mockMiddleware)

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 1)
        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        await waitExpectation(timeout: 1)
        subject.provider(callProvider, didActivate: AVAudioSession.sharedInstance())

        await fulfillment {
            mockMiddleware.actionsReceived.first {
                switch $0 {
                case let .callKit(.activate(session)) where session === AVAudioSession.sharedInstance():
                    return true
                default:
                    return false
                }
            } != nil
        }
    }

    @MainActor
    func test_didActivate_callSettingsObservationWasSetCorrectly() async throws {
        let firstCallUUID = UUID()
        uuidFactory.getResult = firstCallUUID
        let call = stubCall(response: defaultGetCallResponse)
        let callState = CallState()
        callState.callSettings = .init(audioOn: true)
        call.stub(for: \.state, with: callState)
        subject.streamVideo = mockedStreamVideo
        let mockMiddleware = MockMiddleware<RTCAudioStore.Namespace>()
        mockAudioStore.audioStore.add(mockMiddleware)

        subject.reportIncomingCall(
            cid,
            localizedCallerName: localizedCallerName,
            callerId: callerId,
            hasVideo: false
        ) { _ in }

        await waitExpectation(timeout: 1)
        // Accept call
        subject.provider(
            callProvider,
            perform: CXAnswerCallAction(
                call: firstCallUUID
            )
        )

        await waitExpectation(timeout: 1)
        try await assertRequestTransaction(CXSetMutedCallAction.self) {
            subject.provider(callProvider, didActivate: AVAudioSession.sharedInstance())
        }
    }

    // MARK: - Private Helpers

    @MainActor
    private func assertReportCallEnded(
        _ expectedReason: CXCallEndedReason,
        actionBlock: @MainActor @Sendable () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        callProvider.reset()

        actionBlock()

        await fulfillment(timeout: defaultTimeout, file: file, line: line) {
            if case .reportCall = self.callProvider.invocations.last {
                return true
            } else {
                return false
            }
        }

        guard case let .reportCall(_, _, reason) = callProvider.invocations.last else {
            XCTFail(file: file, line: line)
            return
        }

        XCTAssertEqual(expectedReason, reason, file: file, line: line)
    }

    @MainActor
    private func assertNoAction(
        actionBlock: @MainActor @Sendable () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        callProvider.reset()

        actionBlock()

        await wait(for: 1)
        XCTAssertTrue(callProvider.invocations.isEmpty, file: file, line: line)
    }

    @MainActor
    private func assertRequestTransaction<T>(
        _ expected: T.Type,
        actionBlock: @MainActor @Sendable () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        callController.reset()

        actionBlock()

        await fulfillment(timeout: defaultTimeout, file: file, line: line) {
            (self.callController.requestWasCalledWith?.0.actions.last as? T) != nil
        }

        let action = try XCTUnwrap(
            callController.requestWasCalledWith?.0.actions.last,
            file: file,
            line: line
        )
        XCTAssertTrue(
            action is T,
            "Action type is \(String(describing: type(of: action))) instead of \(String(describing: T.self))",
            file: file,
            line: line
        )

        if let answerAction = action as? CXAnswerCallAction {
            subject.provider(callProvider, perform: answerAction)
        } else if let endAction = action as? CXEndCallAction {
            subject.provider(callProvider, perform: endAction)
        }
    }

    private func assertNotRequestTransaction<T>(
        _ expected: T.Type,
        actionBlock: @Sendable () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        callProvider.reset()

        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

        if let record = callController.requestWasCalledWith {
            let action = try XCTUnwrap(record.0.actions.first)
            XCTAssertFalse(
                action is T,
                "Action type is \(String(describing: type(of: action))) instead of \(String(describing: T.self))"
            )
        }
    }

    @MainActor
    private func assertWithoutRequestTransaction(
        actionBlock: @MainActor @Sendable () -> Void,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        actionBlock()

        await waitExpectation(timeout: 1, description: "Wait for internal async tasks to complete.")

        let action = callController.requestWasCalledWith?.0.actions.first
        XCTAssertNil(
            action,
            "Action type is \(String(describing: type(of: action))) instead of nil)"
        )
    }

    @MainActor
    private func assertCallWasHandled(
        otherMembers: [MemberResponse] = [.dummy()],
        wasAccepted: Bool = false,
        wasRejected: Bool = false,
        wasRejectedByEveryoneElse: Bool = false
    ) async throws {
        let acceptedBy = wasAccepted ? [user.id: Date()] : [:]
        let rejectedBy: [String: Date] = {
            if wasRejected {
                return [user.id: Date()]
            } else if wasRejectedByEveryoneElse {
                return otherMembers.reduce(into: [String: Date]()) { partialResult, otherMember in
                    partialResult[otherMember.userId] = .init()
                }
            } else {
                return [:]
            }
        }()
        stubCall(
            response: .dummy(
                call: .dummy(
                    session: .dummy(
                        acceptedBy: acceptedBy,
                        rejectedBy: rejectedBy
                    )
                ),
                members: otherMembers + [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo

        try await assertRequestTransaction(CXEndCallAction.self) {
            subject.reportIncomingCall(
                cid,
                localizedCallerName: localizedCallerName,
                callerId: callerId,
                hasVideo: false
            ) { _ in }
        }
    }

    @MainActor
    private func assertParticipantLeft(
        remainingParticipants: Int = 0
    ) async throws {
        stubCall(
            response: .dummy(
                members: (0...remainingParticipants)
                    .map { _ in MemberResponse.dummy() } + [.dummy(userId: user.id)]
            )
        )
        subject.streamVideo = mockedStreamVideo
    }

    private func waitExpectation(
        timeout: TimeInterval = defaultTimeout,
        description: String = "Wait expectation"
    ) async {
        let waitExpectation = expectation(description: description)
        waitExpectation.isInverted = true
        await safeFulfillment(of: [waitExpectation], timeout: timeout)
    }

    private func stubConnectionState(to status: ConnectionStatus) {
        let mockedState = mockedStreamVideo.state
        mockedState.connection = status
        mockedStreamVideo.stub(for: \.state, with: mockedState)
    }

    @MainActor
    @discardableResult
    private func stubCall(
        overrideCallId: String? = nil,
        response: GetCallResponse
    ) -> MockCall {
        let callId = overrideCallId ?? callId
        let call = MockCall(.dummy(callId: callId))
        call.stub(for: .get, with: response)
        call.stub(
            for: .join,
            with: JoinCallResponse.dummy(
                call: .dummy(
                    cid: cid,
                    id: callId,
                    type: .default
                )
            )
        )
        call.stub(for: .accept, with: AcceptCallResponse(duration: "0"))
        call.stub(for: .reject, with: RejectCallResponse(duration: "0"))
        call.stub(for: \.state, with: .init())
        mockedStreamVideo.stub(for: .call, with: call)
        return call
    }
}

private class MockUUIDFactory: UUIDProviding {
    var getResult: UUID?

    func get() -> UUID {
        getResult ?? .init()
    }
}
