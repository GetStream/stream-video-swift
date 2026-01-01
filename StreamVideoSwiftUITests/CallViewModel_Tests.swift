//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
@testable import StreamVideoSwiftUI
import StreamWebRTC
import XCTest

@MainActor
final class CallViewModel_Tests: XCTestCase, @unchecked Sendable {

    private lazy var firstUser: Member! = Member(user: StreamVideo.mockUser, updatedAt: .now)
    private lazy var secondUser: Member! = Member(user: User(id: "test2"), updatedAt: .now)
    private lazy var thirdUser: Member! = Member(user: User(id: "test3"), updatedAt: .now)
    private lazy var callType: String! = .default
    private lazy var callId: String! = UUID().uuidString
    private lazy var participants: [Member]! = [firstUser, secondUser]
    private var streamVideo: MockStreamVideo! = .init()
    private lazy var mockCoordinatorClient: MockDefaultAPI! = .init()
    private lazy var mockCall: MockCall! = .init(
        .dummy(
            callType: callType,
            callId: callId,
            coordinatorClient: mockCoordinatorClient
        )
    )

    private var subject: CallViewModel!

    private var cId: String { callCid(from: callId, callType: callType) }

    override func tearDown() async throws {
        subject = nil
        participants = nil
        callId = nil
        callType = nil
        thirdUser = nil
        secondUser = nil
        firstUser = nil
        mockCoordinatorClient = nil
        try await super.tearDown()
    }

    @MainActor
    func test_startCall_withoutLocalCallSettingsAndRingTrue_respectsDashboardSettings() async throws {
        // Given
        let mockCall = MockCall(.dummy(callType: .default, callId: callId))
        await streamVideo?.disconnect()
        streamVideo = nil
        let mockStreamVideo = MockStreamVideo()
        mockStreamVideo.stub(for: .call, with: mockCall)
        let callViewModel = CallViewModel()

        // When
        callViewModel.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )

        // Then
        XCTAssertEqual(mockStreamVideo.timesCalled(.call), 1)
        let (
            recordedCallType,
            recordedCallId,
            recordedCallSettings
        ) = try XCTUnwrap(
            mockStreamVideo
                .recordedInputPayload((String, String, CallSettings?).self, for: .call)?.first
        )
        XCTAssertEqual(recordedCallType, callType)
        XCTAssertEqual(recordedCallId, callId)
        XCTAssertNil(recordedCallSettings)
    }

    @MainActor
    func test_startCall_withLocalCallSettingsAndRingTrue_respectsLocalSettings() async throws {
        // Given
        let mockCall = MockCall(.dummy(callType: .default, callId: callId))
        await streamVideo?.disconnect()
        streamVideo = nil
        let mockStreamVideo = MockStreamVideo()
        mockStreamVideo.stub(for: .call, with: mockCall)
        let callViewModel = CallViewModel(callSettings: .init(audioOn: false, audioOutputOn: false))

        // When
        callViewModel.startCall(
            callType: .default,
            callId: callId,
            members: participants,
            ring: true
        )

        // Then
        XCTAssertEqual(mockStreamVideo.timesCalled(.call), 1)
        let (
            recordedCallType,
            recordedCallId,
            recordedCallSettings
        ) = try XCTUnwrap(
            mockStreamVideo
                .recordedInputPayload((String, String, CallSettings?).self, for: .call)?.first
        )
        XCTAssertEqual(recordedCallType, callType)
        XCTAssertEqual(recordedCallId, callId)
        XCTAssertFalse(recordedCallSettings?.audioOn ?? true)
        XCTAssertFalse(recordedCallSettings?.audioOutputOn ?? true)
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

    func test_outgoingCall_callCreatedPriorToStarting_rejectedEventFromOneParticipantCallRemainsOngoing() async throws {
        // Given
        let memberResponses = (participants + [thirdUser]).map {
            MemberResponse(
                createdAt: .init(),
                custom: [:],
                updatedAt: .init(),
                user: .dummy(id: $0.id),
                userId: $0.userId
            )
        }
        mockCoordinatorClient.stub(
            for: .getOrCreateCall,
            with: GetOrCreateCallResponse(
                call: .dummy(
                    cid: callCid(from: callId, callType: callType),
                    settings: .dummy(ring: .dummy(autoCancelTimeoutMs: 15000))
                ),
                created: true,
                duration: "",
                members: memberResponses,
                ownCapabilities: []
            )
        )
        await prepare()
        mockCall.stub(for: .create, with: ()) // We stub with something irrelevant to cause the mock to forward to super the request

        subject.startCall(
            callType: .default,
            callId: callId,
            members: [],
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

    func test_joinAndRingCall_joinsAndRingsMembers() async throws {
        // Given
        await prepare()
        mockCall.resetRecords(for: .join)
        mockCall.resetRecords(for: .ring)
        let thirdParticipant = try XCTUnwrap(thirdUser)
        let recipients: [Member] = participants + [thirdParticipant]
        let team = "test-team"
        let startsAt = Date(timeIntervalSince1970: 1_700_000_000)
        let maxDuration = 600
        let maxParticipants = 8
        let customData: [String: RawJSON] = ["topic": .string("demo")]
        let expectedOptions = CreateCallOptions(
            members: recipients.map(\.toMemberRequest),
            custom: customData,
            settings: CallSettingsRequest(
                limits: LimitsSettingsRequest(
                    maxDurationSeconds: maxDuration,
                    maxParticipants: maxParticipants
                )
            ),
            startsAt: startsAt,
            team: team
        )

        // When
        subject.joinAndRingCall(
            callType: callType,
            callId: callId,
            members: recipients,
            team: team,
            maxDuration: maxDuration,
            maxParticipants: maxParticipants,
            startsAt: startsAt,
            customData: customData,
            video: true
        )

        // Then
        XCTAssertEqual(subject.callingState, .outgoing)
        XCTAssertEqual(subject.outgoingCallMembers, recipients)

        await fulfilmentInMainActor { self.mockCall.timesCalled(.join) == 1 }
        let joinPayload = try XCTUnwrap(
            mockCall
                .recordedInputPayload((Bool, CreateCallOptions?, Bool, Bool, CallSettings?).self, for: .join)?
                .last
        )
        let (createFlag, options, ringFlag, notifyFlag, forwardedCallSettings) = joinPayload
        XCTAssertTrue(createFlag)
        XCTAssertEqual(options, expectedOptions)
        XCTAssertFalse(ringFlag)
        XCTAssertFalse(notifyFlag)
        XCTAssertNil(forwardedCallSettings)

        await fulfilmentInMainActor { self.mockCall.timesCalled(.ring) == 1 }
        let ringRequest = try XCTUnwrap(
            mockCall
                .recordedInputPayload(RingCallRequest.self, for: .ring)?
                .last
        )
        XCTAssertEqual(
            ringRequest,
            RingCallRequest(
                membersIds: [secondUser.id, thirdParticipant.id],
                video: true
            )
        )
    }

    func test_joinAndRingCall_usesLocalCallSettingsOverrides() async throws {
        // Given
        await prepare()
        mockCall.resetRecords(for: .join)
        mockCall.resetRecords(for: .ring)
        subject.toggleMicrophoneEnabled()
        await fulfilmentInMainActor { self.subject.callSettings.audioOn == false }
        let expectedCallSettings = subject.callSettings

        // When
        subject.joinAndRingCall(
            callType: callType,
            callId: callId,
            members: participants
        )

        // Then
        XCTAssertEqual(subject.callingState, .outgoing)
        await fulfilmentInMainActor { self.mockCall.timesCalled(.join) == 1 }
        let joinPayload = try XCTUnwrap(
            mockCall
                .recordedInputPayload((Bool, CreateCallOptions?, Bool, Bool, CallSettings?).self, for: .join)?
                .last
        )
        let (_, _, _, _, forwardedCallSettings) = joinPayload
        XCTAssertEqual(forwardedCallSettings, expectedCallSettings)
        XCTAssertEqual(
            joinPayload.1?.members,
            participants.map(\.toMemberRequest)
        )

        await fulfilmentInMainActor { self.mockCall.timesCalled(.ring) == 1 }
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

    func test_inCall_participantEvents() async throws {
        // Given
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)

        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallSessionParticipantJoinedEvent(
                    .init(
                        callCid: cId,
                        createdAt: .init(),
                        participant: .dummy(userSessionId: "123"),
                        sessionId: "123"
                    )
                )
            )
        )

        // Then
        await fulfilmentInMainActor { self.subject.participantEvent != nil }
        await fulfilmentInMainActor { self.subject.participantEvent == nil }
    }

    func test_inCall_ringingCallEnds_activeCallRemainsJoined() async throws {
        // Given
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)

        let newCallId = String.unique
        let cid = callCid(from: newCallId, callType: .default)
        // When
        streamVideo.process(
            .coordinatorEvent(
                .typeCallRingEvent(
                    .init(
                        call: .dummy(cid: cid),
                        callCid: cid,
                        createdAt: .init(),
                        members: [],
                        sessionId: .unique,
                        user: .dummy(),
                        video: true
                    )
                )
            )
        )
        streamVideo.process(
            .coordinatorEvent(
                .typeCallEndedEvent(
                    .init(
                        call: .dummy(cid: cid),
                        callCid: cid,
                        createdAt: .init()
                    )
                )
            )
        )

        // Then
        await assertCallingState(.inCall)
    }

    func test_inCall_participantJoinedAndLeft() async throws {
        // Given
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)
        let newParticipant = CallParticipant.dummy()
        mockCall.state.participantsMap[newParticipant.sessionId] = newParticipant
        await fulfilmentInMainActor { self.subject.participants.first { $0.sessionId == newParticipant.sessionId } != nil }

        // When
        mockCall.state.participantsMap[newParticipant.sessionId] = nil

        // Then
        await fulfilmentInMainActor { self.subject.participants.first { $0.sessionId == newParticipant.sessionId } == nil }
    }

    func test_inCall_changeTrackVisibility() async throws {
        // Given
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)
        await fulfilmentInMainActor {
            self
                .subject
                .participants
                .first { $0.sessionId == self.secondUser.id && $0.showTrack == false } == nil
        }

        // When
        subject.changeTrackVisibility(for: .dummy(userId: secondUser.id, sessionId: secondUser.id), isVisible: true)

        // Then
        await fulfilmentInMainActor {
            self
                .subject
                .participants
                .first { $0.sessionId == self.secondUser.id && $0.showTrack == true } == nil
        }
    }

    func test_pinParticipant_manualLayoutChange() async throws {
        // Given
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)
        XCTAssertEqual(subject.participantsLayout, .grid)

        // When
        subject.update(participantsLayout: .fullScreen)

        // Then
        await fulfilmentInMainActor {
            self.subject.participantsLayout == .fullScreen
        }
    }
    
    // MARK: - Participants

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

    // MARK: - Move to foreground

    func test_applicationDidBecomeActive_activatesAllTracksRequired() async throws {
        // Given
        let mockApplicationStateAdapter: MockAppStateAdapter! = .init()
        InjectedValues[\.applicationStateAdapter] = mockApplicationStateAdapter
        await prepare()
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)
        let peerConnectionFactory = PeerConnectionFactory.build(
            audioProcessingModule: MockAudioProcessingModule.shared
        )
        let trackA = try XCTUnwrap(
            RTCVideoTrack.dummy(
                kind: .video,
                peerConnectionFactory: peerConnectionFactory
            ) as? RTCVideoTrack
        )
        let trackB = try XCTUnwrap(
            RTCVideoTrack.dummy(
                kind: .video,
                peerConnectionFactory: peerConnectionFactory
            ) as? RTCVideoTrack
        )
        let trackC = try XCTUnwrap(
            RTCVideoTrack.dummy(
                kind: .video,
                peerConnectionFactory: peerConnectionFactory
            ) as? RTCVideoTrack
        )
        trackA.isEnabled = false
        trackB.isEnabled = false
        trackC.isEnabled = false

        mockCall.state.participantsMap = [
            CallParticipant.dummy(id: mockCall.state.sessionId), // Local participant
            CallParticipant.dummy(hasVideo: true, track: trackA),
            CallParticipant.dummy(hasVideo: true, track: trackB),
            CallParticipant.dummy(hasVideo: false, track: trackC)
        ].reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }
        await fulfilmentInMainActor { self.subject.participants.count == 4 }

        // When
        mockApplicationStateAdapter.stubbedState = .background
        mockApplicationStateAdapter.stubbedState = .foreground

        // Then
        await fulfillment { trackA.isEnabled && trackB.isEnabled && !trackC.isEnabled }
    }

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
        mockCall.stub(for: .ring, with: RingCallResponse(duration: "0", membersIds: participants.map(\.id)))

        streamVideo = .init(stubbedProperty: [:], stubbedFunction: [
            .call: mockCall!
        ])
        streamVideo.state.user = firstUser.user

        subject = .init()
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

        await assertCallingState(.inCall, file: file, line: line)
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
                isLocalScreenSharing: scenario.isLocalScreenSharing,
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
        await prepare(file: file, line: line)
        subject.startCall(callType: callType, callId: callId, members: participants)
        await assertCallingState(.inCall)
        let call = try XCTUnwrap(subject.call, file: file, line: line)

        let localParticipant = CallParticipant.dummy(
            id: call.state.sessionId,
            isScreenSharing: isLocalScreenSharing
        )

        let remoteCallParticipants = (0..<(callParticipantsCount - 1))
            .map { CallParticipant.dummy(id: "test-participant-\($0)") }

        if isLocalScreenSharing {
            subject.call?.state.screenSharingSession = .init(
                track: nil,
                participant: localParticipant
            )
        } else if isRemoteScreenSharing, let firstRemoteCallParticipant = remoteCallParticipants.first {
            subject.call?.state.screenSharingSession = .init(
                track: nil,
                participant: firstRemoteCallParticipant
            )
        }

        subject.update(participantsLayout: participantsLayout)
        subject.call?.state.participantsMap = ([localParticipant] + remoteCallParticipants)
            .reduce(into: [String: CallParticipant]()) { $0[$1.id] = $1 }

        await fulfilmentInMainActor(file: file, line: line) { self.subject.participants.count == expectedCount }
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
        #if compiler(>=6.0)
        await fulfilmentInMainActor(
            "CallViewModel.callingState expected:\(expected) actual: \(subject.callingState)",
            file: file,
            line: line
        ) { self.subject.callingState == expected }
        #else
        await fulfilmentInMainActor(
            file: file,
            line: line
        ) { self.subject.callingState == expected }
        #endif
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
