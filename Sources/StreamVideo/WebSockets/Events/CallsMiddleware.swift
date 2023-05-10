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
        if let incomingCallEvent = event as? IncomingCallEvent, incomingCallEvent.ringing {
            log.debug("Received call created \(incomingCallEvent)")
            let cId = incomingCallEvent.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let userId = incomingCallEvent.createdBy
            let type = incomingCallEvent.type
            let incomingCall = IncomingCall(
                id: id,
                callerId: userId,
                type: type,
                participants: incomingCallEvent.users.map { $0.toCallParticipant() }
            )
            onCallEvent?(.incoming(incomingCall))
        } else if let event = event as? CallEventInfo {
            var callEvent: CallEvent
            switch event.action {
            case .accept:
                callEvent = .accepted(event)
            case .reject:
                callEvent = .rejected(event)
            case .cancel:
                callEvent = .canceled(event)
            case .end:
                callEvent = .ended(event)
            case .block:
                callEvent = .userBlocked(event)
            case .unblock:
                callEvent = .userUnblocked(event)
            }
            onCallEvent?(callEvent)
        } else if let event = event as? CallUpdatedEvent {
            let state = event.call.toCallData(
                members: [],
                blockedUsers: event.call.blockedUserIds.map {
                    UserResponse(
                        createdAt: Date(),
                        custom: [:],
                        id: $0,
                        role: "user",
                        teams: [],
                        updatedAt: Date()
                    )
                }
            )
            onCallUpdated?(state)
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
}
