//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class CallViewModel_Tests: StreamVideoTestCase {
    
    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    
    private let mockResponseBuilder = MockResponseBuilder()
    
    let firstUser: MemberRequest = Member(user: StreamVideo.mockUser, updatedAt: .now).toMemberRequest
    let secondUser: MemberRequest = Member(user: User(id: "test2"), updatedAt: .now).toMemberRequest
    let thirdUser: MemberRequest = Member(user: User(id: "test3"), updatedAt: .now).toMemberRequest
    let callId = "test"
    let callType: String = .default
    var callCid: String {
        "\(callType):\(callId)"
    }
    
    lazy var participants = [firstUser, secondUser]
    
    override func setUp() {
        super.setUp()
        LogConfig.level = .debug
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
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
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
        eventNotificationCenter?.process(firstReject)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .outgoing)
        
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
        eventNotificationCenter?.process(secondReject)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_callEndedEvent() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        try await waitForCallEvent()
        
        // When
        let event = CallEndedEvent(callCid: callCid, createdAt: Date())
        eventNotificationCenter?.process(event)
        
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
        eventNotificationCenter?.process(event)
        
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
        eventNotificationCenter?.process(event)
        
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
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_incomingCall_acceptCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        let acceptResponse = AcceptCallResponse(duration: "1.0")
        let data = try JSONEncoder.default.encode(acceptResponse)
        (httpClient as? HTTPClient_Mock)?.dataResponses = [data]
        
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
                role: "user",
                teams: [],
                updatedAt: Date()
            )
        )
        eventNotificationCenter?.process(event)
        
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
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
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
                role: "user",
                teams: [],
                updatedAt: Date()
            )
        )
        eventNotificationCenter?.process(event)
        
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
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
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
        // Video is not available in simulator, so it stays in front.
        try await XCTAssertWithDelay(callViewModel.callSettings.cameraPosition == .front)
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
            sessionId: "123",
            user: .make(from: "test")
        )
        eventNotificationCenter?.process(participantEvent)
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
        controller.webRTCClient.eventNotificationCenter.process(participantJoined)

        // Then
        try await XCTAssertWithDelay(callViewModel.participants.map(\.userId).contains(secondUser.userId))

        // When
        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
        participantLeft.callCid = callCid
        participantLeft.participant = participant
        controller.webRTCClient.eventNotificationCenter.process(participantLeft)

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
        let controller = callViewModel.call!.callController as! CallController_Mock
        controller.webRTCClient.eventNotificationCenter.process(participantJoined)
        let callParticipant = participant.toCallParticipant(showTrack: false)
        callViewModel.changeTrackVisbility(for: callParticipant, isVisible: true)

        // Then
        try await XCTAssertWithDelay(callViewModel.participants.first?.showTrack == true)
    }
    
    func test_pinParticipant_layoutChange() async throws {
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
        controller.webRTCClient.eventNotificationCenter.process(participantJoined)
        let callParticipant = participant.toCallParticipant(showTrack: false)
        callViewModel.pinnedParticipant = callParticipant

        // Then
        XCTAssert(callViewModel.participantsLayout == .spotlight)
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
        controller.webRTCClient.eventNotificationCenter.process(participantJoined)
        callViewModel.update(participantsLayout: .fullScreen)
        let callParticipant = participant.toCallParticipant(showTrack: false)
        callViewModel.pinnedParticipant = callParticipant

        // Then
        XCTAssert(callViewModel.participantsLayout == .fullScreen)
    }
    
    //MARK: - private
    
    private func callViewModelWithRingingCall(participants: [MemberRequest]) -> CallViewModel {
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
            name: name,
            role: role,
            teams: [],
            updatedAt: Date()
        )
    }
}
