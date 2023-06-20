//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class CallEventsHandler {
    
    public init() {}
        
    public func checkForCallEvents(from event: VideoEvent) -> CallEvent? {
        switch event {
        case .typeBlockedUserEvent(let blockedUserEvent):
            let callEventInfo = CallEventInfo(
                callCid: blockedUserEvent.callCid,
                user: blockedUserEvent.user.toUser,
                action: .block
            )
            return .userBlocked(callEventInfo)
        case .typeCallAcceptedEvent(let callAcceptedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callAcceptedEvent.callCid,
                user: callAcceptedEvent.user.toUser,
                action: .accept
            )
            return .accepted(callEventInfo)
        case .typeCallEndedEvent(let callEndedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callEndedEvent.callCid,
                user: callEndedEvent.user?.toUser,
                action: .end
            )
            return .ended(callEventInfo)
        case .typeCallRejectedEvent(let callRejectedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callRejectedEvent.callCid,
                user: callRejectedEvent.user.toUser,
                action: .reject
            )
            return .rejected(callEventInfo)
        case .typeCallRingEvent(let ringEvent):
            log.debug("Received ring event \(ringEvent)")
            let cId = ringEvent.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let caller = ringEvent.call.createdBy.toUser
            let type = ringEvent.call.type
            let incomingCall = IncomingCall(
                id: id,
                caller: caller,
                type: type,
                // TODO: use helper to map to members + why do we call this participants?
                participants: ringEvent.members.map {
                    let user = $0.user.toUser
                    let member = Member(
                        user: user,
                        role: $0.role ?? $0.user.role,
                        customData: $0.custom,
                        updatedAt: $0.updatedAt
                    )
                    return member
                },
                timeout: TimeInterval(ringEvent.call.settings.ring.autoCancelTimeoutMs / 1000)
            )
            return .incoming(incomingCall)
        case .typeCallSessionStartedEvent(let callSessionStartedEvent):
            if let session = callSessionStartedEvent.call.session {
                return .sessionStarted(session)
            } else {
                return nil
            }
        case .typeUnblockedUserEvent(let unblockedUserEvent):
            let callEventInfo = CallEventInfo(
                callCid: unblockedUserEvent.callCid,
                user: unblockedUserEvent.user.toUser,
                action: .unblock
            )
            return .userUnblocked(callEventInfo)
        default:
            return nil
        }
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
