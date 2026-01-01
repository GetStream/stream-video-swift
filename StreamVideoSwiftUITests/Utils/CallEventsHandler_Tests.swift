//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class CallEventsHandler_Tests: XCTestCase, @unchecked Sendable {
    
    private let callEventsHandler = CallEventsHandler()
    private let mockResponseBuilder = MockResponseBuilder()
    private let callCid = "default:123"

    func test_callEventsHandler_blockedUserEvent() {
        // Given
        let rawEvent = BlockedUserEvent(
            callCid: callCid,
            createdAt: Date(),
            user: mockResponseBuilder.makeUserResponse()
        )
        let event: VideoEvent = .typeBlockedUserEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .userBlocked(info) = callEvent {
            XCTAssert(info.callCid == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_callAcceptedEvent() {
        // Given
        let rawEvent = CallAcceptedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            user: mockResponseBuilder.makeUserResponse()
        )
        let event: VideoEvent = .typeCallAcceptedEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .accepted(info) = callEvent {
            XCTAssert(info.callCid == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_callEndedEvent() {
        // Given
        let rawEvent = CallEndedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            user: mockResponseBuilder.makeUserResponse()
        )
        let event: VideoEvent = .typeCallEndedEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .ended(info) = callEvent {
            XCTAssert(info.callCid == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_callRejectedEvent() {
        // Given
        let rawEvent = CallRejectedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            user: mockResponseBuilder.makeUserResponse()
        )
        let event: VideoEvent = .typeCallRejectedEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .rejected(info) = callEvent {
            XCTAssert(info.callCid == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_callRingEvent() {
        // Given
        let rawEvent = CallRingEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            members: [],
            sessionId: "123",
            user: mockResponseBuilder.makeUserResponse(),
            video: true
        )
        let event: VideoEvent = .typeCallRingEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .incoming(info) = callEvent {
            XCTAssert(info.id == "123")
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_callSessionStartedEvent() {
        // Given
        let rawEvent = CallSessionStartedEvent(
            call: mockResponseBuilder.makeCallResponse(cid: callCid),
            callCid: callCid,
            createdAt: Date(),
            sessionId: "123"
        )
        let event: VideoEvent = .typeCallSessionStartedEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .sessionStarted(info) = callEvent {
            XCTAssert(info.id == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_unblockedUserEvent() {
        let rawEvent = UnblockedUserEvent(
            callCid: callCid,
            createdAt: Date(),
            user: mockResponseBuilder.makeUserResponse()
        )
        let event: VideoEvent = .typeUnblockedUserEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        if case let .userUnblocked(info) = callEvent {
            XCTAssert(info.callCid == callCid)
        } else {
            XCTFail("Wrong event type")
        }
    }
    
    func test_callEventsHandler_unhandledEvent() {
        // Given
        let rawEvent = HealthCheckEvent(connectionId: "123", createdAt: Date())
        let event: VideoEvent = .typeHealthCheckEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForCallEvents(from: event)
        
        // Then
        XCTAssert(callEvent == nil)
    }
    
    func test_callEventsHandler_participantJoined() {
        // Given
        let rawEvent = CallSessionParticipantJoinedEvent(
            callCid: callCid,
            createdAt: Date(),
            participant: CallParticipantResponse(
                joinedAt: Date(),
                role: "user",
                user: mockResponseBuilder.makeUserResponse(),
                userSessionId: "123"
            ),
            sessionId: "123"
        )
        let event: VideoEvent = .typeCallSessionParticipantJoinedEvent(rawEvent)
        
        // When
        let participantEvent = callEventsHandler.checkForParticipantEvents(from: event)
        
        // Then
        XCTAssertNotNil(participantEvent)
        XCTAssert(participantEvent?.action == .join)
        XCTAssert(participantEvent?.id == "test")
    }
    
    func test_callEventsHandler_participantLeft() {
        // Given
        let rawEvent = CallSessionParticipantLeftEvent(
            callCid: callCid,
            createdAt: Date(),
            durationSeconds: 0,
            participant: CallParticipantResponse(
                joinedAt: Date(),
                role: "user",
                user: mockResponseBuilder.makeUserResponse(),
                userSessionId: "123"
            ),
            sessionId: "123"
        )
        let event: VideoEvent = .typeCallSessionParticipantLeftEvent(rawEvent)
        
        // When
        let participantEvent = callEventsHandler.checkForParticipantEvents(from: event)
        
        // Then
        XCTAssertNotNil(participantEvent)
        XCTAssert(participantEvent?.action == .leave)
        XCTAssert(participantEvent?.id == "test")
    }
    
    func test_callEventsHandler_unhandledEventParticipants() {
        // Given
        let rawEvent = HealthCheckEvent(connectionId: "123", createdAt: Date())
        let event: VideoEvent = .typeHealthCheckEvent(rawEvent)
        
        // When
        let callEvent = callEventsHandler.checkForParticipantEvents(from: event)
        
        // Then
        XCTAssert(callEvent == nil)
    }
}
