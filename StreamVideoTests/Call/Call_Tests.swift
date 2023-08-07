//
// Copyright © 2023 Stream.io Inc. All rights reserved.
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
        let videoConfig = VideoConfig()
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
            callController: callController,
            videoOptions: VideoOptions()
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
        call?.state.members = [Member(user: .init(id: userId), updatedAt: .now)]
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
        call?.state.members = [Member(user: .init(id: userId), updatedAt: .now)]
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
        try await waitForCallEvent(nanoseconds: 1_000_000_000)
        
        // Then
        var duration = call?.state.duration ?? 0
        XCTAssertEqual(Int(duration), 1)
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
        XCTAssertEqual(Int(duration), 1)
    }
    
}
