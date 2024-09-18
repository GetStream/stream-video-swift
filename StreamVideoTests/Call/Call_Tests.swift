//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class Call_Tests: StreamVideoTestCase {

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
        var member = mockResponseBuilder.makeMemberResponse(id: userId)
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

    func test_updateState_fromTranscriptionStoppedEvent() throws {
        try assertUpdateState(
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

    func test_updateState_fromTranscriptionStartedEvent() throws {
        try assertUpdateState(
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

    func test_updateState_transcriptionStarted_fromTranscriptionFailedEvent() throws {
        try assertUpdateState(
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

    // MARK: - join

    func test_join_callControllerWasCalledOnlyOnce() async throws {
        LogConfig.level = .debug
        let mockCallController = MockCallController()
        let call = MockCall(.dummy(callController: mockCallController))
        call.stub(for: \.state, with: .init())
        mockCallController.stub(for: .join, with: JoinCallResponse.dummy())

        let executionExpectation = expectation(description: "Iteration expectation")
        executionExpectation.expectedFulfillmentCount = 10

        for _ in (0..<10) {
            Task {
                do {
                    _ = try await call.join()
                } catch {
                    log.error(error)
                }
                executionExpectation.fulfill()
            }
        }

        await safeFulfillment(of: [executionExpectation], timeout: defaultTimeout)

        XCTAssertEqual(mockCallController.timesJoinWasCalled, 1)
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

    // MARK: - Private helpers

    private func assertUpdateState(
        with steps: [UpdateStateStep],
        file: StaticString = #file,
        line: UInt = #line
    ) throws {
        let call = try XCTUnwrap(
            streamVideo?.call(callType: callType, callId: callId),
            file: file,
            line: line
        )

        for step in steps {
            call.state.updateState(from: step.event)
            XCTAssertTrue(step.validation(call), file: file, line: line)
        }
    }
}

private struct UpdateStateStep {
    var event: VideoEvent
    var validation: (Call) -> Bool

    init<V: Equatable>(
        event: VideoEvent,
        keyPath: KeyPath<Call, V>,
        expected: V
    ) {
        self.event = event
        validation = { $0[keyPath: keyPath] == expected }
    }
}

private final class MockCallController: CallController, Mockable {
    typealias FunctionKey = MockFunctionKey
    typealias FunctionInputKey = EmptyPayloadable

    enum MockFunctionKey: Hashable, CaseIterable {
        case join
    }

    var joinError: Error?
    var timesJoinWasCalled: Int = 0
    var stubbedProperty: [String: Any] = [:]
    var stubbedFunction: [FunctionKey: Any] = [:]
    var stubbedFunctionInput: [FunctionKey: [FunctionInputKey]] = [:]

    convenience init() {
        self.init(
            defaultAPI: .dummy(),
            user: .dummy(),
            callId: .unique,
            callType: .unique,
            apiKey: .unique,
            videoConfig: .dummy(),
            cachedLocation: nil
        )
    }

    func stub<T>(for keyPath: KeyPath<MockCallController, T>, with value: T) {
        stubbedProperty[propertyKey(for: keyPath)] = value
    }

    func stub<T>(for function: FunctionKey, with value: T) {
        stubbedFunction[function] = value
    }

    override func joinCall(
        create: Bool = true,
        callSettings: CallSettings?,
        options: CreateCallOptions? = nil,
        ring: Bool = false,
        notify: Bool = false
    ) async throws -> JoinCallResponse {
        timesJoinWasCalled += 1
        if let stub = stubbedFunction[.join] as? JoinCallResponse {
            return stub
        } else if let joinError {
            throw joinError
        } else {
            return try await super.joinCall(
                create: create,
                callSettings: callSettings,
                options: options,
                ring: ring,
                notify: notify
            )
        }
    }
}
