//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallViewModel_Tests: StreamVideoTestCase {
    
    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    
    private let mockResponseBuilder = MockResponseBuilder()
    
    let firstUser: Member = Member(user: StreamVideo.mockUser, updatedAt: .now)
    let secondUser: Member = Member(user: User(id: "test2"), updatedAt: .now)
    let thirdUser: Member = Member(user: User(id: "test3"), updatedAt: .now)
    let callType: String = .default
    var callId: String!
    var callCid: String!

    lazy var participants = [firstUser, secondUser]
    
    @MainActor
    override func setUp() async throws {
        try await super.setUp()
        LogConfig.level = .debug
        callId = UUID().uuidString
        callCid = "\(callType):\(callId!)"
    }
    
    // MARK: - Call Events

    func test_startCall_joiningState() {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .joining)
    }
    
    func test_startCall_outgoingState() {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants, ring: true)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .outgoing)
    }
    
    func test_outgoingCall_rejectedEvent() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        try await waitForCallEvent()
        
        // When
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            rejectedBy: [secondUser.userId: Date()]
        )
        let event = CallRejectedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            user: User(id: secondUser.userId).toUserResponse()
        )
        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRejectedEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle, nanoseconds: 5_000_000_000)
    }
    
    func test_outgoingCall_rejectedEventThreeParticipants() async throws {
        // Given
        let threeParticipants = participants + [thirdUser]
        let callViewModel = callViewModelWithRingingCall(participants: threeParticipants)
        try await waitForCallEvent()
        
        // When
        let firstCallResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            rejectedBy: [secondUser.userId: Date()]
        )
        let firstReject = CallRejectedEvent(
            call: firstCallResponse,
            callCid: callCid,
            createdAt: Date(),
            user: User(id: secondUser.userId).toUserResponse()
        )
        let first = WrappedEvent.coordinatorEvent(.typeCallRejectedEvent(firstReject))
        eventNotificationCenter?.process(first)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .outgoing, nanoseconds: 5_000_000_000)

        // When
        let secondCallResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid,
            rejectedBy: [secondUser.userId: Date(), thirdUser.userId: Date()]
        )
        let secondReject = CallRejectedEvent(
            call: secondCallResponse,
            callCid: callCid,
            createdAt: Date(),
            user: User(id: thirdUser.userId).toUserResponse()
        )
        let second = WrappedEvent.coordinatorEvent(.typeCallRejectedEvent(secondReject))
        eventNotificationCenter?.process(second)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle, nanoseconds: 5_000_000_000)
    }
    
    func test_outgoingCall_callEndedEvent() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        try await waitForCallEvent()
        
        // When
        let event = CallEndedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date()
        )
        eventNotificationCenter?.process(.coordinatorEvent(.typeCallEndedEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_blockEventCurrentUser() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        try await waitForCallEvent()
        
        // When
        let event = BlockedUserEvent(
            callCid: callCid,
            createdAt: Date(),
            user: User(id: firstUser.userId).toUserResponse()
        )
        eventNotificationCenter?.process(.coordinatorEvent(.typeBlockedUserEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_blockEventOtherUser() async throws {
        // Given
        let callViewModel = CallViewModel()
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callData = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        call?.state.update(from: callData)
        callViewModel.setActiveCall(call)
        try await waitForCallEvent()

        // When
        let event = BlockedUserEvent(
            callCid: callCid,
            createdAt: Date(),
            user: User(id: secondUser.userId).toUserResponse()
        )
        eventNotificationCenter?.process(.coordinatorEvent(.typeBlockedUserEvent(event)))
        
        // Then
        try await XCTAssertWithDelay(callViewModel.call?.state.blockedUserIds.first == secondUser.userId)
    }
    
    func test_outgoingCall_hangUp() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants, ring: true)
        try await waitForCallEvent()
        callViewModel.hangUp()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle, nanoseconds: 5_000_000_000)
    }
    
    func test_incomingCall_acceptCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        let acceptResponse = AcceptCallResponse(duration: "1.0")
        let data = try JSONEncoder.default.encode(acceptResponse)
        httpClient.dataResponses = [data]
        
        // When
        try await waitForCallEvent()
        let event = CallRingEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: UserResponse(
                createdAt: Date(),
                custom: [:],
                id: secondUser.userId,
                language: "",
                role: "user",
                teams: [],
                updatedAt: Date()
            )
        )

        let wrapped = WrappedEvent.coordinatorEvent(.typeCallRingEvent(event))
        eventNotificationCenter?.process(wrapped)
        
        // Then
        try await waitForCallEvent()
        guard case let .incoming(call) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(call.id == callId)
        
        // When
        callViewModel.acceptCall(callType: callType, callId: callId)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall, nanoseconds: 2_000_000_000)
    }
    
    func test_incomingCall_rejectCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        try await waitForCallEvent()
        let event = CallRingEvent(
            call: mockResponseBuilder.makeCallResponse(
                cid: callCid,
                rejectedBy: [firstUser.userId: Date()]
            ),
            callCid: callCid,
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: UserResponse(
                createdAt: Date(),
                custom: [:],
                id: secondUser.userId,
                language: "en",
                role: "user",
                teams: [],
                updatedAt: Date()
            )
        )
        eventNotificationCenter?.process(.coordinatorEvent(.typeCallRingEvent(event)))
        
        // Then
        try await waitForCallEvent()
        guard case let .incoming(call) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(call.id == callId)
        
        // When
        callViewModel.rejectCall(callType: callType, callId: callId)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle, nanoseconds: 2_000_000_000)
    }
    
    func test_joinCall_success() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.joinCall(callType: callType, callId: callId)
        
        // Then
        XCTAssert(callViewModel.callingState == .joining)
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
    }
    
    func test_enterLobby_joinCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.enterLobby(callType: callType, callId: callId, members: participants)
        
        // Then
        guard case let .lobby(lobbyInfo) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(lobbyInfo.callId == callId)
        XCTAssert(lobbyInfo.callType == callType)
        XCTAssert(lobbyInfo.participants == participants)
        
        // When
        try await waitForCallEvent()
        callViewModel.joinCall(
            callType: callType,
            callId: callId
        )
        try await waitForCallEvent()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
    }
    
    func test_enterLobby_leaveCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.enterLobby(callType: callType, callId: callId, members: participants)
        
        // Then
        guard case let .lobby(lobbyInfo) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(lobbyInfo.callId == callId)
        XCTAssert(lobbyInfo.callType == callType)
        XCTAssert(lobbyInfo.participants == participants)
        
        // When
        try await waitForCallEvent()
        callViewModel.hangUp()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    // MARK: - Toggle media state
    
    func test_callSettings_toggleCamera() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()
        callViewModel.toggleCameraEnabled()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.videoOn == false)
    }
    
    func test_callSettings_toggleAudio() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()
        callViewModel.toggleMicrophoneEnabled()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.audioOn == false)
    }
    
    func test_callSettings_toggleCameraPosition() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()
        callViewModel.toggleCameraPosition()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.cameraPosition == .back)
    }
    
    // MARK: - Events
    
    func test_inCall_participantEvents() async throws {
        // Given
        let callViewModel = CallViewModel()

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()
        let participantEvent = CallSessionParticipantJoinedEvent(
            callCid: callCid,
            createdAt: Date(),
            participant: CallParticipantResponse(
                joinedAt: Date(),
                role: "user",
                user: mockResponseBuilder.makeUserResponse(),
                userSessionId: "123"
            ),
            sessionId: "123"
        )

        eventNotificationCenter?.process(.coordinatorEvent(.typeCallSessionParticipantJoinedEvent(participantEvent)))
        try await waitForCallEvent()

        // Then
        try await XCTAssertWithDelay(callViewModel.participantEvent != nil)
        try await Task.sleep(nanoseconds: 2_500_000_000)
        try await XCTAssertWithDelay(callViewModel.participantEvent == nil)
    }
    
    func test_inCall_participantJoinedAndLeft() async throws {
        // Given
        let callViewModel = CallViewModel()

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = callCid
        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = callViewModel.call!.callController as! CallController_Mock
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))

        // Then
        try await XCTAssertWithDelay(callViewModel.participants.map(\.userId).contains(secondUser.userId))

        // When
        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
        participantLeft.callCid = callCid
        participantLeft.participant = participant
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantLeft(participantLeft)))

        // Then
        try await XCTAssertWithDelay(callViewModel.participants.count == 0)
    }
    
    func test_inCall_changeTrackVisibility() async throws {
        // Given
        let callViewModel = CallViewModel()

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = callCid

        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = try XCTUnwrap(callViewModel.call?.callController as? CallController_Mock)
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))

        let callParticipant = participant.toCallParticipant(showTrack: false)
        callViewModel.changeTrackVisibility(for: callParticipant, isVisible: true)

        // Then
        try await XCTAssertWithDelay(callViewModel.participants.first?.showTrack == true)
    }
    
    func test_pinParticipant_manualLayoutChange() async throws {
        // Given
        let callViewModel = CallViewModel()

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        try await waitForCallEvent()

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = callCid

        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = callViewModel.call!.callController as! CallController_Mock
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        callViewModel.update(participantsLayout: .fullScreen)

        // Then
        XCTAssert(callViewModel.participantsLayout == .fullScreen)
    }
    
    // MARK: - Participants

    func test_participants_layoutIsGrid_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(callParticipantsCount: 2, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 1),
            .init(callParticipantsCount: 2, participantsLayout: .grid, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 1),
            .init(callParticipantsCount: 2, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 1),

            .init(callParticipantsCount: 3, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 3, participantsLayout: .grid, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 3, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 2),

            .init(callParticipantsCount: 4, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .grid, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .grid, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 4),
        ])
    }

    func test_participants_layoutIsSpotlight_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(callParticipantsCount: 2, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 2, participantsLayout: .spotlight, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 2, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 2),

            .init(callParticipantsCount: 3, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 3),
            .init(callParticipantsCount: 3, participantsLayout: .spotlight, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 3),
            .init(callParticipantsCount: 3, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 3),

            .init(callParticipantsCount: 4, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .spotlight, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .spotlight, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 4),
        ])
    }

    func test_participants_layoutIsFullscreen_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(callParticipantsCount: 2, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 2, participantsLayout: .fullScreen, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 2),
            .init(callParticipantsCount: 2, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 2),

            .init(callParticipantsCount: 3, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 3),
            .init(callParticipantsCount: 3, participantsLayout: .fullScreen, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 3),
            .init(callParticipantsCount: 3, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 3),

            .init(callParticipantsCount: 4, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .fullScreen, isLocalScreenSharing: true, isRemoteScreenSharing: false, expectedCount: 4),
            .init(callParticipantsCount: 4, participantsLayout: .fullScreen, isLocalScreenSharing: false, isRemoteScreenSharing: true, expectedCount: 4),
        ])
    }

    private struct ParticipantsScenario {
        var callParticipantsCount: Int
        var participantsLayout: ParticipantsLayout
        var isLocalScreenSharing: Bool
        var isRemoteScreenSharing: Bool
        var expectedCount: Int
    }

    private func assertParticipantScenarios(
        _ scenarios: [ParticipantsScenario],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        for scenario in scenarios {
            try await assertParticipants(
                callParticipantsCount: scenario.callParticipantsCount,
                participantsLayout: scenario.participantsLayout,
                isLocalScreenSharing:scenario.isLocalScreenSharing,
                isRemoteScreenSharing: scenario.isRemoteScreenSharing,
                expectedCount: scenario.expectedCount,
                file: file,
                line: line
            )
        }
    }

    private func assertParticipants(
        callParticipantsCount: Int,
        participantsLayout: ParticipantsLayout,
        isLocalScreenSharing: Bool,
        isRemoteScreenSharing: Bool,
        expectedCount: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        // Setup call
        let callViewModel = CallViewModel()
        callViewModel.startCall(callType: .default, callId: callId, members: [])
        try await waitForCallEvent()
        let call = try XCTUnwrap(callViewModel.call, file: file, line: line)

        let localParticipant = CallParticipant.dummy(
            id: call.state.sessionId,
            isScreenSharing: isLocalScreenSharing
        )

        let remoteCallParticipants = (0..<(callParticipantsCount - 1))
            .map { CallParticipant.dummy(id: "test-participant-\($0)") }

        if isLocalScreenSharing {
            callViewModel.call?.state.screenSharingSession = .init(
                track: nil,
                participant: localParticipant
            )
        } else if isRemoteScreenSharing, let firstRemoteCallParticipant = remoteCallParticipants.first {
            callViewModel.call?.state.screenSharingSession = .init(
                track: nil,
                participant: firstRemoteCallParticipant
            )
        }

        callViewModel.update(participantsLayout: participantsLayout)
        callViewModel.call?.state.participantsMap = ([localParticipant] + remoteCallParticipants)
            .reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }

        XCTAssertEqual(callViewModel.participants.count, expectedCount, file: file, line: line)
    }

    //MARK: - private
    
    private func callViewModelWithRingingCall(participants: [Member]) -> CallViewModel {
        let callViewModel = CallViewModel()
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callData = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        call?.state.update(from: callData)
        callViewModel.setActiveCall(call)
        callViewModel.outgoingCallMembers = participants
        callViewModel.callingState = .outgoing
        return callViewModel
    }
    
}

extension User {
    func toUserResponse() -> UserResponse {
        UserResponse(
            createdAt: Date(),
            custom: customData,
            id: id,
            image: imageURL?.absoluteString,
            language: "en",
            name: name,
            role: role,
            teams: [],
            updatedAt: Date()
        )
    }
}

extension Member {
    var userId: String { id }
}
