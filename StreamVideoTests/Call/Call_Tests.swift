//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@preconcurrency import XCTest

@MainActor
final class Call_Tests: StreamVideoTestCase, @unchecked Sendable {

    let callType = "default"
    let callId = "123"
    let callCid = "default:123"
    let userId = "test"
    let mockResponseBuilder = MockResponseBuilder()

    func test_updateState_fromCallAcceptedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            acceptedBy: [userId: Date()]
        )
        let userResponse = mockResponseBuilder.makeUserResponse()
        let event = CallAcceptedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            user: userResponse
        )

        // When
        call?.state.updateState(from: .typeCallAcceptedEvent(event))

        // Then
        XCTAssert(call?.cId == callCid)
        XCTAssert(call?.state.session?.acceptedBy[userId] != nil)
        XCTAssert(call?.state.backstage == false)
        XCTAssert(call?.state.egress?.broadcasting == false)
        XCTAssert(call?.state.recordingState == .noRecording)
        XCTAssert(call?.state.session != nil)
    }

    func test_updateState_fromCallRejectedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            rejectedBy: [userId: Date()]
        )
        let userResponse = mockResponseBuilder.makeUserResponse()
        let event = CallRejectedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            user: userResponse
        )

        // When
        call?.state.updateState(from: .typeCallRejectedEvent(event))

        // Then
        XCTAssert(call?.cId == callCid)
        XCTAssert(call?.state.session?.rejectedBy[userId] != nil)
        XCTAssert(call?.state.backstage == false)
        XCTAssert(call?.state.egress?.broadcasting == false)
        XCTAssert(call?.state.recordingState == .noRecording)
        XCTAssert(call?.state.session != nil)
    }

    func test_updateState_fromCallUpdatedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let event = CallUpdatedEvent(
            call: callResponse,
            callCid: callCid,
            capabilitiesByRole: [:],
            createdAt: Date()
        )

        // When
        call?.state.updateState(from: .typeCallUpdatedEvent(event))

        // Then
        XCTAssert(call?.cId == callCid)
        XCTAssert(call?.state.backstage == false)
        XCTAssert(call?.state.egress?.broadcasting == false)
        XCTAssert(call?.state.recordingState == .noRecording)
        XCTAssert(call?.state.session != nil)
    }

    func test_updateState_fromRecordingStartedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let event = CallRecordingStartedEvent(callCid: callCid, createdAt: Date())

        // When
        call?.state.updateState(from: .typeCallRecordingStartedEvent(event))

        // Then
        XCTAssert(call?.state.recordingState == .recording)
    }

    func test_updateState_fromRecordingStoppedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let event = CallRecordingStoppedEvent(callCid: callCid, createdAt: Date())

        // When
        call?.state.updateState(from: .typeCallRecordingStoppedEvent(event))

        // Then
        XCTAssert(call?.state.recordingState == .noRecording)
    }

    func test_updateState_fromPermissionsEvent() {
        // Given
        let videoConfig = VideoConfig.dummy()
        let userResponse = mockResponseBuilder.makeUserResponse(id: "testuser")
        let defaultAPI = DefaultAPI(
            basePath: "https://example.com",
            transport: URLSessionTransport(urlSession: URLSession.shared),
            middlewares: [DefaultParams(apiKey: "key1")]
        )
        let callController = CallController_Mock(
            defaultAPI: defaultAPI,
            user: userResponse.toUser,
            callId: callId,
            callType: callType,
            apiKey: "key1",
            videoConfig: videoConfig,
            cachedLocation: nil
        )
        let call = Call(
            callType: callType,
            callId: callId,
            coordinatorClient: defaultAPI,
            callController: callController
        )
        let event = UpdatedCallPermissionsEvent(
            callCid: callCid,
            createdAt: Date(),
            ownCapabilities: [.sendAudio],
            user: userResponse
        )

        // When
        call.state.updateState(from: .typeUpdatedCallPermissionsEvent(event))

        // Then
        XCTAssert(call.currentUserHasCapability(.sendAudio) == true)
        XCTAssert(call.currentUserHasCapability(.sendVideo) == false)
    }

    func test_updateState_fromMemberAddedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let userId = "test"
        let member = mockResponseBuilder.makeMemberResponse(id: userId)
        let event = CallMemberAddedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [member]
        )

        // When
        call?.state.updateState(from: .typeCallMemberAddedEvent(event))

        // Then
        XCTAssert(call?.state.members.first?.id == userId)
    }

    func test_updateState_fromMemberRemovedEvent() {
        // Given
        let userId = "test"
        let call = streamVideo?.call(callType: callType, callId: callId)
        call?.state.members = [Member(user: .init(id: userId), updatedAt: Date())]
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let event = CallMemberRemovedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [userId]
        )

        // When
        call?.state.updateState(from: .typeCallMemberRemovedEvent(event))

        // Then
        XCTAssert(call?.state.members.isEmpty == true)
    }

    func test_updateState_fromMemberUpdatedEvent() {
        // Given
        let userId = "test"
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        call?.state.members = [Member(user: .init(id: userId), updatedAt: Date())]
        let member = mockResponseBuilder.makeMemberResponse(id: userId)
        member.user.name = "newname"
        let event = CallMemberUpdatedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [member]
        )

        // When
        call?.state.updateState(from: .typeCallMemberUpdatedEvent(event))

        // Then
        XCTAssert(call?.state.members.first?.user.name == "newname")
    }

    // MARK: - Transcriptions

    func test_updateState_fromTranscriptionStoppedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallTranscriptionStoppedEvent(
                        CallTranscriptionStoppedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.transcribing,
                    expected: false
                )
            ]
        )
    }

    func test_updateState_fromTranscriptionStartedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallTranscriptionStartedEvent(
                        CallTranscriptionStartedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.transcribing,
                    expected: true
                )
            ]
        )
    }

    func test_updateState_transcriptionStarted_fromTranscriptionFailedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallTranscriptionStartedEvent(
                        CallTranscriptionStartedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.transcribing,
                    expected: true
                ),
                .init(
                    event: .typeCallTranscriptionFailedEvent(
                        CallTranscriptionFailedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.transcribing,
                    expected: false
                )
            ]
        )
    }

    // MARK: - Duration

    func test_call_duration() async throws {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let startDate = Date()
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            liveStartedAt: startDate
        )

        // When
        call?.state.update(from: callResponse)
        try await waitForCallEvent(nanoseconds: 1_500_000_000)

        // Then
        var duration = call?.state.duration ?? 0
        XCTAssertTrue(Int(duration) >= 1)
        XCTAssertEqual(startDate, call?.state.startedAt)

        // When
        let endCallResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            liveStartedAt: startDate,
            liveEndedAt: Date()
        )
        call?.state.update(from: endCallResponse)

        // Then
        duration = call?.state.duration ?? 0
        XCTAssertTrue(Int(duration) >= 1)
    }

    // MARK: - setIncomingVideoQualitySettings

    func test_setIncomingVideoQualitySettings_updatesCallState() async throws {
        let call = streamVideo?.call(callType: callType, callId: callId)
        let incomingVideoQualitySettings = IncomingVideoQualitySettings.manual(
            group: .custom(sessionIds: [.unique, .unique]),
            targetSize: .init(
                width: 11,
                height: 10
            )
        )

        await call?.setIncomingVideoQualitySettings(incomingVideoQualitySettings)

        await fulfilmentInMainActor {
            call?.state.incomingVideoQualitySettings == incomingVideoQualitySettings
        }
    }

    // MARK: - setDisconnectionTimeout

    func test_setDisconnectionTimeout_setDisconnectionTimeoutOnCallController() async throws {
        let mockCallController = MockCallController()
        let call = MockCall(.dummy(callController: mockCallController))
        call.stub(for: \.state, with: .init())

        call.setDisconnectionTimeout(11)

        XCTAssertEqual(
            mockCallController.recordedInputPayload(
                TimeInterval.self,
                for: .setDisconnectionTimeout
            )?.first,
            11
        )
    }

    // MARK: - ClosedCaptions

    func test_updateState_fromClosedCaptionsStoppedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallClosedCaptionsStoppedEvent(
                        CallClosedCaptionsStoppedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.captioning,
                    expected: false
                )
            ]
        )
    }

    func test_updateState_fromClosedCaptionsStartedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallClosedCaptionsStartedEvent(
                        CallClosedCaptionsStartedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.captioning,
                    expected: true
                )
            ]
        )
    }

    func test_updateState_closedCaptionsStarted_fromClosedCaptionsFailedEvent() async throws {
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallClosedCaptionsStartedEvent(
                        CallClosedCaptionsStartedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.captioning,
                    expected: true
                ),
                .init(
                    event: .typeCallClosedCaptionsFailedEvent(
                        CallClosedCaptionsFailedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.captioning,
                    expected: false
                )
            ]
        )
    }

    func test_updateState_closedCaptionEventReceived() async throws {
        let expected = CallClosedCaption(
            endTime: .init(),
            speakerId: .unique,
            startTime: .init(),
            text: .unique,
            user: .dummy()
        )
        try await assertUpdateState(
            with: [
                .init(
                    event: .typeCallClosedCaptionsStartedEvent(
                        CallClosedCaptionsStartedEvent(callCid: callCid, createdAt: .init())
                    ),
                    keyPath: \.state.captioning,
                    expected: true
                ),
                .init(
                    event: .typeClosedCaptionEvent(
                        .init(
                            callCid: callCid,
                            closedCaption: expected,
                            createdAt: .init()
                        )
                    ),
                    keyPath: \.state.closedCaptions,
                    onEventUpdate: true,
                    expected: [expected]
                )
            ]
        )
    }

    // MARK: - Recording

    func test_coordinatorEventReceived_startedRecording_updatesStateCorrectly() async throws {
        try await assertCoordinatorEventReceived(
            .typeCallRecordingStartedEvent(
                CallRecordingStartedEvent(callCid: callCid, createdAt: Date())
            )
        ) { call in await fulfilmentInMainActor { call.state.recordingState == .recording } }
    }

    func test_coordinatorEventReceived_startedRecordingForAnotherCall_doesNotUpdateState() async throws {
        try await assertCoordinatorEventReceived(
            .typeCallRecordingStartedEvent(
                CallRecordingStartedEvent(callCid: .unique, createdAt: Date())
            )
        ) { @MainActor call in
            await wait(for: 1)
            XCTAssertEqual(call.state.recordingState, .noRecording)
        }
    }

    // MARK: - join

    func test_join_callControllerWasCalledOnlyOnce() async throws {
        let mockCallController = MockCallController()
        let call = MockCall(.dummy(callController: mockCallController))
        call.stub(for: \.state, with: .init())
        mockCallController.stub(for: .join, with: JoinCallResponse.dummy())

        let executionExpectation = expectation(description: "Iteration expectation")
        executionExpectation.expectedFulfillmentCount = 10

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in (0..<executionExpectation.expectedFulfillmentCount) {
                group.addTask {
                    _ = try await call.join()
                    executionExpectation.fulfill()
                }
            }

            try await group.waitForAll()
        }

        await safeFulfillment(of: [executionExpectation], timeout: defaultTimeout)

        XCTAssertEqual(mockCallController.timesCalled(.join), 1)
    }
    
    func test_call_customSorting() async throws {
        // Given
        let nameComparator: StreamSortComparator<CallParticipant> = {
            comparison($0, $1, keyPath: \.name)
        }
        let call = streamVideo?.call(callType: callType, callId: callId)
        call?.updateParticipantsSorting(with: [nameComparator])
        
        // When
        call?.state.participantsMap = [
            "martin": .dummy(id: "martin", name: "Martin", isSpeaking: true),
            "ilias": .dummy(id: "ilias", name: "Ilias", pin: PinInfo(isLocal: false, pinnedAt: Date())),
            "alexey": .dummy(id: "alexey", name: "Alexey")
        ]
        
        // Then
        let participants = call?.state.participants
        XCTAssertEqual(participants?[0].name, "Alexey")
        XCTAssertEqual(participants?[1].name, "Ilias")
    }
    
    // MARK: - RTMP Broadcasting
    
    func test_updateState_fromBroadcastStartedEvent() async throws {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let event = CallRtmpBroadcastStartedEvent(callCid: callCid, createdAt: Date(), name: "test")

        // When
        call?.state.updateState(from: .typeCallRtmpBroadcastStartedEvent(event))

        // Then
        XCTAssert(call?.state.broadcasting == true)
    }
    
    func test_updateState_fromBroadcastStoppedEvent() async throws {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let event = CallRtmpBroadcastStoppedEvent(callCid: callCid, createdAt: Date(), name: "test")
        call?.state.broadcasting = true

        // When
        call?.state.updateState(from: .typeCallRtmpBroadcastStoppedEvent(event))

        // Then
        XCTAssert(call?.state.broadcasting == false)
    }
    
    func test_updateState_fromBroadcastFailedEvent() async throws {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let event = CallRtmpBroadcastFailedEvent(callCid: callCid, createdAt: Date(), name: "test")
        call?.state.broadcasting = true

        // When
        call?.state.updateState(from: .typeCallRtmpBroadcastFailedEvent(event))

        // Then
        XCTAssert(call?.state.broadcasting == false)
    }

    // MARK: - Private helpers

    private func assertUpdateState(
        with steps: [UpdateStateStep],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        let call = try XCTUnwrap(
            streamVideo?.call(callType: callType, callId: callId),
            file: file,
            line: line
        )

        for step in steps {
            if step.onEventUpdate {
                call.onEvent(.coordinatorEvent(step.event))
                await fulfillment(timeout: 2) { step.validation(call) }
            } else {
                call.state.updateState(from: step.event)
            }
            XCTAssertTrue(step.validation(call), file: file, line: line)
        }
    }

    private func assertCoordinatorEventReceived(
        _ event: VideoEvent,
        fulfillmentHandler: @MainActor(Call) async throws -> Void
    ) async throws {
        let streamVideo = try XCTUnwrap(streamVideo)
        let call = streamVideo.call(callType: callType, callId: callId)

        streamVideo
            .eventNotificationCenter
            .process(.coordinatorEvent(event))

        try await fulfillmentHandler(call)
    }
}

private struct UpdateStateStep: Sendable {
    var event: VideoEvent
    var onEventUpdate: Bool
    var validation: @Sendable(Call) -> Bool

    init<V: Equatable & Sendable>(
        event: VideoEvent,
        keyPath: KeyPath<Call, V>,
        onEventUpdate: Bool = false,
        expected: V
    ) {
        self.event = event
        self.onEventUpdate = onEventUpdate
        validation = { @Sendable in $0[keyPath: keyPath] == expected }
    }
}
