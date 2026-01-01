//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

public class CallEventsHandler {
    
    public init() {}
        
    public func checkForCallEvents(from event: VideoEvent) -> CallEvent? {
        switch event {
        case let .typeBlockedUserEvent(blockedUserEvent):
            let callEventInfo = CallEventInfo(
                callCid: blockedUserEvent.callCid,
                user: blockedUserEvent.user.toUser,
                action: .block
            )
            return .userBlocked(callEventInfo)
        case let .typeCallAcceptedEvent(callAcceptedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callAcceptedEvent.callCid,
                user: callAcceptedEvent.user.toUser,
                action: .accept
            )
            return .accepted(callEventInfo)
        case let .typeCallEndedEvent(callEndedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callEndedEvent.callCid,
                user: callEndedEvent.user?.toUser,
                action: .end
            )
            return .ended(callEventInfo)
        case let .typeCallRejectedEvent(callRejectedEvent):
            let callEventInfo = CallEventInfo(
                callCid: callRejectedEvent.callCid,
                user: callRejectedEvent.user.toUser,
                action: .reject
            )
            return .rejected(callEventInfo)
        case let .typeCallRingEvent(ringEvent):
            log.debug("Received ring event \(ringEvent)")
            let cId = ringEvent.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let caller = ringEvent.call.createdBy.toUser
            let type = ringEvent.call.type
            var members = ringEvent.members.map(\.member)
            let callerMember = Member(user: caller)
            if !members.contains(callerMember) {
                members.append(callerMember)
            }
            let incomingCall = IncomingCall(
                id: id,
                caller: caller,
                type: type,
                members: members,
                timeout: TimeInterval(ringEvent.call.settings.ring.autoCancelTimeoutMs / 1000),
                video: ringEvent.video,
                custom: ringEvent.call.custom
            )
            return .incoming(incomingCall)
        case let .typeCallSessionStartedEvent(callSessionStartedEvent):
            if let session = callSessionStartedEvent.call.session {
                return .sessionStarted(session)
            } else {
                return nil
            }
        case let .typeUnblockedUserEvent(unblockedUserEvent):
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
    
    public func checkForParticipantEvents(from event: VideoEvent) -> ParticipantEvent? {
        switch event {
        case let .typeCallSessionParticipantJoinedEvent(event):
            return ParticipantEvent(
                id: event.participant.user.id,
                callCid: event.callCid,
                action: .join,
                user: event.participant.user.name ?? event.participant.user.id,
                imageURL: URL(string: event.participant.user.image ?? "")
            )
        case let .typeCallSessionParticipantLeftEvent(event):
            return ParticipantEvent(
                id: event.participant.user.id,
                callCid: event.callCid,
                action: .leave,
                user: event.participant.user.name ?? event.participant.user.id,
                imageURL: URL(string: event.participant.user.image ?? "")
            )
        default:
            return nil
        }
    }
}

extension MemberResponse {

    var member: Member {
        let user = user.toUser
        return Member(
            user: user,
            role: role ?? user.role,
            customData: custom,
            updatedAt: updatedAt
        )
    }
}
