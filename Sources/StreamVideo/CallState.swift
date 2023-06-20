//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class CallState: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public internal(set) var createdAt: Date = .distantPast
    @Published public internal(set) var updatedAt: Date = .distantPast
    @Published public internal(set) var startsAt: Date?
    @Published public internal(set) var endedAt: Date?
    @Published public internal(set) var endedBy: User?
    @Published public internal(set) var createdBy: User?
    @Published public internal(set) var backstage: Bool = false
    @Published public internal(set) var transcribing: Bool = false
    @Published public internal(set) var blockedUserIds: Set<String> = []
    @Published public internal(set) var custom: [String: RawJSON] = [:]
    @Published public internal(set) var members: [Member] = []
    @Published public internal(set) var team: String?
    @Published public internal(set) var ownCapabilities: [OwnCapability] = []
    @Published public internal(set) var capabilitiesByRole: [String: [String]] = [:]
    @Published public internal(set) var ingress: CallIngressResponse?
    @Published public internal(set) var egress: EgressResponse?    
    @Published public internal(set) var settings: CallSettingsResponse?
    @Published public internal(set) var session: CallSessionResponse?
    @Published public internal(set) var participants = [String: CallParticipant]()
    @Published public internal(set) var reconnectionStatus = ReconnectionStatus.connected
    @Published public internal(set) var recordingState: RecordingState = .noRecording
    @Published public internal(set) var participantCount: UInt32 = 0
        
    internal func updateState(from event: Event) {
        if let event = event as? CallAcceptedEvent {
            update(from: event.call)
        } else if let event = event as? CallRejectedEvent {
            update(from: event.call)
        } else if let event = event as? CallUpdatedEvent {
            update(from: event.call)
        } else if event is CallRecordingStartedEvent {
            if recordingState != .recording {
                recordingState = .recording
            }
        } else if event is CallRecordingStoppedEvent {
            if recordingState != .noRecording {
                recordingState = .noRecording
            }
        } else if let event = event as? UpdatedCallPermissionsEvent {
            updateOwnCapabilities(event)
        } else if let event = event as? CallMemberAddedEvent {
            mergeMembers(event.members)
        } else if let event = event as? CallMemberRemovedEvent {
            let updated = members.filter { !event.members.contains($0.id) }
            self.members = updated
        } else if let event = event as? CallMemberUpdatedEvent {
            mergeMembers(event.members)
        } else if let event = event as? BlockedUserEvent {
            blockUser(id: event.user.id)
        } else if let event = event as? UnblockedUserEvent {
            unblockUser(id: event.user.id)
        }
    }
    
    internal func blockUser(id: String) {
        if !blockedUserIds.contains(id) {
            blockedUserIds.insert(id)
        }
    }

    internal func unblockUser(id: String) {
        blockedUserIds.remove(id)
    }

    internal func mergeMembers(_ response: [MemberResponse]) {
        var current = members
        var changed = false
        let membersDict = Dictionary(uniqueKeysWithValues: members.lazy.map { ($0.id, $0) })
        response.forEach {
            guard let m = membersDict[$0.userId] else {
                current.insert($0.toMember, at: 0)
                changed = true
                return
            }
            if m.updatedAt != $0.updatedAt {
                if let index = members.firstIndex(where: { $0.id == m.id }) {
                    current[index] = $0.toMember
                }
                changed = true
            }
        }
        if changed {
            members = current
        }
    }

    internal func update(from response: GetOrCreateCallResponse) {
        update(from: response.call)
        mergeMembers(response.members)
    }

    internal func update(from response: CallResponse) {
        custom = response.custom
        createdAt = response.createdAt
        updatedAt = response.updatedAt
        startsAt = response.startsAt
        endedAt = response.endedAt
        createdBy = response.createdBy.toUser
        backstage = response.backstage
        recordingState = response.recording ? .recording : .noRecording
        transcribing = response.transcribing
        blockedUserIds = Set(response.blockedUserIds.map { $0 })
        team = response.team
        session = response.session
        settings = response.settings
        egress = response.egress
    }
    
    private func updateOwnCapabilities(_ event: UpdatedCallPermissionsEvent) {
        guard
            event.user.id == streamVideo.user.id
        else {
            return
        }
        self.ownCapabilities = event.ownCapabilities
    }
    
}
