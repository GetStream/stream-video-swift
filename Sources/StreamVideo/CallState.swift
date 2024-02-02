//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PermissionRequest: @unchecked Sendable, Identifiable {
    public let id: UUID = .init()
    public let permission: String
    public let user: User
    public let requestedAt: Date
    let onReject: (PermissionRequest) -> Void
    
    public init(
        permission: String,
        user: User,
        requestedAt: Date,
        onReject: @escaping (PermissionRequest) -> Void = { _ in }
    ) {
        self.permission = permission
        self.user = user
        self.requestedAt = requestedAt
        self.onReject = onReject
    }

    public func reject() {
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
        case let .typeBlockedUserEvent(event):
            blockUser(id: event.user.id)
        case let .typeCallAcceptedEvent(event):
            update(from: event.call)
        case .typeCallHLSBroadcastingStartedEvent:
            egress?.broadcasting = true
        case .typeCallHLSBroadcastingStoppedEvent:
            egress?.broadcasting = false
        case let .typeCallCreatedEvent(event):
            update(from: event.call)
            mergeMembers(event.members)
        case let .typeCallEndedEvent(event):
            update(from: event.call)
        case let .typeCallLiveStartedEvent(event):
            update(from: event.call)
        case let .typeCallMemberAddedEvent(event):
            mergeMembers(event.members)
        case let .typeCallMemberRemovedEvent(event):
            let updated = members.filter { !event.members.contains($0.id) }
            members = updated
        case let .typeCallMemberUpdatedEvent(event):
            mergeMembers(event.members)
        case let .typeCallMemberUpdatedPermissionEvent(event):
            capabilitiesByRole = event.capabilitiesByRole
            mergeMembers(event.members)
            update(from: event.call)
        case let .typeCallNotificationEvent(event):
            mergeMembers(event.members)
            update(from: event.call)
        case .typeCallReactionEvent:
            break
        case .typeCallRecordingStartedEvent:
            if recordingState != .recording {
                recordingState = .recording
            }
        case .typeCallRecordingStoppedEvent:
            if recordingState != .noRecording {
                recordingState = .noRecording
            }
        case let .typeCallRejectedEvent(event):
            update(from: event.call)
        case let .typeCallRingEvent(event):
            update(from: event.call)
            mergeMembers(event.members)
        case let .typeCallSessionEndedEvent(event):
            update(from: event.call)
        case let .typeCallSessionParticipantJoinedEvent(event):
            if session?.participants.contains(event.participant) == false {
                session?.participants.append(event.participant)
            }
        case let .typeCallSessionParticipantLeftEvent(event):
            session?.participants.removeAll(where: { participant in
                participant == event.participant
            })
        case let .typeCallSessionStartedEvent(event):
            update(from: event.call)
        case let .typeCallUpdatedEvent(event):
            update(from: event.call)
        case let .typePermissionRequestEvent(event):
            addPermissionRequest(user: event.user.toUser, permissions: event.permissions, requestedAt: event.createdAt)
        case let .typeUnblockedUserEvent(event):
            unblockUser(id: event.user.id)
        case let .typeUpdatedCallPermissionsEvent(event):
            updateOwnCapabilities(event)
        case .typeConnectedEvent:
            // note: connection events are not relevant for call state sync'ing
            break
        case .typeConnectionErrorEvent:
            // note: connection events are not relevant for call state sync'ing
            break
        case .typeCustomVideoEvent:
            // note: custom events are exposed via event subscriptions
            break
        case .typeHealthCheckEvent:
            // note: health checks are not relevant for call state sync'ing
            break
        case .typeCallUserMuted:
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
        ingress = Ingress(rtmp: rtmp)

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
        ownCapabilities = event.ownCapabilities
    }

    private func didUpdate(_ newParticipants: [CallParticipant]) {
        // Combine existing and newly added participants.
        let currentParticipantIds = Set(participants.map(\.id))
        let newlyAddedParticipants = Set(newParticipants.map(\.id))
            .subtracting(currentParticipantIds)
            .compactMap { participantsMap[$0] }

        // Sort the updated participants.
        let updatedCurrentParticipants: [CallParticipant] = (
            participants
                .compactMap { participantsMap[$0.id] } + newlyAddedParticipants
        )
        .sorted(by: defaultComparators)

        // Variables to hold segregated participants.
        var remoteParticipants: [CallParticipant] = []
        var activeSpeakers: [CallParticipant] = []
        var screenSharingSession: ScreenSharingSession?

        // Segregate participants based on conditions.
        for participant in updatedCurrentParticipants {
            // Check if participant is local or remote.
            if participant.sessionId == sessionId {
                localParticipant = participant
            } else {
                remoteParticipants.append(participant)
            }

            // Check if participant is speaking.
            if participant.isSpeaking {
                activeSpeakers.append(participant)
            }

            // Check if participant is a dominant speaker.
            if participant.isDominantSpeaker {
                dominantSpeaker = participant
            }

            // Check if participant is sharing their screen.
            if let screenshareTrack = participant.screenshareTrack, participant.isScreensharing {
                screenSharingSession = .init(track: screenshareTrack, participant: participant)
            }
        }

        // Update the respective class properties.
        participants = updatedCurrentParticipants
        self.screenSharingSession = screenSharingSession
        self.remoteParticipants = remoteParticipants
        self.activeSpeakers = activeSpeakers
    }

    private func didUpdate(_ egress: EgressResponse?) {
        broadcasting = egress?.broadcasting ?? false
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
