//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamVideo_Tests: StreamVideoTestCase {

    func test_streamVideo_anonymousConnectError() async throws {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: .anonymous,
            token: StreamVideo.mockToken,
            tokenProvider: { _ in }
        )
        
        // Then
        do {
            try await streamVideo.connect()
            XCTFail("connect should fail for anonymous users")
        } catch {
            XCTAssert(error is ClientError.MissingPermissions)
        }
    }
    
    func test_streamVideo_makeCall() {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: StreamVideo.mockUser,
            token: StreamVideo.mockToken,
            tokenProvider: { _ in }
        )
        
        // When
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // Then
        XCTAssert(call.cId == "default:123")
        XCTAssert(call.callType == .default)
        XCTAssert(call.callId == "123")
    }
    
    func test_streamVideo_activeCallAndLeave() async throws {
        // Given
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // When
        try await call.join()

        // Then
        XCTAssert(streamVideo.state.activeCall?.cId == call.cId)
        
        // When
        call.leave()
        
        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
    }
    
    func test_streamVideo_ringCallAccept() async throws {
        let httpClient = httpClientWithGetCallResponse()
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // When
        try await call.ring()
        
        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)
        
        // When
        let callAcceptedEvent = CallAcceptedEvent(
            call: makeCallResponse(),
            callCid: "123",
            createdAt: Date(),
            user: makeUserResponse()
        )
        let event = WrappedEvent.coordinatorEvent(.typeCallAcceptedEvent(callAcceptedEvent))
        streamVideo.eventNotificationCenter.process(event)
        try await call.join()
        
        // Then
        XCTAssert(streamVideo.state.ringingCall == nil)
        XCTAssert(streamVideo.state.activeCall?.cId == call.cId)
    }
    
    func test_streamVideo_ringCallReject() async throws {
        let httpClient = httpClientWithGetCallResponse()
        let rejectCallResponse = RejectCallResponse(duration: "1")
        let data = try! JSONEncoder.default.encode(rejectCallResponse)
        httpClient.dataResponses.append(data)
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        let call = streamVideo.call(callType: .default, callId: "123")
        
        // When
        try await call.ring()
        
        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)
        
        // When
        try await call.reject()
        
        // Then
        XCTAssert(streamVideo.state.ringingCall == nil)
        XCTAssert(streamVideo.state.activeCall == nil)
    }
    
    func test_streamVideo_incomingCallAccept() async throws {
        // Given
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        let call = streamVideo.call(callType: .default, callId: "123")

        // When
        let ringEvent = CallRingEvent(
            call: makeCallResponse(),
            callCid: "default:123",
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: makeUserResponse()
        )
        let incomingCall = WrappedEvent.coordinatorEvent(.typeCallRingEvent(ringEvent))
        streamVideo.eventNotificationCenter.process(incomingCall)
        try await waitForCallEvent()
        
        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)

        // When
        try await call.join()
        
        // Then
        XCTAssert(streamVideo.state.ringingCall == nil)
        XCTAssert(streamVideo.state.activeCall?.cId == call.cId)
    }
    
    func test_streamVideo_incomingCallReject() async throws {
        // Given
        let httpClient = HTTPClient_Mock()
        let data = try! JSONEncoder().encode(RejectCallResponse(duration: "1"))
        httpClient.dataResponses = [data]
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        let call = streamVideo.call(callType: .default, callId: "123")

        // When
        let ringEvent = CallRingEvent(
            call: makeCallResponse(),
            callCid: "default:123",
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: makeUserResponse()
        )
        let incomingCall = WrappedEvent.coordinatorEvent(.typeCallRingEvent(ringEvent))
        streamVideo.eventNotificationCenter.process(incomingCall)
        try await waitForCallEvent()
        
        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)

        // When
        try await call.reject()
        
        // Then
        XCTAssert(streamVideo.state.ringingCall == nil)
        XCTAssert(streamVideo.state.activeCall == nil)
    }
    
    func test_streamVideo_initialState() {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: StreamVideo.mockUser,
            token: StreamVideo.mockToken,
            tokenProvider: { _ in }
        )
        
        // Then
        XCTAssert(streamVideo.state.user == StreamVideo.mockUser)
        XCTAssert(streamVideo.state.connection == .initialized)
    }
    
    //MARK: - private
    
    private func makeCallResponse() -> CallResponse {
        let callResponse = MockResponseBuilder().makeCallResponse(cid: "default:123")
        return callResponse
    }
    
    private func makeUserResponse() -> UserResponse {
        UserResponse(
            createdAt: Date(),
            custom: [:],
            id: "test",
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
    
    private func httpClientWithGetCallResponse() -> HTTPClient_Mock {
        let httpClient = HTTPClient_Mock()
        let callResponse = makeCallResponse()
        let getCallResponse = GetCallResponse(
            call: callResponse,
            duration: "1",
            members: [],
            ownCapabilities: []
        )
        let data = try! JSONEncoder.default.encode(getCallResponse)
        httpClient.dataResponses = [data]
        return httpClient
    }
    
}
