//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class CallEventsHandler {
    
    public init() {}
        
    public func checkForCallEvents(from event: Event) -> CallEvent? {
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
            return .incoming(incomingCall)
        } else if let event = event as? CallAcceptedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .accept
            )
            return .accepted(callEventInfo)
        } else if let event = event as? CallRejectedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .reject
            )
            return .rejected(callEventInfo)
        } else if let event = event as? CallEndedEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user?.toUser,
                action: .end
            )
            return .ended(callEventInfo)
        } else if let event = event as? BlockedUserEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .block
            )
            return .userBlocked(callEventInfo)
        } else if let event = event as? UnblockedUserEvent {
            let callEventInfo = CallEventInfo(
                callCid: event.callCid,
                user: event.user.toUser,
                action: .unblock
            )
            return .userUnblocked(callEventInfo)
        } else if let event = event as? CallSessionStartedEvent,
                    let session = event.call.session {
            return .sessionStarted(session)
        }
        
        return nil
    }
    
    public func checkForParticipantEvents(from event: Event) -> ParticipantEvent? {
        if let event = event as? CallSessionParticipantJoinedEvent {
            return ParticipantEvent(
                id: event.user.id,
                action: .join,
                user: event.user.name ?? event.user.id,
                imageURL: URL(string: event.user.image ?? "")
            )
        } else if let event = event as? CallSessionParticipantLeftEvent {
            return ParticipantEvent(
                id: event.user.id,
                action: .leave,
                user: event.user.name ?? event.user.id,
                imageURL: URL(string: event.user.image ?? "")
            )
        }
        
        return nil
    }
}
