//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

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
        
        // Then
        XCTAssert(call?.state.callData == nil)
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.callCid == callCid)
        XCTAssert(call?.state.callData?.session?.acceptedBy[userId] != nil)
        XCTAssert(call?.state.callData?.backstage == false)
        XCTAssert(call?.state.callData?.broadcasting == false)
        XCTAssert(call?.state.callData?.recording == false)
        XCTAssert(call?.state.callData?.session != nil)
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
        
        // Then
        XCTAssert(call?.state.callData == nil)
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.callCid == callCid)
        XCTAssert(call?.state.callData?.session?.rejectedBy[userId] != nil)
        XCTAssert(call?.state.callData?.backstage == false)
        XCTAssert(call?.state.callData?.broadcasting == false)
        XCTAssert(call?.state.callData?.recording == false)
        XCTAssert(call?.state.callData?.session != nil)
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
        
        // Then
        XCTAssert(call?.state.callData == nil)
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.callCid == callCid)
        XCTAssert(call?.state.callData?.backstage == false)
        XCTAssert(call?.state.callData?.broadcasting == false)
        XCTAssert(call?.state.callData?.recording == false)
        XCTAssert(call?.state.callData?.session != nil)
    }
    
    func test_updateState_fromRecordingStartedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        call?.state.callData = callResponse.toCallData(members: [], blockedUsers: [])
        let event = CallRecordingStartedEvent(callCid: callCid, createdAt: Date())
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.recordingState == .recording)
        XCTAssert(call?.state.callData?.recording == true)
    }
    
    func test_updateState_fromRecordingStoppedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        call?.state.callData = callResponse.toCallData(members: [], blockedUsers: [])
        let event = CallRecordingStoppedEvent(callCid: callCid, createdAt: Date())
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.recordingState == .noRecording)
        XCTAssert(call?.state.callData?.recording == false)
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
        let coordinatorController = CallCoordinatorController(
            defaultAPI: defaultAPI,
            user: userResponse.toUser,
            coordinatorInfo: CoordinatorInfo(
                apiKey: "key1",
                hostname: "hostname",
                token: "some_token"
            ),
            videoConfig: videoConfig
        )
        let callController = CallController_Mock(
            defaultAPI: defaultAPI,
            callCoordinatorController: coordinatorController,
            user: userResponse.toUser,
            callId: callId,
            callType: callType,
            apiKey: "key1",
            videoConfig: videoConfig
        )
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let callData = callResponse.toCallData(members: [], blockedUsers: [])
        coordinatorController.currentCallSettings = CallSettingsInfo(
            callCapabilities: [],
            callSettings: mockResponseBuilder.makeCallSettingsResponse(),
            state: callData,
            recording: false
        )
        let call = Call(
            callType: callType,
            callId: callId,
            defaultAPI: defaultAPI,
            callCoordinatorController: coordinatorController,
            callController: callController,
            videoOptions: VideoOptions()
        )
        call.state.callData = callData
        let event = UpdatedCallPermissionsEvent(
            callCid: callCid,
            createdAt: Date(),
            ownCapabilities: [.sendAudio],
            user: userResponse
        )
        
        // When
        call.updateState(from: event)
        
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
        call?.state.callData = callResponse.toCallData(members: [], blockedUsers: [])
        let userId = "test"
        let member = mockResponseBuilder.makeMemberResponse(id: userId)
        let event = CallMemberAddedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [member]
        )
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.members.first?.id == userId)
    }
    
    func test_updateState_fromMemberRemovedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let userId = "test"
        let member = mockResponseBuilder.makeMemberResponse(id: userId)
        call?.state.callData = callResponse.toCallData(members: [member], blockedUsers: [])
        let event = CallMemberRemovedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [userId]
        )
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.members.isEmpty == true)
    }

    func test_updateState_fromMemberUpdatedEvent() {
        // Given
        let call = streamVideo?.call(callType: callType, callId: callId)
        let callResponse = mockResponseBuilder.makeCallResponse(
            cid: callCid
        )
        let userId = "test"
        var member = mockResponseBuilder.makeMemberResponse(id: userId)
        call?.state.callData = callResponse.toCallData(members: [member], blockedUsers: [])
        member.user.name = "newname"
        let event = CallMemberUpdatedEvent(
            call: callResponse,
            callCid: callCid,
            createdAt: Date(),
            members: [member]
        )
        
        // When
        call?.updateState(from: event)
        
        // Then
        XCTAssert(call?.state.callData?.members.first?.user.name == "newname")
    }
    
}
