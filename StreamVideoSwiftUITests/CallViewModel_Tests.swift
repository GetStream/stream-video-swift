//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class CallViewModel_Tests: StreamVideoTestCase {
    
    private lazy var mockResponseBuilder: MockResponseBuilder! = MockResponseBuilder()
    private lazy var firstUser: Member! = Member(user: StreamVideo.mockUser, updatedAt: .now)
    private lazy var secondUser: Member! = Member(user: User(id: "test2"), updatedAt: .now)
    private lazy var thirdUser: Member! = Member(user: User(id: "test3"), updatedAt: .now)
    private lazy var callType: String! = .default
    private lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    private lazy var callId: String! = UUID().uuidString
    private lazy var participants: [Member]! = [firstUser, secondUser]

    private var cId: String { callCid(from: callId, callType: callType) }

    // MARK: - Call Events

    override func tearDown() {
        participants = nil
        callId = nil
        eventNotificationCenter = nil
        callType = nil
        thirdUser = nil
        secondUser = nil
        firstUser = nil
        mockResponseBuilder = nil
        super.tearDown()
    }

    @MainActor
    func test_startCall_joiningState() {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .joining)
    }
    
    @MainActor
    func test_startCall_outgoingState() {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants, ring: true)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .outgoing)
    }
    
    @MainActor
    func test_outgoingCall_rejectedEvent() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(
            .coordinatorEvent(
                .typeCallRejectedEvent(.dummy(
                    call: .dummy(
                        cid: cId,
                        session: .dummy(
                            rejectedBy: [secondUser.userId: Date()]
                        )
                    ),
                    callCid: cId,
                    createdAt: Date(),
                    user: secondUser.user.toUserResponse()
                ))
            )
        )
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_outgoingCall_rejectedEventThreeParticipants() async throws {
        // Given
        let threeParticipants: [Member] = participants + [thirdUser]
        let callViewModel = callViewModelWithRingingCall(participants: threeParticipants)
        await fulfillment { callViewModel.isSubscribedToCallEvents }
        
        // When
        let firstCallResponse = mockResponseBuilder.makeCallResponse(
            cid: cId,
            rejectedBy: [secondUser.userId: Date()]
        )
        let firstReject = CallRejectedEvent(
            call: firstCallResponse,
            callCid: cId,
            createdAt: Date(),
            user: User(id: secondUser.userId).toUserResponse()
        )
        let first = WrappedEvent.coordinatorEvent(.typeCallRejectedEvent(firstReject))
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(first)
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.outgoing actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .outgoing
        }

        // When
        let secondCallResponse = mockResponseBuilder.makeCallResponse(
            cid: cId,
            rejectedBy: [secondUser.userId: Date(), thirdUser.userId: Date()]
        )
        let secondReject = CallRejectedEvent(
            call: secondCallResponse,
            callCid: cId,
            createdAt: Date(),
            user: User(id: thirdUser.userId).toUserResponse()
        )
        let second = WrappedEvent.coordinatorEvent(.typeCallRejectedEvent(secondReject))
        eventNotificationCenter.process(second)

        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_outgoingCall_callEndedEvent() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        await fulfillment { callViewModel.isSubscribedToCallEvents }
        
        // When
        let event = CallEndedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: cId),
            callCid: cId,
            createdAt: Date()
        )
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(.coordinatorEvent(.typeCallEndedEvent(event)))
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_outgoingCall_blockEventCurrentUser() async throws {
        // Given
        let callViewModel = callViewModelWithRingingCall(participants: participants)
        await fulfillment { callViewModel.isSubscribedToCallEvents }
        
        // When
        let event = BlockedUserEvent(
            callCid: cId,
            createdAt: Date(),
            user: User(id: firstUser.userId).toUserResponse()
        )
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(.coordinatorEvent(.typeBlockedUserEvent(event)))
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_outgoingCall_blockEventOtherUser() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        let call = streamVideo?.call(callType: callType, callId: callId)
        let callData = mockResponseBuilder.makeCallResponse(
            cid: cId
        )
        call?.state.update(from: callData)
        callViewModel.setActiveCall(call)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        // When
        let event = BlockedUserEvent(
            callCid: cId,
            createdAt: Date(),
            user: User(id: secondUser.userId).toUserResponse()
        )
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(.coordinatorEvent(.typeBlockedUserEvent(event)))
        
        // Then
        await fulfillment { callViewModel.call?.state.blockedUserIds.first == self.secondUser.userId }
    }
    
    @MainActor
    func test_outgoingCall_hangUp() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        callViewModel.hangUp()
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_incomingCall_acceptCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        let acceptResponse = AcceptCallResponse(duration: "1.0")
        let data = try JSONEncoder.default.encode(acceptResponse)
        httpClient.dataResponses = [data]

        // When
        let event = CallRingEvent(
            call: mockResponseBuilder.makeCallResponse(cid: cId),
            callCid: cId,
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: UserResponse(
                banned: false,
                blockedUserIds: [],
                createdAt: Date(),
                custom: [:],
                id: secondUser.userId,
                language: "",
                role: "user",
                teams: [],
                updatedAt: Date()
            ),
            video: true
        )

        let wrapped = WrappedEvent.coordinatorEvent(.typeCallRingEvent(event))
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(wrapped)
        
        await fulfillment {
            if case .incoming = callViewModel.callingState {
                return true
            } else {
                return false
            }
        }

        // Then
        guard case let .incoming(call) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(call.id == callId)
        
        // When
        callViewModel.acceptCall(callType: callType, callId: callId)
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }
    }
    
    @MainActor
    func test_incomingCall_rejectCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        let event = CallRingEvent(
            call: mockResponseBuilder.makeCallResponse(
                cid: cId,
                rejectedBy: [firstUser.userId: Date()]
            ),
            callCid: cId,
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: UserResponse(
                banned: false,
                blockedUserIds: [],
                createdAt: Date(),
                custom: [:],
                id: secondUser.userId,
                language: "en",
                role: "user",
                teams: [],
                updatedAt: Date()
            ),
            video: true
        )
        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(.coordinatorEvent(.typeCallRingEvent(event)))
        
        await fulfillment {
            if case .incoming = callViewModel.callingState {
                return true
            } else {
                return false
            }
        }

        // Then
        guard case let .incoming(call) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(call.id == callId)
        
        // When
        callViewModel.rejectCall(callType: callType, callId: callId)
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    @MainActor
    func test_joinCall_success() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.joinCall(callType: callType, callId: callId)
        
        // Then
        XCTAssert(callViewModel.callingState == .joining)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }
    }
    
    @MainActor
    func test_enterLobby_joinCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.enterLobby(
            callType: callType,
            callId: callId,
            members: participants
        )
        await fulfillment {
            if case .lobby = callViewModel.callingState {
                return true
            } else {
                return false
            }
        }

        // Then
        guard case let .lobby(lobbyInfo) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(lobbyInfo.callId == callId)
        XCTAssert(lobbyInfo.callType == callType)
        XCTAssert(lobbyInfo.participants == participants)

        // When
        callViewModel.joinCall(
            callType: callType,
            callId: callId
        )
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }
    }
    
    @MainActor
    func test_enterLobby_leaveCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.enterLobby(
            callType: callType,
            callId: callId,
            members: participants
        )
        await fulfillment {
            if case .lobby = callViewModel.callingState {
                return true
            } else {
                return false
            }
        }

        // Then
        guard case let .lobby(lobbyInfo) = callViewModel.callingState else {
            XCTFail()
            return
        }
        XCTAssert(lobbyInfo.callId == callId)
        XCTAssert(lobbyInfo.callType == callType)
        XCTAssert(lobbyInfo.participants == participants)
        
        // When

        callViewModel.hangUp()
        
        // Then
        await fulfillment("CallViewModel.callingState expected:.idle actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .idle
        }
    }
    
    // MARK: - Toggle media state
    
    @MainActor
    func test_callSettings_toggleCamera() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        callViewModel.toggleCameraEnabled()
        
        // Then
        await fulfillment { callViewModel.callSettings.videoOn == false }
    }
    
    @MainActor
    func test_callSettings_toggleAudio() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        callViewModel.toggleMicrophoneEnabled()
        
        // Then
        await fulfillment { callViewModel.callSettings.videoOn == false }
    }
    
    @MainActor
    func test_callSettings_toggleCameraPosition() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        callViewModel.toggleCameraPosition()
        
        // Then
        await fulfillment { callViewModel.callSettings.cameraPosition == .back }
    }
    
    // MARK: - Events
    
    @MainActor
    func test_inCall_participantEvents() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        let participantEvent = CallSessionParticipantJoinedEvent(
            callCid: cId,
            createdAt: Date(),
            participant: CallParticipantResponse(
                joinedAt: Date(),
                role: "user",
                user: mockResponseBuilder.makeUserResponse(),
                userSessionId: "123"
            ),
            sessionId: "123"
        )

        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
        eventNotificationCenter.process(.coordinatorEvent(.typeCallSessionParticipantJoinedEvent(participantEvent)))

        // Then
        await fulfillment { callViewModel.participantEvent != nil }
        await fulfillment { callViewModel.participantEvent == nil }
    }
    
    @MainActor
    func test_inCall_participantJoinedAndLeft() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment { callViewModel.callingState == .inCall }

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = cId
        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = try XCTUnwrap(callViewModel.call?.callController as? CallController_Mock)
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))

        // Then
        await fulfillment {
            callViewModel
                .participants
                .map(\.userId)
                .contains(self.secondUser.userId)
        }

        // When
        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
        participantLeft.callCid = cId
        participantLeft.participant = participant
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantLeft(participantLeft)))

        // Then
        await fulfillment { callViewModel.participants.isEmpty }
    }
    
    @MainActor
    func test_inCall_changeTrackVisibility() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = cId

        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = try XCTUnwrap(callViewModel.call?.callController as? CallController_Mock)
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))

        let callParticipant = participant.toCallParticipant(showTrack: false)
        callViewModel.changeTrackVisibility(for: callParticipant, isVisible: true)

        // Then
        await fulfillment { callViewModel.participants.first?.showTrack == true }
    }
    
    @MainActor
    func test_pinParticipant_manualLayoutChange() async throws {
        // Given
        let callViewModel = CallViewModel()
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        // When
        callViewModel.startCall(callType: .default, callId: callId, members: participants)
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }

        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
        participantJoined.callCid = cId

        var participant = Stream_Video_Sfu_Models_Participant()
        participant.userID = secondUser.userId
        participant.sessionID = UUID().uuidString
        participantJoined.participant = participant

        let controller = try XCTUnwrap(callViewModel.call?.callController as? CallController_Mock)
        controller.webRTCClient.eventNotificationCenter.process(.sfuEvent(.participantJoined(participantJoined)))
        callViewModel.update(participantsLayout: .fullScreen)

        // Then
        XCTAssert(callViewModel.participantsLayout == .fullScreen)
    }
    
    // MARK: - Participants

    @MainActor
    func test_participants_layoutIsGrid_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(
                callParticipantsCount: 2,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 1
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .grid,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 1
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 1
            ),
            
            .init(
                callParticipantsCount: 3,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .grid,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 2
            ),
            
            .init(
                callParticipantsCount: 4,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .grid,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .grid,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 4
            )
        ])
    }

    @MainActor
    func test_participants_layoutIsSpotlight_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(
                callParticipantsCount: 2,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .spotlight,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 2
            ),
            
            .init(
                callParticipantsCount: 3,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 3
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .spotlight,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 3
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 3
            ),
            
            .init(
                callParticipantsCount: 4,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .spotlight,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .spotlight,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 4
            )
        ])
    }

    @MainActor
    func test_participants_layoutIsFullscreen_validateAllVariants() async throws {
        try await assertParticipantScenarios([
            .init(
                callParticipantsCount: 2,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 2
            ),
            .init(
                callParticipantsCount: 2,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 2
            ),
            
            .init(
                callParticipantsCount: 3,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 3
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 3
            ),
            .init(
                callParticipantsCount: 3,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 3
            ),
            
            .init(
                callParticipantsCount: 4,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: true,
                isRemoteScreenSharing: false,
                expectedCount: 4
            ),
            .init(
                callParticipantsCount: 4,
                participantsLayout: .fullScreen,
                isLocalScreenSharing: false,
                isRemoteScreenSharing: true,
                expectedCount: 4
            )
        ])
    }

    private struct ParticipantsScenario {
        var callParticipantsCount: Int
        var participantsLayout: ParticipantsLayout
        var isLocalScreenSharing: Bool
        var isRemoteScreenSharing: Bool
        var expectedCount: Int
    }

    @MainActor
    private func assertParticipantScenarios(
        _ scenarios: [ParticipantsScenario],
        file: StaticString = #file,
        line: UInt = #line
    ) async throws {
        for scenario in scenarios {
            try await assertParticipants(
                callParticipantsCount: scenario.callParticipantsCount,
                participantsLayout: scenario.participantsLayout,
                isLocalScreenSharing: scenario.isLocalScreenSharing,
                isRemoteScreenSharing: scenario.isRemoteScreenSharing,
                expectedCount: scenario.expectedCount,
                file: file,
                line: line
            )
        }
    }

    @MainActor
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
        await fulfillment { callViewModel.isSubscribedToCallEvents }

        callViewModel.startCall(callType: .default, callId: callId, members: [])
        await fulfillment("CallViewModel.callingState expected:.inCall actual: \(callViewModel.callingState)") {
            callViewModel.callingState == .inCall
        }
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

    // MARK: - private
    
    @MainActor
    private func callViewModelWithRingingCall(participants: [Member]) -> CallViewModel {
        let callViewModel = CallViewModel()
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callData = mockResponseBuilder.makeCallResponse(
            cid: cId
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
            banned: false,
            blockedUserIds: [],
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
