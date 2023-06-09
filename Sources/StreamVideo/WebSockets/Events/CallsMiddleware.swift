//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CallsMiddleware: EventMiddleware {
    
    var onCallEvent: ((CallEvent) -> Void)?
    var onCallUpdated: ((CallData) -> Void)?
    var onBroadcastingEvent: ((BroadcastingEvent) -> Void)?
    var onAnyEvent: ((Event) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let ringEvent = event as? CallRingEvent {
            log.debug("Received ring event \(ringEvent)")
            let cId = ringEvent.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let caller = ringEvent.call.createdBy.toUser
            let type = ringEvent.call.type
            let incomingCall = IncomingCall(
                id: id,
                caller: caller,
                type: type,
                participants: ringEvent.members.map {
                    let user = $0.user.toUser
                    let member = Member(
                        user: user,
                        role: $0.role ?? $0.user.role,
                        customData: convert($0.custom)
                    )
                    return member
                },
                timeout: TimeInterval(ringEvent.call.settings.ring.autoCancelTimeoutMs / 1000)
            )
            onCallEvent?(.incoming(incomingCall))
        } else if let event = event as? CallAcceptedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .accept
            )
            let state = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map {
                    userResponse(from: $0)
                }
            )
            onCallUpdated?(state)
            onCallEvent?(.accepted(callEventInfo))
        } else if let event = event as? CallRejectedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .reject
            )
            let state = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map {
                    userResponse(from: $0)
                }
            )
            onCallUpdated?(state)
            onCallEvent?(.rejected(callEventInfo))
        } else if let event = event as? CallEndedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user?.toUser,
                action: .end
            )
            onCallEvent?(.ended(callEventInfo))
        } else if let event = event as? BlockedUserEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .block
            )
            onCallEvent?(.userBlocked(callEventInfo))
        } else if let event = event as? UnblockedUserEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .unblock
            )
            onCallEvent?(.userUnblocked(callEventInfo))
        } else if let event = event as? CallUpdatedEvent {
            let state = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map {
                    userResponse(from: $0)
                }
            )
            onCallUpdated?(state)
        } else if let event = event as? CallSessionStartedEvent {
            let call = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map {
                    userResponse(from: $0)
                }
            )
            let sessionInfo = SessionInfo(
                call: call,
                callCid: event.callCid,
                createdAt: event.createdAt,
                sessionId: event.sessionId
            )
            onCallEvent?(.sessionStarted(sessionInfo))
        } else if let event = event as? CallBroadcastingStartedEvent {
            let broadcastStarted = BroadcastingStartedEvent(
                callCid: event.callCid,
                createdAt: event.createdAt,
                hlsPlaylistUrl: event.hlsPlaylistUrl,
                type: event.type
            )
            onBroadcastingEvent?(broadcastStarted)
        } else if let event = event as? CallBroadcastingStoppedEvent {
            let broadcastStopped = BroadcastingStoppedEvent(
                callCid: event.callCid,
                createdAt: event.createdAt,
                type: event.type
            )
            onBroadcastingEvent?(broadcastStopped)
        }
        onAnyEvent?(event)
        
        return event
    }
    
    private func userResponse(from id: String) -> UserResponse {
        UserResponse(
            createdAt: Date(),
            custom: [:],
            id: id,
            role: "user",
            teams: [],
            updatedAt: Date()
        )
    }
}
