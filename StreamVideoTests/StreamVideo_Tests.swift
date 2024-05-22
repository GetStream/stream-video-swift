//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

final class StreamVideo_Tests: StreamVideoTestCase {

    private lazy var callId: String! = String(String.unique.prefix(10))
    private lazy var callType: String! = .default
    private var cId: String { callCid(from: callId, callType: callType) }

    override func tearDown() {
        callId = nil
        callType = nil
        super.tearDown()
    }

    func test_streamVideo_anonymousConnectError() async throws {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: .anonymous,
            token: StreamVideo.mockToken,
            videoConfig: .dummy(),
            tokenProvider: { _ in }
        )
        self.streamVideo = streamVideo

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
            videoConfig: .dummy(),
            tokenProvider: { _ in }
        )
        self.streamVideo = streamVideo

        // When
        let call = streamVideo.call(callType: callType, callId: callId)

        // Then
        XCTAssert(call.cId == cId)
        XCTAssert(call.callType == callType)
        XCTAssert(call.callId == callId)
    }

    func test_streamVideo_activeCallAndLeave() async throws {
        // Given
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        self.streamVideo = streamVideo
        let call = streamVideo.call(callType: callType, callId: callId)

        // When
        try await call.join()

        await fulfillment { streamVideo.state.activeCall != nil }

        // Then
        XCTAssert(streamVideo.state.activeCall?.cId == call.cId)
        
        // When
        call.leave()

        await fulfillment { streamVideo.state.activeCall == nil }

        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
    }
    
    func test_streamVideo_ringCallAccept() async throws {
        let httpClient = httpClientWithGetCallResponse()
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        self.streamVideo = streamVideo
        let call = streamVideo.call(callType: callType, callId: callId)

        // When
        try await call.ring()
        await fulfillment {
            streamVideo.state.activeCall == nil
                && streamVideo.state.ringingCall != nil
        }

        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)
        
        // When
        let callAcceptedEvent = CallAcceptedEvent(
            call: makeCallResponse(),
            callCid: cId,
            createdAt: Date(),
            user: makeUserResponse()
        )
        let event = WrappedEvent.coordinatorEvent(.typeCallAcceptedEvent(callAcceptedEvent))
        streamVideo.eventNotificationCenter.process(event)
        try await call.join()
        await fulfillment {
            streamVideo.state.activeCall != nil
                && streamVideo.state.ringingCall == nil
        }

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
        self.streamVideo = streamVideo
        let call = streamVideo.call(callType: callType, callId: callId)

        // When
        try await call.ring()
        await fulfillment {
            streamVideo.state.activeCall == nil
                && streamVideo.state.ringingCall != nil
        }

        // Then
        XCTAssert(streamVideo.state.activeCall == nil)
        XCTAssert(streamVideo.state.ringingCall?.cId == call.cId)
        
        // When
        try await call.reject()
        await fulfillment {
            streamVideo.state.activeCall == nil
                && streamVideo.state.ringingCall == nil
        }

        // Then
        XCTAssert(streamVideo.state.ringingCall == nil)
        XCTAssert(streamVideo.state.activeCall == nil)
    }
    
    func test_streamVideo_incomingCallAccept() async throws {
        // Given
        let streamVideo = StreamVideo.mock(httpClient: HTTPClient_Mock())
        self.streamVideo = streamVideo
        let call = streamVideo.call(callType: callType, callId: callId)

        // When
        let ringEvent = CallRingEvent(
            call: makeCallResponse(),
            callCid: cId,
            createdAt: Date(),
            members: [],
            sessionId: callId,
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
        await fulfillment {
            streamVideo.state.activeCall != nil
                && streamVideo.state.ringingCall == nil
        }

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
        self.streamVideo = streamVideo
        let call = streamVideo.call(callType: callType, callId: callId)

        // When
        let ringEvent = CallRingEvent(
            call: makeCallResponse(),
            callCid: cId,
            createdAt: Date(),
            members: [],
            sessionId: callId,
            user: makeUserResponse()
        )
        let incomingCall = WrappedEvent.coordinatorEvent(.typeCallRingEvent(ringEvent))
        streamVideo.eventNotificationCenter.process(incomingCall)
        try await waitForCallEvent()
        await fulfillment {
            streamVideo.state.activeCall == nil
                && streamVideo.state.ringingCall != nil
        }

        // Then
        XCTAssertNil(streamVideo.state.activeCall)
        XCTAssertEqual(streamVideo.state.ringingCall?.cId, call.cId)

        // When
        try await call.reject()
        await fulfillment {
            streamVideo.state.activeCall == nil
                && streamVideo.state.ringingCall == nil
        }

        // Then
        XCTAssertNil(streamVideo.state.ringingCall)
        XCTAssertNil(streamVideo.state.activeCall)
    }
    
    func test_streamVideo_initialState() {
        // Given
        let streamVideo = StreamVideo(
            apiKey: "key1",
            user: StreamVideo.mockUser,
            token: StreamVideo.mockToken,
            videoConfig: .dummy(),
            tokenProvider: { _ in }
        )
        
        // Then
        XCTAssert(streamVideo.state.user == StreamVideo.mockUser)
        XCTAssert(streamVideo.state.connection == .initialized)
    }
    
    // MARK: - private
    
    private func makeCallResponse() -> CallResponse {
        let callResponse = MockResponseBuilder().makeCallResponse(cid: cId)
        return callResponse
    }
    
    private func makeUserResponse() -> UserResponse {
        UserResponse(
            createdAt: Date(),
            custom: [:],
            id: "test",
            language: "en",
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
