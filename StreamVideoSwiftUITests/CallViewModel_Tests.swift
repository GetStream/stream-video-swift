//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class CallViewModel_Tests: XCTestCase, @unchecked Sendable {

    private lazy var mockResponseBuilder: MockResponseBuilder! = MockResponseBuilder()
    private lazy var firstUser: Member! = Member(user: StreamVideo.mockUser, updatedAt: .now)
    private lazy var secondUser: Member! = Member(user: User(id: "test2"), updatedAt: .now)
    private lazy var thirdUser: Member! = Member(user: User(id: "test3"), updatedAt: .now)
    private lazy var callType: String! = .default
    private lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    private lazy var callId: String! = UUID().uuidString
    private lazy var participants: [Member]! = [firstUser, secondUser]
    private var streamVideo: MockStreamVideo!
    private lazy var mockCall: MockCall! = .init(.dummy(callType: callType, callId: callId))

    private var subject: CallViewModel!

    private var cId: String { callCid(from: callId, callType: callType) }

    override func tearDown() async throws {
        subject = nil
        participants = nil
        callId = nil
        eventNotificationCenter = nil
        callType = nil
        thirdUser = nil
        secondUser = nil
        firstUser = nil
        mockResponseBuilder = nil
        try await super.tearDown()
    }

    // MARK: - Call Events

    func test_startCall_joiningState() async {
        // Given
        await prepare()

        // When
        subject.startCall(callType: .default, callId: callId, members: participants)

        // Then
        XCTAssertEqual(subject.outgoingCallMembers, participants)
        XCTAssertEqual(subject.callingState, .joining)
    }

    func test_startCall_outgoingState() async {
        // Given
        await prepare()

        // When
        subject.startCall(callType: .default, callId: callId, members: participants, ring: true)

        // Then
        XCTAssertEqual(subject.outgoingCallMembers, participants)
        XCTAssertEqual(subject.callingState, .outgoing)
    }

    // MARK: - Outgoing

    func test_outgoingCall_rejectedEvent() async throws {
        // Given
        await prepare()
        subject.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        streamVideo.process(
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
        await assertCallingState(.idle)
    }

    func test_outgoingCall_rejectedEventThreeParticipants() async throws {
        // Given
        await prepare()
        let threeParticipants: [Member] = participants + [thirdUser]
        subject.startCall(
            callType: .default,
            callId: callId,
            members: threeParticipants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        streamVideo.process(
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
        await wait(for: 1.0)
        await assertCallingState(.outgoing)
        streamVideo.process(
            .coordinatorEvent(
                .typeCallRejectedEvent(.dummy(
                    call: .dummy(
                        cid: cId,
                        session: .dummy(
                            rejectedBy: [thirdUser.userId: Date()]
                        )
                    ),
                    callCid: cId,
                    createdAt: Date(),
                    user: secondUser.user.toUserResponse()
                ))
            )
        )

        // Then
        await assertCallingState(.idle)
    }

    func test_outgoingCall_callEndedEvent() async throws {
        // Given
        await prepare()
        subject.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallEndedEvent(
                    .init(
                        call: .dummy(cid: cId),
                        callCid: cId,
                        createdAt: .init(),
                        user: .dummy()
                    )
                )
            )
        )

        // Then
        await assertCallingState(.idle)
    }

    func test_outgoingCall_blockEventCurrentUser() async throws {
        // Given
        await prepare()
        subject.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeBlockedUserEvent(
                    .init(
                        callCid: cId,
                        createdAt: .init(),
                        user: .dummy(id: firstUser.userId)
                    )
                )
            )
        )

        // Then
        await assertCallingState(.idle)
    }

    func test_outgoingCall_blockEventOtherUser() async throws {
        // Given
        await prepare()
        subject.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeBlockedUserEvent(
                    .init(
                        callCid: cId,
                        createdAt: .init(),
                        user: .dummy(id: secondUser.userId)
                    )
                )
            )
        )

        // Then
        await assertCallingState(.outgoing, delay: 1)
    }

    func test_outgoingCall_hangUp() async throws {
        // Given
        await prepare()
        subject.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )
        await assertCallingState(.outgoing)

        // When
        subject.hangUp()

        // Then
        await assertCallingState(.idle)
    }

    // MARK: - Incoming

    func test_incomingCall_acceptCall() async throws {
        // Given
        await prepareIncomingCallScenario()

        // When
        subject.acceptCall(callType: callType, callId: callId)

        // Then
        await assertCallingState(.inCall)
    }

    func test_incomingCall_acceptedFromSameUserElsewhere_callingStateChangesToIdle() async throws {
        // Given
        await prepareIncomingCallScenario()

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallAcceptedEvent(
                    .dummy(
                        callCid: cId,
                        user: firstUser.user.toUserResponse()
                    )
                )
            )
        )

        // Then
        await assertCallingState(.idle)
    }

    func test_incomingCall_sameUserAcceptedAnotherCall_callingStateShouldRemainIncoming() async throws {
        // Given
        await prepareIncomingCallScenario()
        let callingState = subject.callingState

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallAcceptedEvent(
                    .dummy(
                        callCid: "\(callType):\(String.unique)",
                        user: firstUser.user.toUserResponse()
                    )
                )
            )
        )

        // Then
        await assertCallingState(callingState, delay: 1)
    }

    func test_incomingCall_anotherUserAcceptedThisCall_callingStateShouldRemainIncoming() async throws {
        // Given
        await prepareIncomingCallScenario()
        let callingState = subject.callingState

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallAcceptedEvent(
                    .dummy(
                        callCid: cId,
                        user: Member(userId: .unique).user.toUserResponse()
                    )
                )
            )
        )

        // Then
        await assertCallingState(callingState, delay: 1)
    }

    func test_incomingCall_acceptedAnotherCallElsewhere_callingStateShouldRemainInCall() async throws {
        // Given
        await prepareIncomingCallScenario()
        let callingState = subject.callingState

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallAcceptedEvent(
                    .dummy(
                        callCid: "\(callType):\(String.unique)",
                        user: Member(userId: .unique).user.toUserResponse()
                    )
                )
            )
        )

        // Then
        await assertCallingState(callingState, delay: 1)
    }

    func test_incomingCall_rejectCall() async throws {
        // Given
        await prepareIncomingCallScenario()
        mockCall.stub(for: .reject, with: RejectCallResponse(duration: "0"))

        // When
        subject.rejectCall(callType: callType, callId: callId)

        // Then
        await assertCallingState(.idle)
    }
    
    // MARK: - Join

    func test_joinCall_success() async throws {
        // Given
        await prepare()

        // When
        subject.joinCall(callType: callType, callId: callId)

        // Then
        await assertCallingState(.inCall)
    }

    // MARK: - EnterLobby

    func test_enterLobby_joinCall() async throws {
        // Given
        await prepare()

        // When
        subject.enterLobby(
            callType: callType,
            callId: callId,
            members: participants
        )
        await assertCallingState(
            .lobby(
                .init(
                    callId: callId,
                    callType: callType,
                    participants: participants
                )
            )
        )
        subject.joinCall(callType: callType, callId: callId)

        // Then
        await assertCallingState(.inCall)
    }

    func test_enterLobby_leaveCall() async throws {
        // Given
        await prepare()

        // When
        subject.enterLobby(
            callType: callType,
            callId: callId,
            members: participants
        )
        await assertCallingState(
            .lobby(
                .init(
                    callId: callId,
                    callType: callType,
                    participants: participants
                )
            )
        )
        subject.hangUp()

        // Then
        await assertCallingState(.idle)
    }
    
    // MARK: - Toggle media state

    func test_callSettings_toggleCamera() async throws {
        // Given
        await prepareMediaScenario()
        XCTAssertTrue(subject.callSettings.videoOn)

        // When
        subject.toggleCameraEnabled()

        // Then
        await fulfilmentInMainActor { self.subject.callSettings.videoOn == false }
    }

    func test_callSettings_toggleAudio() async throws {
        // Given
        await prepareMediaScenario()
        XCTAssertTrue(subject.callSettings.audioOn)

        // When
        subject.toggleMicrophoneEnabled()

        // Then
        await fulfilmentInMainActor { self.subject.callSettings.audioOn == false }
    }

    func test_callSettings_toggleCameraPosition() async throws {
        // Given
        await prepareMediaScenario()
        XCTAssertEqual(subject.callSettings.cameraPosition, .front)

        // When
        subject.toggleCameraPosition()

        // Then
        await fulfilmentInMainActor { self.subject.callSettings.cameraPosition == .back }
    }
    
    // MARK: - Events
    
//    @MainActor
//    func test_inCall_participantEvents() async throws {
//        // Given
//        let callViewModel = CallViewModel()
//        await fulfilmentInMainActor { callViewModel.isSubscribedToCallEvents }
//
//        // When
//        callViewModel.startCall(callType: .default, callId: callId, members: participants)
//        nonisolated(unsafe) let callingState = callViewModel.callingState
//        await fulfilmentInMainActor("CallViewModel.callingState expected:.inCall actual: \(callingState)") {
//            callViewModel.callingState == .inCall
//        }
//
//        let participantEvent = CallSessionParticipantJoinedEvent(
//            callCid: cId,
//            createdAt: Date(),
//            participant: CallParticipantResponse(
//                joinedAt: Date(),
//                role: "user",
//                user: mockResponseBuilder.makeUserResponse(),
//                userSessionId: "123"
//            ),
//            sessionId: "123"
//        )
//
//        let eventNotificationCenter = try XCTUnwrap(eventNotificationCenter)
//        eventNotificationCenter.process(.coordinatorEvent(.typeCallSessionParticipantJoinedEvent(participantEvent)))
//
//        // Then
//        await fulfilmentInMainActor { callViewModel.participantEvent != nil }
//        await fulfilmentInMainActor { callViewModel.participantEvent == nil }
//    }
//
//    @MainActor
//    func test_inCall_participantJoinedAndLeft() async throws {
//        throw XCTSkip()
//        // Given
//        let callViewModel = CallViewModel()
//        await fulfilmentInMainActor { callViewModel.isSubscribedToCallEvents }
//
//        // When
//        callViewModel.startCall(callType: .default, callId: callId, members: participants)
//        await fulfilmentInMainActor { callViewModel.callingState == .inCall }
//
//        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
//        participantJoined.callCid = cId
//        var participant = Stream_Video_Sfu_Models_Participant()
//        participant.userID = secondUser.userId
//        participant.sessionID = UUID().uuidString
//        participantJoined.participant = participant
//
//        // Then
//        await fulfilmentInMainActor {
//            callViewModel
//                .participants
//                .map(\.userId)
//                .contains(self.secondUser.userId)
//        }
//
//        // When
//        var participantLeft = Stream_Video_Sfu_Event_ParticipantLeft()
//        participantLeft.callCid = cId
//        participantLeft.participant = participant
//
//        // Then
//        await fulfilmentInMainActor { callViewModel.participants.isEmpty }
//    }
//
//    @MainActor
//    func test_inCall_changeTrackVisibility() async throws {
//        throw XCTSkip()
//        // Given
//        let callViewModel = CallViewModel()
//        await fulfilmentInMainActor { callViewModel.isSubscribedToCallEvents }
//
//        // When
//        callViewModel.startCall(callType: .default, callId: callId, members: participants)
//        nonisolated(unsafe) let callingState = callViewModel.callingState
//        await fulfilmentInMainActor("CallViewModel.callingState expected:.inCall actual: \(callingState)") {
//            callViewModel.callingState == .inCall
//        }
//
//        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
//        participantJoined.callCid = cId
//
//        var participant = Stream_Video_Sfu_Models_Participant()
//        participant.userID = secondUser.userId
//        participant.sessionID = UUID().uuidString
//        participantJoined.participant = participant
//
//        let callParticipant = participant.toCallParticipant(showTrack: false)
//        callViewModel.changeTrackVisibility(for: callParticipant, isVisible: true)
//
//        // Then
//        await fulfilmentInMainActor { callViewModel.participants.first?.showTrack == true }
//    }
//
//    @MainActor
//    func test_pinParticipant_manualLayoutChange() async throws {
//        throw XCTSkip()
//        // Given
//        let callViewModel = CallViewModel()
//        await fulfilmentInMainActor { callViewModel.isSubscribedToCallEvents }
//
//        // When
//        callViewModel.startCall(callType: .default, callId: callId, members: participants)
//        nonisolated(unsafe) let callingState = callViewModel.callingState
//        await fulfilmentInMainActor("CallViewModel.callingState expected:.inCall actual: \(callingState)") {
//            callViewModel.callingState == .inCall
//        }
//
//        var participantJoined = Stream_Video_Sfu_Event_ParticipantJoined()
//        participantJoined.callCid = cId
//
//        var participant = Stream_Video_Sfu_Models_Participant()
//        participant.userID = secondUser.userId
//        participant.sessionID = UUID().uuidString
//        participantJoined.participant = participant
//
//        callViewModel.update(participantsLayout: .fullScreen)
//
//        // Then
//        XCTAssert(callViewModel.participantsLayout == .fullScreen)
//    }
    
    // MARK: - Participants

//    @MainActor
//    func test_participants_layoutIsGrid_validateAllVariants() async throws {
//        try await assertParticipantScenarios([
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 1
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .grid,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 1
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 1
//            ),
//
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .grid,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 2
//            ),
//
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .grid,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .grid,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 4
//            )
//        ])
//    }
//
//    @MainActor
//    func test_participants_layoutIsSpotlight_validateAllVariants() async throws {
//        try await assertParticipantScenarios([
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 2
//            ),
//
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 3
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 3
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 3
//            ),
//
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .spotlight,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 4
//            )
//        ])
//    }
//
//    @MainActor
//    func test_participants_layoutIsFullscreen_validateAllVariants() async throws {
//        try await assertParticipantScenarios([
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 2
//            ),
//            .init(
//                callParticipantsCount: 2,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 2
//            ),
//
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 3
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 3
//            ),
//            .init(
//                callParticipantsCount: 3,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 3
//            ),
//
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: true,
//                isRemoteScreenSharing: false,
//                expectedCount: 4
//            ),
//            .init(
//                callParticipantsCount: 4,
//                participantsLayout: .fullScreen,
//                isLocalScreenSharing: false,
//                isRemoteScreenSharing: true,
//                expectedCount: 4
//            )
//        ])
//    }

    // MARK: - Move to foreground

//    @MainActor
//    func test_applicationDidBecomeActive_activatesAllTracksRequired() async throws {
//        LogConfig.level = .debug
//        let mockApplicationStateAdapter: MockAppStateAdapter! = .init()
//        InjectedValues[\.applicationStateAdapter] = mockApplicationStateAdapter
//        let call = try await prepareInCall(
//            callType: callType,
//            callId: callId,
//            members: []
//        )
//
//        let peerConnectionFactory = PeerConnectionFactory.build(
//            audioProcessingModule: MockAudioProcessingModule.shared
//        )
//        let trackA = try XCTUnwrap(
//            RTCVideoTrack.dummy(
//                kind: .video,
//                peerConnectionFactory: peerConnectionFactory
//            ) as? RTCVideoTrack
//        )
//        let trackB = try XCTUnwrap(
//            RTCVideoTrack.dummy(
//                kind: .video,
//                peerConnectionFactory: peerConnectionFactory
//            ) as? RTCVideoTrack
//        )
//        let trackC = try XCTUnwrap(
//            RTCVideoTrack.dummy(
//                kind: .video,
//                peerConnectionFactory: peerConnectionFactory
//            ) as? RTCVideoTrack
//        )
//        trackA.isEnabled = false
//        trackB.isEnabled = false
//        trackC.isEnabled = false
//
//        call.state.participantsMap = [
//            CallParticipant.dummy(id: call.state.sessionId), // Local participant
//            CallParticipant.dummy(hasVideo: true, track: trackA),
//            CallParticipant.dummy(hasVideo: true, track: trackB),
//            CallParticipant.dummy(hasVideo: false, track: trackC)
//        ].reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }
//        await fulfilmentInMainActor { self.subject.participants.count == 4 }
//
//        mockApplicationStateAdapter.stubbedState = .background
//        mockApplicationStateAdapter.stubbedState = .foreground
//        await fulfillment { trackA.isEnabled && trackB.isEnabled && !trackC.isEnabled }
//    }

    // MARK: - startScreensharing

    func test_startScreensharing_broadcast_pictureInPictureRemainsActive() async {
        // Given
        await prepare()
        subject.isPictureInPictureEnabled = true

        // When
        subject.startScreensharing(type: .broadcast)

        // Then
        await wait(for: 0.5)
        XCTAssertTrue(subject.isPictureInPictureEnabled)
    }

    func test_startScreensharing_inApp_pictureInPictureGetsDisabled() async {
        // Given
        await prepare()
        subject.isPictureInPictureEnabled = true

        // When
        subject.startScreensharing(type: .inApp)

        // Then
        await wait(for: 0.5)
        XCTAssertFalse(subject.isPictureInPictureEnabled)
    }

    // MARK: - leaveCall

    func test_leaveCall_resetsCallSettings() async {
        // Given
        await prepare()
        subject.startCall(
            callType: callType,
            callId: callId,
            members: participants
        )
        await assertCallingState(.inCall)
        subject.toggleMicrophoneEnabled()
        await fulfilmentInMainActor { self.subject.callSettings.audioOn == false }
        subject.toggleAudioOutput()
        await fulfilmentInMainActor { self.subject.callSettings.audioOutputOn == false }

        // When
        subject.hangUp()

        // Then
        await assertCallingState(.idle)
        XCTAssertTrue(subject.callSettings.audioOn)
        XCTAssertTrue(subject.callSettings.audioOutputOn)
        XCTAssertFalse(subject.localCallSettingsChange)
    }

    // MARK: - Private helpers

    private func prepare(
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        LogConfig.level = .debug

        mockCall.stub(
            for: .join,
            with: JoinCallResponse.dummy(
                call: .dummy(id: callId, type: callType)
            )
        )
        mockCall.stub(
            for: .create,
            with: CallResponse.dummy(
                cid: cId,
                settings: .dummy(
                    ring: .dummy(autoCancelTimeoutMs: 5000)
                )
            )
        )
        mockCall.stub(
            for: .get,
            with: GetCallResponse.dummy(
                call: CallResponse.dummy(
                    cid: cId,
                    settings: .dummy(
                        ring: .dummy(autoCancelTimeoutMs: 5000)
                    )
                )
            )
        )
        mockCall.stub(for: .reject, with: RejectCallResponse(duration: "0"))

        streamVideo = .init(stubbedProperty: [:], stubbedFunction: [
            .call: mockCall!
        ])
        streamVideo.state.user = firstUser.user

        subject = .init()
        await fulfilmentInMainActor(file: file, line: line) {
            self.subject.isSubscribedToCallEvents
        }
    }

    private func prepareIncomingCallScenario(
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        // Given
        await prepare(file: file, line: line)
        mockCall.stub(for: .accept, with: AcceptCallResponse(duration: "0"))

        let ringEvent = CallRingEvent(
            call: .dummy(
                cid: cId,
                createdBy: secondUser.user.toUserResponse(),
                id: callId,
                settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 10000)),
                type: callType
            ),
            callCid: cId,
            createdAt: .init(),
            members: [
                .init(createdAt: .init(), custom: [:], updatedAt: .init(), user: .dummy(id: firstUser.id), userId: firstUser.id)
            ],
            sessionId: .unique,
            user: secondUser.user.toUserResponse(),
            video: false
        )
        streamVideo.process(
            .coordinatorEvent(
                .typeCallRingEvent(
                    ringEvent
                )
            )
        )
        await assertCallingState(
            .incoming(
                .init(
                    id: callId,
                    caller: secondUser.user,
                    type: callType,
                    members: [firstUser, secondUser],
                    timeout: 10
                )
            ),
            file: file,
            line: line
        )
    }

    private func prepareMediaScenario(
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        await prepare(file: file, line: line)
        subject.startCall(
            callType: callType,
            callId: callId,
            members: participants
        )

        await assertCallingState(.inCall)
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
        await fulfilmentInMainActor { callViewModel.isSubscribedToCallEvents }

        callViewModel.startCall(callType: .default, callId: callId, members: [])
        nonisolated(unsafe) let callingState = callViewModel.callingState
        await fulfilmentInMainActor("CallViewModel.callingState expected:.inCall actual: \(callingState)") {
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
    
    @MainActor
    private func callViewModelWithRingingCall(participants: [Member]) async -> CallViewModel {
        let callViewModel = CallViewModel()
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callData = mockResponseBuilder.makeCallResponse(
            cid: cId
        )
        call?.state.update(from: callData)
        try? await Task.sleep(nanoseconds: 250_000_000)
        callViewModel.setActiveCall(call)
        callViewModel.outgoingCallMembers = participants
        callViewModel.callingState = .outgoing
        return callViewModel
    }

    @MainActor
    private func prepareInCall(
        callType: String,
        callId: String,
        members: [Member]
    ) async throws -> Call {
        _ = subject
        await fulfilmentInMainActor { self.subject.isSubscribedToCallEvents }

        subject.startCall(
            callType: callType,
            callId: callId,
            members: members
        )

        _ = try? await subject
            .$callingState
            .filter { $0 == .inCall }
            .nextValue(timeout: defaultTimeout)

        XCTAssertEqual(subject.callingState, .inCall)
        return try XCTUnwrap(subject.call)
    }

    private func assertCallingState(
        _ expected: CallingState,
        delay: TimeInterval? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async {
        if let delay {
            await wait(for: delay)
        }
        await fulfilmentInMainActor(
            "CallViewModel.callingState expected:\(expected) actual: \(subject.callingState)",
            file: file,
            line: line
        ) { self.subject.callingState == expected }
    }
}

extension User {
    func toUserResponse() -> UserResponse {
        UserResponse(
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
