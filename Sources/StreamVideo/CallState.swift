//
//  CallState.swift
//  StreamVideo
//
//  Created by tommaso barbugli on 09/06/2023.
//

import Foundation

// TODO: ingress field is missing
// TODO: settings field is missing
// TODO: session field is missing

public class CallState: ObservableObject {
    @Published public internal(set) var createdAt: Date = .distantPast
    @Published public internal(set) var updatedAt: Date = .distantPast
    @Published public internal(set) var startsAt: Date?
    @Published public internal(set) var endedAt: Date?
    @Published public internal(set) var endedBy: User?
    @Published public internal(set) var createdBy: User?
    @Published public internal(set) var backstage: Bool = false
    @Published public internal(set) var recording: Bool = false
    @Published public internal(set) var transcribing: Bool = false
    @Published public internal(set) var blockedUserIds: Set<String> = []
    @Published public internal(set) var custom : [String: RawJSON] = [:]
    @Published public internal(set) var members : [String: CallMember] = [:]
    @Published public internal(set) var rejectedBy : Set<String> = []
    @Published public internal(set) var acceptedBy : Set<String> = []
    @Published public internal(set) var team : String?
    @Published public internal(set) var ownCapabilities : [OwnCapability] = []
    @Published public internal(set) var capabilitiesByRole : [String: [String]] = [:]

    // TODO: implement this for real :)
    public func hasPermission(_ permission: OwnCapability) -> Bool {
        return false
    }

    public func hasPermission(_ permission: String) -> Bool {
        guard let v = OwnCapability(rawValue: permission) else {
            return false
        }
        return hasPermission(v)
    }

    internal func updateFrom(_ response: GetOrCreateCallResponse) {
        mergeMembers(response.members)
        updateFrom(response.call)
    }
    
    internal func mergeMembers(_ response: [MemberResponse]) {
        // TODO: is this necessary? (cloning objects instead of changing them in-place)
        var newDict = members.mapValues { $0 }
        response.forEach {
            guard let m = newDict[$0.userId] else {
                newDict[$0.userId] = $0.toMember
                return
            }
            if m.updatedAt != $0.updatedAt {
                newDict[$0.userId] = $0.toMember
            }
        }
        members = newDict
    }

    internal func updateFrom(_ response: CallResponse) {
        custom = response.custom
        createdAt = response.createdAt
        updatedAt = response.updatedAt
        startsAt = response.startsAt
        endedAt = response.endedAt
        createdBy = response.createdBy.toUser
        backstage = response.backstage
        recording = response.recording
        transcribing = response.transcribing
        blockedUserIds = Set(response.blockedUserIds.map { $0 })
        team = response.team
    }

    // TODO: ideally this used the VideoEvent type and switch case based on enum
    // cases so that we fail to compile when the code is out of sync with new events
    internal func updateFrom(_ event: WSCallEvent) {
        switch event {
        case let e as BlockedUserEvent:
            blockedUserIds = blockedUserIds.union([e.user.id])
        case let e as CallAcceptedEvent:
            acceptedBy = acceptedBy.union([e.user.id])
        case _ as CallBroadcastingStartedEvent:
            break
        case _ as CallBroadcastingStoppedEvent:
            break
        case _ as CallCreatedEvent:
            break
        case let e as CallEndedEvent:
            endedAt = e.createdAt
            endedBy = e.user?.toUser
        case _ as CallLiveStartedEvent:
            break
        case _ as CallMemberAddedEvent:
            break
        case _ as CallMemberRemovedEvent:
            break
        case _ as CallMemberUpdatedEvent:
            break
        case _ as CallMemberUpdatedPermissionEvent:
            break
        case _ as CallNotificationEvent:
            break
        case _ as CallReactionEvent:
            break
        case _ as CallRecordingStartedEvent:
            break
        case _ as CallRecordingStoppedEvent:
            break
        case let e as CallRejectedEvent:
            rejectedBy = rejectedBy.union([e.user.id])
        case _ as CallRingEvent:
            break
        case _ as CallSessionEndedEvent:
            break
        case _ as CallSessionParticipantJoinedEvent:
            break
        case _ as CallSessionParticipantLeftEvent:
            break
        case _ as CallSessionStartedEvent:
            break
        case let e as CallUpdatedEvent:
            updateFrom(e.call)
        case _ as CustomVideoEvent:
            break
        case _ as PermissionRequestEvent:
            break
        case let e as UnblockedUserEvent:
            blockedUserIds = blockedUserIds.subtracting([e.user.id])
        case _ as UpdatedCallPermissionsEvent:
            break
        default:
            log.warning("event\(event) is not handled in CallState updateFrom(_ event: VideoEvent)")
        }
    }
}
