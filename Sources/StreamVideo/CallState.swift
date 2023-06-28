//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public class CallState: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public internal(set) var participants = [String: CallParticipant]() { didSet { didUpdate(Array(participants.values)) } }
    @Published public internal(set) var me: CallParticipant?
    @Published public internal(set) var dominantSpeaker: CallParticipant?
    @Published public internal(set) var remoteParticipants: [CallParticipant] = []
    @Published public internal(set) var activeSpeakers: [CallParticipant] = []
    @Published public internal(set) var members: [Member] = []
    @Published public internal(set) var screenSharingSession: ScreenSharingSession? = nil
    @Published public internal(set) var recordingState: RecordingState = .noRecording
    @Published public internal(set) var blockedUserIds: Set<String> = []
    @Published public internal(set) var settings: CallSettingsResponse?
    @Published public internal(set) var ownCapabilities: [OwnCapability] = []
    @Published public internal(set) var capabilitiesByRole: [String: [String]] = [:]
    @Published public internal(set) var backstage: Bool = false
    @Published public internal(set) var broadcasting: Bool = false
    @Published public internal(set) var createdAt: Date = .distantPast
    @Published public internal(set) var updatedAt: Date = .distantPast
    @Published public internal(set) var startsAt: Date?
    @Published public internal(set) var endedAt: Date?
    @Published public internal(set) var endedBy: User?
    @Published public internal(set) var custom: [String: RawJSON] = [:]
    @Published public internal(set) var team: String?
    @Published public internal(set) var createdBy: User?
    @Published public internal(set) var ingress: CallIngressResponse?

    @Published public internal(set) var transcribing: Bool = false
    @Published public internal(set) var egress: EgressResponse? { didSet { didUpdate(egress) } }
    @Published public internal(set) var session: CallSessionResponse?
    @Published public internal(set) var reconnectionStatus = ReconnectionStatus.connected
    @Published public internal(set) var participantCount: UInt32 = 0
        
    internal func updateState(from event: VideoEvent) {
        switch event {
        case .typeBlockedUserEvent(let event):
            blockUser(id: event.user.id)
        case .typeCallAcceptedEvent(let event):
            update(from: event.call)
        case .typeCallBroadcastingStartedEvent(_):
            self.egress?.broadcasting = true
        case .typeCallBroadcastingStoppedEvent(_):
            self.egress?.broadcasting = false
        case .typeCallCreatedEvent(let event):
            update(from: event.call)
            mergeMembers(event.members)
        case .typeCallEndedEvent(_):
            endedAt = Date()
        case .typeCallLiveStartedEvent(let event):
            update(from: event.call)
        case .typeCallMemberAddedEvent(let event):
            mergeMembers(event.members)
        case .typeCallMemberRemovedEvent(let event):
            let updated = members.filter { !event.members.contains($0.id) }
            self.members = updated
        case .typeCallMemberUpdatedEvent(let event):
            mergeMembers(event.members)
        case .typeCallMemberUpdatedPermissionEvent(let event):
            capabilitiesByRole = event.capabilitiesByRole
            mergeMembers(event.members)
            update(from: event.call)
        case .typeCallNotificationEvent(let event):
            mergeMembers(event.members)
            update(from: event.call)
        case .typeCallReactionEvent(_):
            break
        case .typeCallRecordingStartedEvent(_):
            if recordingState != .recording {
                recordingState = .recording
            }
        case .typeCallRecordingStoppedEvent(_):
            if recordingState != .noRecording {
                recordingState = .noRecording
            }
        case .typeCallRejectedEvent(let event):
            update(from: event.call)
        case .typeCallRingEvent(let event):
            update(from: event.call)
            mergeMembers(event.members)
        case .typeCallSessionEndedEvent(let event):
            update(from: event.call)
        case .typeCallSessionParticipantJoinedEvent(let event):
            if session?.participants.map(\.user).contains(event.user) == false {
                let callParticipant = CallParticipantResponse(
                    joinedAt: Date(),
                    user: event.user
                )
                session?.participants.append(callParticipant)
            }
        case .typeCallSessionParticipantLeftEvent(let event):
            session?.participants.removeAll(where: { participant in
                participant.user == event.user
            })
        case .typeCallSessionStartedEvent(let event):
            update(from: event.call)
        case .typeCallUpdatedEvent(let event):
            update(from: event.call)
        case .typeConnectedEvent(_):
            break
        case .typeConnectionErrorEvent(_):
            break
        case .typeCustomVideoEvent(_):
            break
        case .typeHealthCheckEvent(_):
            break
        case .typePermissionRequestEvent(_):
            break
        case .typeUnblockedUserEvent(let event):
            unblockUser(id: event.user.id)
        case .typeUpdatedCallPermissionsEvent(let event):
            updateOwnCapabilities(event)
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

    internal func update(from response: CallStateResponseFields) {
        update(from: response.call)
        mergeMembers(response.members)
        ownCapabilities = response.ownCapabilities
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

    private func didUpdate(_ participants: [CallParticipant]) {
        var remoteParticipants: [CallParticipant] = []
        var activeSpeakers: [CallParticipant] = []
        var screenSharingSession: ScreenSharingSession?

        for participant in participants {
            if participant.id == streamVideo.user.id {
                me = participant
            } else {
                remoteParticipants.append(participant)
            }

            if participant.isSpeaking {
                activeSpeakers.append(participant)
            }

            if participant.isDominantSpeaker {
                dominantSpeaker = participant
            }

            if let screenshareTrack = participant.screenshareTrack {
                screenSharingSession = .init(track: screenshareTrack, participant: participant)
            }
        }

        self.screenSharingSession = screenSharingSession
        self.remoteParticipants = remoteParticipants
        self.activeSpeakers = activeSpeakers
    }

    private func didUpdate(_ egress: EgressResponse?) {
        self.broadcasting = egress?.broadcasting ?? false
    }
}
