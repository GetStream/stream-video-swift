//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

public struct PermissionRequest: @unchecked Sendable, Identifiable, Equatable {
    public static func == (lhs: PermissionRequest, rhs: PermissionRequest) -> Bool {
        lhs.id == rhs.id
            && lhs.permission == rhs.permission
            && lhs.user == rhs.user
            && lhs.requestedAt == rhs.requestedAt
    }
    
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

public class CallState: ObservableObject {
    @Injected(\.screenProperties) private var screenProperties

    /// The id of the current session.
    /// When a call is started, a unique session identifier is assigned to the user in the call.
    @Published public private(set) var sessionId: String
    @Published public private(set) var participants: [CallParticipant]
    @Published public private(set) var participantsMap: [String: CallParticipant]
    @Published public private(set) var localParticipant: CallParticipant?
    @Published public private(set) var dominantSpeaker: CallParticipant?
    @Published public private(set) var remoteParticipants: [CallParticipant]
    @Published public private(set) var activeSpeakers: [CallParticipant]
    @Published public private(set) var members: [Member]
    @Published public private(set) var screenSharingSession: ScreenSharingSession?

    @Published public private(set) var recordingState: RecordingState
    @Published public private(set) var blockedUserIds: Set<String>
    @Published public private(set) var settings: CallSettingsResponse?
    @Published public private(set) var ownCapabilities: [OwnCapability]

    @Published public private(set) var capabilitiesByRole: [String: [String]]
    @Published public private(set) var backstage: Bool
    @Published public private(set) var broadcasting: Bool
    @Published public private(set) var createdAt: Date

    @Published public private(set) var updatedAt: Date
    @Published public private(set) var startsAt: Date?
    @Published public private(set) var startedAt: Date?

    @Published public private(set) var endedAt: Date?
    @Published public private(set) var endedBy: User?
    @Published public private(set) var custom: [String: RawJSON]
    @Published public private(set) var team: String?
    @Published public private(set) var createdBy: User?
    @Published public private(set) var ingress: Ingress?
    @Published public private(set) var permissionRequests: [PermissionRequest]
    @Published public private(set) var transcribing: Bool
    @Published public private(set) var captioning: Bool
    @Published public private(set) var egress: EgressResponse?
    @Published public private(set) var session: CallSessionResponse?

    @Published public private(set) var reconnectionStatus: ReconnectionStatus
    @Published public private(set) var anonymousParticipantCount: UInt32
    @Published public private(set) var participantCount: UInt32
    @Published public private(set) var isInitialized: Bool
    @Published public private(set) var callSettings: CallSettings

    @Published public private(set) var isCurrentUserScreensharing: Bool
    @Published public private(set) var duration: TimeInterval
    @Published public private(set) var statsReport: CallStatsReport?

    @Published public private(set) var closedCaptions: [CallClosedCaption]

    @Published public private(set) var statsCollectionInterval: Int

    /// A public enum representing the settings for incoming video streams in a WebRTC
    /// session. This enum supports different policies like none, manual, or
    /// disabled, each potentially applying to specific session IDs.
    @Published public private(set) var incomingVideoQualitySettings: IncomingVideoQualitySettings
    
    /// This property holds the error that indicates the user has been disconnected
    /// due to a network-related issue. When the user’s connection is disrupted for longer than the specified
    /// timeout, this error will be set with a relevant error type, such as
    /// `ClientError.NetworkNotAvailable`.
    ///
    /// - SeeAlso: ``ClientError.NetworkNotAvailable`` for the type of error set when a
    ///            disconnection due to network issues occurs.
    @Published public private(set) var disconnectionError: Error?

    private let disposableBag = DisposableBag()

    init(_ store: CallStateStore) {
        sessionId = store.sessionId
        participants = store.participants
        participantsMap = store.participantsMap
        localParticipant = store.localParticipant
        dominantSpeaker = store.dominantSpeaker
        remoteParticipants = store.remoteParticipants
        activeSpeakers = store.activeSpeakers
        members = store.members
        screenSharingSession = store.screenSharingSession
        recordingState = store.recordingState
        blockedUserIds = store.blockedUserIds
        settings = store.settings
        ownCapabilities = store.ownCapabilities
        capabilitiesByRole = store.capabilitiesByRole
        backstage = store.backstage
        broadcasting = store.broadcasting
        createdAt = store.createdAt
        updatedAt = store.updatedAt
        startsAt = store.startsAt
        startedAt = store.startedAt
        endedAt = store.endedAt
        endedBy = store.endedBy
        custom = store.custom
        team = store.team
        createdBy = store.createdBy
        ingress = store.ingress
        permissionRequests = store.permissionRequests
        transcribing = store.transcribing
        captioning = store.captioning
        egress = store.egress
        session = store.session
        reconnectionStatus = store.reconnectionStatus
        anonymousParticipantCount = store.anonymousParticipantCount
        participantCount = store.participantCount
        isInitialized = store.isInitialized
        callSettings = store.callSettings
        isCurrentUserScreensharing = store.isCurrentUserScreensharing
        duration = store.duration
        statsReport = store.statsReport
        closedCaptions = store.closedCaptions
        statsCollectionInterval = store.statsCollectionInterval
        incomingVideoQualitySettings = store.incomingVideoQualitySettings
        disconnectionError = store.disconnectionError

        subscribe(on: store.$sessionId.eraseToAnyPublisher(), keyPath: \.sessionId)
        subscribe(on: store.$participants.eraseToAnyPublisher(), keyPath: \.participants)
        subscribe(on: store.$participantsMap.eraseToAnyPublisher(), keyPath: \.participantsMap)
        subscribe(on: store.$localParticipant.eraseToAnyPublisher(), keyPath: \.localParticipant)
        subscribe(on: store.$dominantSpeaker.eraseToAnyPublisher(), keyPath: \.dominantSpeaker)
        subscribe(on: store.$remoteParticipants.eraseToAnyPublisher(), keyPath: \.remoteParticipants)
        subscribe(on: store.$activeSpeakers.eraseToAnyPublisher(), keyPath: \.activeSpeakers)
        subscribe(on: store.$members.eraseToAnyPublisher(), keyPath: \.members)
        subscribe(on: store.$screenSharingSession.eraseToAnyPublisher(), keyPath: \.screenSharingSession)
        subscribe(on: store.$recordingState.eraseToAnyPublisher(), keyPath: \.recordingState)
        subscribe(on: store.$blockedUserIds.eraseToAnyPublisher(), keyPath: \.blockedUserIds)
        subscribe(on: store.$settings.eraseToAnyPublisher(), keyPath: \.settings)
        subscribe(on: store.$ownCapabilities.eraseToAnyPublisher(), keyPath: \.ownCapabilities)
        subscribe(on: store.$capabilitiesByRole.eraseToAnyPublisher(), keyPath: \.capabilitiesByRole)
        subscribe(on: store.$backstage.eraseToAnyPublisher(), keyPath: \.backstage)
        subscribe(on: store.$broadcasting.eraseToAnyPublisher(), keyPath: \.broadcasting)
        subscribe(on: store.$createdAt.eraseToAnyPublisher(), keyPath: \.createdAt)
        subscribe(on: store.$updatedAt.eraseToAnyPublisher(), keyPath: \.updatedAt)
        subscribe(on: store.$startsAt.eraseToAnyPublisher(), keyPath: \.startsAt)
        subscribe(on: store.$startedAt.eraseToAnyPublisher(), keyPath: \.startedAt)
        subscribe(on: store.$endedAt.eraseToAnyPublisher(), keyPath: \.endedAt)
        subscribe(on: store.$endedBy.eraseToAnyPublisher(), keyPath: \.endedBy)
        subscribe(on: store.$custom.eraseToAnyPublisher(), keyPath: \.custom)
        subscribe(on: store.$team.eraseToAnyPublisher(), keyPath: \.team)
        subscribe(on: store.$createdBy.eraseToAnyPublisher(), keyPath: \.createdBy)
        subscribe(on: store.$ingress.eraseToAnyPublisher(), keyPath: \.ingress)
        subscribe(on: store.$permissionRequests.eraseToAnyPublisher(), keyPath: \.permissionRequests)
        subscribe(on: store.$transcribing.eraseToAnyPublisher(), keyPath: \.transcribing)
        subscribe(on: store.$captioning.eraseToAnyPublisher(), keyPath: \.captioning)
        subscribe(on: store.$egress.eraseToAnyPublisher(), keyPath: \.egress)
        subscribe(on: store.$session.eraseToAnyPublisher(), keyPath: \.session)
        subscribe(on: store.$reconnectionStatus.eraseToAnyPublisher(), keyPath: \.reconnectionStatus)
        subscribe(on: store.$anonymousParticipantCount.eraseToAnyPublisher(), keyPath: \.anonymousParticipantCount)
        subscribe(on: store.$participantCount.eraseToAnyPublisher(), keyPath: \.participantCount)
        subscribe(on: store.$isInitialized.eraseToAnyPublisher(), keyPath: \.isInitialized)
        subscribe(on: store.$callSettings.eraseToAnyPublisher(), keyPath: \.callSettings)
        subscribe(on: store.$isCurrentUserScreensharing.eraseToAnyPublisher(), keyPath: \.isCurrentUserScreensharing)
        subscribe(on: store.$duration.eraseToAnyPublisher(), keyPath: \.duration)
        subscribe(on: store.$statsReport.eraseToAnyPublisher(), keyPath: \.statsReport)
        subscribe(on: store.$closedCaptions.eraseToAnyPublisher(), keyPath: \.closedCaptions)
        subscribe(on: store.$statsCollectionInterval.eraseToAnyPublisher(), keyPath: \.statsCollectionInterval)
        subscribe(on: store.$incomingVideoQualitySettings.eraseToAnyPublisher(), keyPath: \.incomingVideoQualitySettings)
        subscribe(on: store.$disconnectionError.eraseToAnyPublisher(), keyPath: \.disconnectionError)
    }

    private func subscribe<V: Equatable>(
        on publisher: AnyPublisher<V, Never>,
        keyPath: ReferenceWritableKeyPath<CallState, V>
    ) {
        publisher
            .removeDuplicates()
            .debounce(for: .seconds(Int(screenProperties.refreshRate)), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .assign(to: keyPath, onWeak: self)
            .store(in: disposableBag)
    }

    private func subscribe<V>(
        on publisher: AnyPublisher<V, Never>,
        removeDuplicatesBy: @escaping (V, V) -> Bool = { _, _ in false },
        keyPath: ReferenceWritableKeyPath<CallState, V>
    ) {
        publisher
            .removeDuplicates(by: removeDuplicatesBy)
            .debounce(for: .seconds(Int(screenProperties.refreshRate)), scheduler: DispatchQueue.main)
            .receive(on: DispatchQueue.main)
            .assign(to: keyPath, onWeak: self)
            .store(in: disposableBag)
    }
}
