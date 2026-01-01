//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

@MainActor
final class CallsController_Tests: ControllerTestCase, @unchecked Sendable {
    
    let mockResponseBuilder = MockResponseBuilder()

    func test_callsController_queryCalls() async throws {
        // Given
        let callsController = try makeTestCallsController()
        
        // When
        try await callsController.loadNextCalls()
        
        // Then
        XCTAssert(callsController.calls.count == 2)
    }
    
    func test_callsController_newCall() async throws {
        // Given
        let callsController = try makeTestCallsController()
        
        // When
        try await callsController.loadNextCalls()
        let newCallCid = "default:newcall"
        let newCall = mockResponseBuilder.makeCallResponse(cid: newCallCid)
        let callCreatedEvent = CallCreatedEvent(
            call: newCall,
            callCid: newCallCid,
            createdAt: Date(),
            members: []
        )
        let event: WrappedEvent = .coordinatorEvent(.typeCallCreatedEvent(callCreatedEvent))
        streamVideo?.eventNotificationCenter.process(event)
                
        // Then
        await fulfillment { callsController.calls.count == 3 }
    }
    
    func test_callsController_updatedCall() async throws {
        // Given
        let callsController = try makeTestCallsController()
        
        // When
        try await callsController.loadNextCalls()
        XCTAssert(callsController.calls[0].state.backstage == false)
        let updatedCallId = "default:123"
        let call = mockResponseBuilder.makeCallResponse(cid: updatedCallId)
        call.backstage = true
        let callUpdatedEvent = CallUpdatedEvent(
            call: call,
            callCid: updatedCallId,
            capabilitiesByRole: [:],
            createdAt: Date()
        )
        let event: WrappedEvent = .coordinatorEvent(.typeCallUpdatedEvent(callUpdatedEvent))
        streamVideo?.eventNotificationCenter.process(event)
                
        // Then
        try await XCTAssertWithDelay(callsController.calls[0].state.backstage == true)
    }
    
    func test_callsController_rewatchCalls() async throws {
        // Given
        let callsController = try makeTestCallsController()
        
        // When
        try await callsController.loadNextCalls()
        // Simulate connection drop
        streamVideo?.state.connection = .disconnected()
        try await waitForCallEvent()
        streamVideo?.state.connection = .connected
        await fulfillment { self.httpClient.requestCounter == 2 }
    }
    
    func test_callsController_noWatchingCalls() async throws {
        // Given
        let callsController = try makeTestCallsController(watch: false)
        
        // When
        try await callsController.loadNextCalls()
        // Simulate connection drop
        streamVideo?.state.connection = .disconnected()
        try await waitForCallEvent()
        streamVideo?.state.connection = .connected
        try await waitForCallEvent()
        
        // Then
        // Calls should not be rewatched
        XCTAssert(httpClient.requestCounter == 1)
    }
    
    // MARK: - private
    
    private func makeTestCallsController(watch: Bool = true) throws -> CallsController {
        let response = mockResponseBuilder.makeQueryCallsResponse()
        let data = try JSONEncoder.default.encode(response)
        httpClient.dataResponses = [data, data]
        let query = CallsQuery(sortParams: [], watch: watch)
        let callsController = CallsController(
            streamVideo: streamVideo!,
            callsQuery: query
        )
        return callsController
    }
}
