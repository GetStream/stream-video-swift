//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class CallViewModel_Tests: StreamVideoTestCase {
    
    lazy var eventNotificationCenter = streamVideo?.eventNotificationCenter
    
    let firstUser = StreamVideo.mockUser
    let secondUser = User(id: "test2")
    let thirdUser = User(id: "test3")
    let callId = "test"
    let callType = CallType(name: "default")
    var callCid: String {
        "\(callType.name):\(callId)"
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
        callViewModel.startCall(callId: callId, type: .default, participants: participants)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .joining)
    }
    
    func test_startCall_outgoingState() {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        
        // Then
        XCTAssert(callViewModel.outgoingCallMembers == participants)
        XCTAssert(callViewModel.callingState == .outgoing)
    }
    
    func test_outgoingCall_rejectedEvent() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        let event = CallEventInfo(callId: callId, user: secondUser, action: .reject)
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_rejectedEventThreeParticipants() async throws {
        // Given
        let callViewModel = CallViewModel()
        let threeParticipants = participants + [thirdUser]
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: threeParticipants, ring: true)        
        try await waitForCallEvent()
        let firstReject = CallEventInfo(callId: callId, user: secondUser, action: .reject)
        eventNotificationCenter?.process(firstReject)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .outgoing)
        
        // When
        let secondReject = CallEventInfo(callId: callId, user: thirdUser, action: .reject)
        eventNotificationCenter?.process(secondReject)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_canceledEvent() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        let event = CallEventInfo(callId: callId, user: secondUser, action: .cancel)
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_callEndedEvent() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        let event = CallEventInfo(callId: callId, user: firstUser, action: .end)
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_blockEventCurrentUser() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        let event = CallEventInfo(callId: callId, user: firstUser, action: .block)
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_outgoingCall_blockEventOtherUser() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        let event = CallEventInfo(callId: callId, user: secondUser, action: .block)
        eventNotificationCenter?.process(event)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState != .idle)
    }
    
    func test_outgoingCall_hangUp() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants, ring: true)
        try await waitForCallEvent()
        callViewModel.hangUp()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_incomingCall_acceptCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        try await waitForCallEvent()
        let event = IncomingCallEvent(
            callCid: callCid,
            createdBy: secondUser.id,
            type: callType.name,
            users: participants,
            ringing: true
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
        callViewModel.acceptCall(callId: callId, type: callType)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
    }
    
    func test_incomingCall_rejectCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        try await waitForCallEvent()
        let event = IncomingCallEvent(
            callCid: callCid,
            createdBy: secondUser.id,
            type: callType.name,
            users: participants,
            ringing: true
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
        callViewModel.rejectCall(callId: callId, type: callType)
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .idle)
    }
    
    func test_joinCall_success() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.joinCall(callId: callId, type: callType)
        
        // Then
        XCTAssert(callViewModel.callingState == .joining)
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
    }
    
    func test_enterLobby_joinCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.enterLobby(callId: callId, type: callType, participants: participants)
        
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
        try callViewModel.joinCallFromLobby(
            callId: callId,
            type: callType,
            participants: participants
        )
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callingState == .inCall)
    }
    
    func test_enterLobby_leaveCall() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.enterLobby(callId: callId, type: callType, participants: participants)
        
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
        callViewModel.startCall(callId: callId, type: .default, participants: participants)
        try await waitForCallEvent()
        callViewModel.toggleCameraEnabled()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.videoOn == false)
    }
    
    func test_callSettings_toggleAudio() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants)
        try await waitForCallEvent()
        callViewModel.toggleMicrophoneEnabled()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.audioOn == false)
    }
    
    func test_callSettings_toggleCameraPosition() async throws {
        // Given
        let callViewModel = CallViewModel()
        
        // When
        callViewModel.startCall(callId: callId, type: .default, participants: participants)
        try await waitForCallEvent()
        callViewModel.toggleCameraPosition()
        
        // Then
        try await XCTAssertWithDelay(callViewModel.callSettings.cameraPosition == .back)
    }
    
    // MARK: - private
    
    private func waitForCallEvent() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }
    
}

@MainActor
func XCTAssertWithDelay(
    _ expression: @autoclosure () throws -> Bool,
    nanoseconds: UInt64 = 500_000_000
) async throws {
    try await Task.sleep(nanoseconds: nanoseconds)
    XCTAssert(try expression())
}
