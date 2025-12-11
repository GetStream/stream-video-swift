//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
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
            /// When screensharingSession is non-nil we need to ensure that the track is also enabled.
            /// Otherwise, we can get in a situation where a track which was shared previously,
            /// was disabled (due to PiP) and that will cause the track not showing on UI.
            /// Forcing it here to be enabled, should mitigate this issue and ensure that the track is always
            /// visible whenever screensharingSession is non-nil.
            screenSharingSession?.track?.isEnabled = true
            if isCurrentUserSharing != isCurrentUserScreensharing {
                isCurrentUserScreensharing = isCurrentUserSharing
            }
        }
    }

    @Published public internal(set) var recordingState: RecordingState = .noRecording
    @Published public internal(set) var blockedUserIds: Set<String> = []
    @Published public internal(set) var settings: CallSettingsResponse?
    @Published public internal(set) var ownCapabilities: [OwnCapability] = [] {
        didSet {
            let oldValue = Set(oldValue)
            let newValue = Set(ownCapabilities)
            guard newValue != oldValue else {
                return
            }
            log.debug(
                """
                Updating ownCapabilities:
                From:
                \(oldValue.map(\.rawValue))
                
                To:
                \(ownCapabilities.map(\.rawValue))
                """,
                subsystems: .webRTC
            )
        }
    }

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
    @Published public internal(set) var captioning: Bool = false
    @Published public internal(set) var egress: EgressResponse? { didSet { didUpdate(egress) } }
    @Published public internal(set) var session: CallSessionResponse? {
        didSet {
            didUpdate(session)
        }
    }

    @Published public internal(set) var reconnectionStatus = ReconnectionStatus.connected
    @Published public internal(set) var anonymousParticipantCount: UInt32 = 0
    @Published public internal(set) var participantCount: UInt32 = 0
    @Published public internal(set) var isInitialized: Bool = false
    @Published public internal(set) var callSettings: CallSettings = .default

    @Published public internal(set) var isCurrentUserScreensharing: Bool = false
    @Published public internal(set) var duration: TimeInterval = 0
    @Published public internal(set) var statsReport: CallStatsReport?

    @Published public internal(set) var closedCaptions: [CallClosedCaption] = []

    @Published public internal(set) var statsCollectionInterval: Int = 0

    /// A public enum representing the settings for incoming video streams in a WebRTC
    /// session. This enum supports different policies like none, manual, or
    /// disabled, each potentially applying to specific session IDs.
    @Published public internal(set) var incomingVideoQualitySettings: IncomingVideoQualitySettings = .none
    
    /// This property holds the error that indicates the user has been disconnected
    /// due to a network-related issue. When the user’s connection is disrupted for longer than the specified
    /// timeout, this error will be set with a relevant error type, such as
    /// `ClientError.NetworkNotAvailable`.
    ///
    /// - SeeAlso: ``ClientError.NetworkNotAvailable`` for the type of error set when a
    ///            disconnection due to network issues occurs.
    @Published public internal(set) var disconnectionError: Error?
    
    var sortComparators = defaultSortPreset {
        didSet {
            Task(disposableBag: disposableBag) { @MainActor [weak self] in
                guard let self else {
                    return
                }
                didUpdate(participants)
            }
        }
    }

    /// Describes the source from which the join action was triggered for this call.
    ///
    /// Use this property to determine whether the current call was joined from
    /// the app's UI or via a system-level integration such as CallKit. This can
    /// help customize logic, analytics, and UI based on how the call was started.
    var joinSource: JoinSource?

    private var localCallSettingsUpdate = false
    private var durationCancellable: AnyCancellable?
    private nonisolated let disposableBag = DisposableBag()

    /// We mark this one as `nonisolated` to allow us to initialise a state instance without isolation.
    /// That's a safe operation because `MainActor` is only required to ensure that all `@Published`
    /// properties, will publish changes on the main thread.
    nonisolated init() {}

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
            if let index = session?.participants.firstIndex(where: {
                $0.userSessionId == event.participant.userSessionId
            }), index < (session?.participants.count ?? 0) {
                session?.participants[index] = event.participant
            } else {
                session?.participants.append(event.participant)
            }
        case let .typeCallSessionParticipantLeftEvent(event):
            session?.participants.removeAll(where: { participant in
                participant.userSessionId == event.participant.userSessionId
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
        case .typeCallUserMutedEvent:
            break
        case .typeCallDeletedEvent:
            break
        case .typeCallHLSBroadcastingFailedEvent:
            break
        case .typeCallRecordingFailedEvent:
            recordingState = .noRecording
        case .typeCallRecordingReadyEvent:
            break
        case .typeClosedCaptionEvent:
            break
        case .typeCallTranscriptionReadyEvent:
            break
        case .typeCallTranscriptionFailedEvent:
            transcribing = false
        case .typeCallTranscriptionStartedEvent:
            transcribing = true
        case .typeCallTranscriptionStoppedEvent:
            transcribing = false
        case .typeCallMissedEvent:
            break
        case .typeCallRtmpBroadcastStartedEvent:
            broadcasting = true
        case .typeCallRtmpBroadcastStoppedEvent:
            broadcasting = false
        case .typeCallRtmpBroadcastFailedEvent:
            broadcasting = false
        case .typeCallSessionParticipantCountsUpdatedEvent:
            break
        case .typeUserUpdatedEvent:
            break
        case .typeCallClosedCaptionsFailedEvent:
            captioning = false
        case .typeCallClosedCaptionsStartedEvent:
            captioning = true
        case .typeCallClosedCaptionsStoppedEvent:
            captioning = false
        case .typeAppUpdatedEvent:
            break
        case .typeCallFrameRecordingFailedEvent:
            break
        case .typeCallFrameRecordingFrameReadyEvent:
            break
        case .typeCallFrameRecordingStartedEvent:
            break
        case .typeCallFrameRecordingStoppedEvent:
            break
        case .typeKickedUserEvent:
            break
        case .typeCallStatsReportReadyEvent:
            break
        case .typeCallUserFeedbackSubmittedEvent:
            break
        case .typeCallModerationBlurEvent:
            break
        case .typeCallModerationWarningEvent:
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
        statsCollectionInterval = response.statsOptions.reportingIntervalMs / 1000
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
        captioning = response.captioning
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
            // All CallSettings updates go through the update method to ensure
            // proper propagation.
            update(callSettings: .init(response.settings))
        }
    }
    
    internal func update(callSettings: CallSettings) {
        guard callSettings != self.callSettings else {
            localCallSettingsUpdate = true
            return
        }
        self.callSettings = callSettings
        localCallSettingsUpdate = true
    }
    
    internal func update(statsReport: CallStatsReport?) {
        self.statsReport = statsReport
    }

    internal func update(closedCaptions: [CallClosedCaption]) {
        self.closedCaptions = closedCaptions
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
        .sorted(by: sortComparators)
        
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
        guard let session else { return }
        if let startedAt = session.startedAt {
            self.startedAt = startedAt
        } else if let liveStartedAt = session.liveStartedAt {
            startedAt = liveStartedAt
        } else if startedAt == nil {
            /// If we don't receive a value from the SFU we start the timer on the current date.
            startedAt = Date()
        }
        
        if session.liveEndedAt != nil {
            resetTimer()
        }
    }
    
    private func setupDurationTimer() {
        resetTimer()
        durationCancellable = DefaultTimer
            .publish(every: 1.0)
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] _ in
                if let startedAt = self?.startedAt {
                    return Date().timeIntervalSince(startedAt)
                } else {
                    return 0
                }
            }
            .assign(to: \.duration, onWeak: self)
    }
    
    private func resetTimer() {
        durationCancellable?.cancel()
        durationCancellable = nil
    }
}
