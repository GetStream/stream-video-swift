//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PermissionRequest: @unchecked Sendable, Identifiable {
    public let id: UUID = .init()
    public let permission: String
    public let user: User
    public let requestedAt: Date
    let onReject: (PermissionRequest) -> Void
    
    public func reject() -> Void {
        onReject(self)
    }
}

@MainActor
public class CallState: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo

    /// The id of the current session.
    /// When a call is started, a unique session identifier is assigned to the user in the call.
    @Published public internal(set) var sessionId: String = ""
    @Published public internal(set) var participants = [CallParticipant]()
    @Published public internal(set) var participantsMap = [String: CallParticipant]() {
        didSet { didUpdate(Array(participantsMap.values)) }
    }
    @Published public internal(set) var localParticipant: CallParticipant?
    @Published public internal(set) var dominantSpeaker: CallParticipant?
    @Published public internal(set) var remoteParticipants: [CallParticipant] = []
    @Published public internal(set) var activeSpeakers: [CallParticipant] = []
    @Published public internal(set) var members: [Member] = []
    @Published public internal(set) var screenSharingSession: ScreenSharingSession? = nil {
        didSet {
            let isCurrentUserSharing = screenSharingSession?.participant.id == sessionId
            if isCurrentUserSharing != isCurrentUserScreensharing {
                isCurrentUserScreensharing = isCurrentUserSharing
            }
        }
    }
    @Published public internal(set) var recordingState: RecordingState = .noRecording
    @Published public internal(set) var blockedUserIds: Set<String> = []
    @Published public internal(set) var settings: CallSettingsResponse?
    @Published public internal(set) var ownCapabilities: [OwnCapability] = []
    @Published public internal(set) var capabilitiesByRole: [String: [String]] = [:]
    @Published public internal(set) var backstage: Bool = false
    @Published public internal(set) var broadcasting: Bool = false
    @Published public internal(set) var createdAt: Date = .distantPast {
        didSet { if !isInitialized { isInitialized = true }}
    }
    @Published public internal(set) var updatedAt: Date = .distantPast
    @Published public internal(set) var startsAt: Date?
    @Published public internal(set) var startedAt: Date? {
        didSet {
            setupDurationTimer()
        }
    }
    @Published public internal(set) var endedAt: Date?
    @Published public internal(set) var endedBy: User?
    @Published public internal(set) var custom: [String: RawJSON] = [:]
    @Published public internal(set) var team: String?
    @Published public internal(set) var createdBy: User?
    @Published public internal(set) var ingress: Ingress?
    @Published public internal(set) var permissionRequests: [PermissionRequest] = []
    @Published public internal(set) var transcribing: Bool = false
    @Published public internal(set) var egress: EgressResponse? { didSet { didUpdate(egress) } }
    @Published public internal(set) var session: CallSessionResponse? {
        didSet {
            didUpdate(session)
        }
    }
    @Published public internal(set) var reconnectionStatus = ReconnectionStatus.connected
    @Published public internal(set) var participantCount: UInt32 = 0
    @Published public internal(set) var isInitialized: Bool = false
    @Published public internal(set) var callSettings = CallSettings()
    @Published public internal(set) var isCurrentUserScreensharing: Bool = false
    @Published public internal(set) var duration: TimeInterval = 0
    @Published public internal(set) var statsReport: CallStatsReport?
    
    private var localCallSettingsUpdate = false
    private var durationTimer: Foundation.Timer?
        
    internal func updateState(from event: VideoEvent) {
        switch event {
        case .typeBlockedUserEvent(let event):
            blockUser(id: event.user.id)
        case .typeCallAcceptedEvent(let event):
            update(from: event.call)
        case .typeCallHLSBroadcastingStartedEvent(_):
            self.egress?.broadcasting = true
        case .typeCallHLSBroadcastingStoppedEvent(_):
            self.egress?.broadcasting = false
        case .typeCallCreatedEvent(let event):
            update(from: event.call)
            mergeMembers(event.members)
        case .typeCallEndedEvent(let event):
            update(from: event.call)
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
            if session?.participants.contains(event.participant) == false {
                session?.participants.append(event.participant)
            }
        case .typeCallSessionParticipantLeftEvent(let event):
            session?.participants.removeAll(where: { participant in
                participant == event.participant
            })
        case .typeCallSessionStartedEvent(let event):
            update(from: event.call)
        case .typeCallUpdatedEvent(let event):
            update(from: event.call)
        case .typePermissionRequestEvent(let event):
            addPermissionRequest(user: event.user.toUser, permissions: event.permissions, requestedAt: event.createdAt)
        case .typeUnblockedUserEvent(let event):
            unblockUser(id: event.user.id)
        case .typeUpdatedCallPermissionsEvent(let event):
            updateOwnCapabilities(event)
        case .typeConnectedEvent(_):
            // note: connection events are not relevant for call state sync'ing
            break
        case .typeConnectionErrorEvent(_):
            // note: connection events are not relevant for call state sync'ing
            break
        case .typeCustomVideoEvent(_):
            // note: custom events are exposed via event subscriptions
            break
        case .typeHealthCheckEvent(_):
            // note: health checks are not relevant for call state sync'ing
            break
        case .typeCallUserMuted(_):
            break
        }
    }

    internal func addPermissionRequest(user: User, permissions: [String], requestedAt: Date) {
        let requests = permissions.map {
            PermissionRequest(
                permission: $0,
                user: user,
                requestedAt: requestedAt,
                onReject: self.removePermissionRequest
            )
        }
        permissionRequests.append(contentsOf: requests)
    }

    internal func removePermissionRequest(request: PermissionRequest) {
        permissionRequests = permissionRequests.filter {
            $0.id != request.id
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
        ownCapabilities = response.ownCapabilities
    }

    internal func update(from response: JoinCallResponse) {
        update(from: response.call)
        mergeMembers(response.members)
        ownCapabilities = response.ownCapabilities
    }

    internal func update(from response: GetCallResponse) {
        update(from: response.call)
        mergeMembers(response.members)
        ownCapabilities = response.ownCapabilities
    }

    internal func update(from response: CallStateResponseFields) {
        update(from: response.call)
        mergeMembers(response.members)
        ownCapabilities = response.ownCapabilities
    }

    internal func update(from response: UpdateCallResponse) {
        update(from: response.call)
        mergeMembers(response.members)
        ownCapabilities = response.ownCapabilities
    }

    internal func update(from event: CallCreatedEvent) {
        update(from: event.call)
        mergeMembers(event.members)
    }

    internal func update(from event: CallRingEvent) {
        update(from: event.call)
        mergeMembers(event.members)
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

        let rtmp = RTMP(
            address: response.ingress.rtmp.address,
            streamKey: streamVideo.token.rawValue
        )
        self.ingress = Ingress(rtmp: rtmp)

        if !localCallSettingsUpdate {
            callSettings = response.settings.toCallSettings
        }
    }
    
    internal func update(callSettings: CallSettings) {
        self.callSettings = callSettings
        localCallSettingsUpdate = true
    }
    
    internal func update(statsReport: CallStatsReport?) {
        self.statsReport = statsReport
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
        self.participants = participants.sorted(using: defaultComparators)
        var remoteParticipants: [CallParticipant] = []
        var activeSpeakers: [CallParticipant] = []
        var screenSharingSession: ScreenSharingSession?

        for participant in participants {
            if participant.sessionId == sessionId {
                localParticipant = participant
            } else {
                remoteParticipants.append(participant)
            }

            if participant.isSpeaking {
                activeSpeakers.append(participant)
            }

            if participant.isDominantSpeaker {
                dominantSpeaker = participant
            }

            if let screenshareTrack = participant.screenshareTrack, participant.isScreensharing {
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
    
    private func didUpdate(_ session: CallSessionResponse?) {
        if startedAt != session?.liveStartedAt {
            startedAt = session?.liveStartedAt
        }
        if session?.liveEndedAt != nil {
            resetTimer()
        }
    }
    
    private func setupDurationTimer() {
        resetTimer()
        durationTimer = Foundation.Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            Task {
                await MainActor.run {
                    self.updateDuration()
                }
            }
        })
    }
    
    private func resetTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
    }
    
    @objc private func updateDuration() {
        guard let startedAt else {
            update(duration: 0)
            return
        }
        let timeInterval = Date().timeIntervalSince(startedAt)
        update(duration: timeInterval)
    }
    
    private func update(duration: TimeInterval) {
        if duration != self.duration {
            self.duration = duration
        }
    }
}
