//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation
import StreamWebRTC

actor WebRTCStateAdapter: ObservableObject {

    enum TrackEntry {
        case audio(id: String, track: RTCAudioTrack)
        case video(id: String, track: RTCVideoTrack)
        case screenShare(id: String, track: RTCVideoTrack)

        var id: String {
            switch self {
            case let .audio(id, _):
                return id
            case let .video(id, _):
                return id
            case let .screenShare(id, _):
                return id
            }
        }
    }

    let user: User
    let apiKey: String
    let callCid: String
    let videoConfig: VideoConfig
    let peerConnectionFactory: PeerConnectionFactory

    @Published private(set) var sessionID: String = ""
    @Published private(set) var token: String = ""
    @Published private(set) var callSettings: CallSettings = .init()
    @Published private(set) var audioSettings: AudioSettings = .init()
    @Published private(set) var videoOptions: VideoOptions = .init() { didSet { didUpdate(videoOptions: videoOptions) } }
    @Published private(set) var connectOptions: ConnectOptions = .init(iceServers: [])
    @Published private(set) var ownCapabilities: Set<OwnCapability> = []

    @Published private(set) var sfuAdapter: SFUAdapter?
    @Published private(set) var publisher: RTCPeerConnectionCoordinator?
    @Published private(set) var subscriber: RTCPeerConnectionCoordinator?
    @Published private(set) var statsReporter: WebRTCStatsReporter?

    @Published private(set) var participants: [String: CallParticipant] = [:]
    @Published private(set) var participantsCount: UInt32 = 0
    @Published private(set) var anonymousCount: UInt32 = 0
    @Published private(set) var participantPins: [PinInfo] = []

    private(set) var initialCallSettings: CallSettings?

    private var audioTracks: [String: RTCAudioTrack] = [:]
    private var videoTracks: [String: RTCVideoTrack] = [:]
    private var screenShareTracks: [String: RTCVideoTrack] = [:]

    private let audioSession: AudioSession = .init()
    private let disposableBag = DisposableBag()

    private lazy var screenShareSessionProvider: ScreenShareSessionProvider = .init()
    private(set) lazy var participantsUpdateSubject = PassthroughSubject<[String: CallParticipant], Never>()

    init(
        user: User,
        apiKey: String,
        callCid: String,
        videoConfig: VideoConfig
    ) {
        self.user = user
        self.apiKey = apiKey
        self.callCid = callCid
        self.videoConfig = videoConfig
        self.peerConnectionFactory = PeerConnectionFactory(
            audioProcessingModule: videoConfig.audioProcessingModule
        )
        let sessionID = UUID().uuidString

        Task { await set(sessionID) }
    }

    func set(_ value: String) { self.sessionID = value }
    func set(_ value: CallSettings) { self.callSettings = value }
    func set(initialCallSettings value: CallSettings?) { self.initialCallSettings = value }
    func set(_ value: AudioSettings) { self.audioSettings = value }
    func set(_ value: VideoOptions) { self.videoOptions = value }
    func set(_ value: ConnectOptions) { self.connectOptions = value }
    func set(_ value: Set<OwnCapability>) { self.ownCapabilities = value }
    func set(_ value: WebRTCStatsReporter) {
        self.statsReporter = value
    }
    func set(sfuAdapter value: SFUAdapter?) {
        self.sfuAdapter = value
        statsReporter?.sfuAdapter = sfuAdapter
    }
    func set(_ value: UInt32) { self.participantsCount = value }
    func set(anonymous value: UInt32) { self.anonymousCount = value }
    func set(_ value: [PinInfo]) { self.participantPins = value }
    func set(token value: String) { self.token = value }

    // MARK: - Session

    func refreshSession() {
        set(UUID().uuidString)
    }

    func configurePeerConnections() async throws {
        guard let sfuAdapter = sfuAdapter else {
            throw ClientError("SFUAdapter hasn't been created.")
        }
        log.debug(
            """
            Setting up PeerConnections with
            sessionId: \(sessionID)
            sfuAdapter: \(sfuAdapter.hostname)
            callSettings
                audioOn: \(callSettings.audioOn)
                videoOn: \(callSettings.videoOn)
            """,
            subsystems: .webRTC
        )

        let publisher = RTCPeerConnectionCoordinator(
            sessionId: sessionID,
            peerType: .publisher,
            peerConnection: try peerConnectionFactory.makePeerConnection(
                configuration: connectOptions.rtcConfiguration,
                constraints: .defaultConstraints,
                delegate: nil
            ),
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )

        let subscriber = RTCPeerConnectionCoordinator(
            sessionId: sessionID,
            peerType: .subscriber,
            peerConnection: try peerConnectionFactory.makePeerConnection(
                configuration: connectOptions.rtcConfiguration,
                constraints: .defaultConstraints,
                delegate: nil
            ),
            peerConnectionFactory: peerConnectionFactory,
            videoOptions: videoOptions,
            videoConfig: videoConfig,
            callSettings: callSettings,
            audioSettings: audioSettings,
            sfuAdapter: sfuAdapter,
            audioSession: audioSession,
            screenShareSessionProvider: screenShareSessionProvider
        )

        publisher
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionPublisher)
            .sinkTask(storeIn: disposableBag) { [weak self] in await self?.peerConnectionReceivedTrackEvent(.publisher, event: $0) }
            .store(in: disposableBag)

        subscriber
            .trackPublisher
            .log(.debug, subsystems: .peerConnectionSubscriber)
            .sinkTask { [weak self] in await self?.peerConnectionReceivedTrackEvent(.subscriber, event: $0) }
            .store(in: disposableBag)

        try await publisher.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )

        try await subscriber.setUp(
            with: callSettings,
            ownCapabilities: Array(
                ownCapabilities
            )
        )

        self.publisher = publisher
        self.subscriber = subscriber
    }

    func cleanUp() async {
        publisher?.close()
        subscriber?.close()
        self.publisher = nil
        self.subscriber = nil
        self.statsReporter = nil
        await sfuAdapter?.disconnect()

        sfuAdapter = nil

        token = ""
        ownCapabilities = []
        participants = [:]
        participantsCount = 0
        participantPins = []

        audioTracks = [:]
        videoTracks = [:]
        screenShareTracks = [:]
    }

    func cleanUpForReconnection() {
        sfuAdapter = nil
        publisher = nil
        subscriber = nil
        statsReporter = nil
        token = ""

        audioTracks = [:]
        videoTracks = [:]
        screenShareTracks = [:]
    }

    func restoreScreenSharing() async throws {
        guard let activeSession = screenShareSessionProvider.activeSession else {
            return
        }
        try await publisher?.beginScreenSharing(
            of: activeSession.screenSharingType,
            ownCapabilities: Array(ownCapabilities)
        )
    }

    // MARK: - Tracks

    func didAddTrack(
        _ track: RTCMediaStreamTrack,
        type: TrackType,
        for id: String
    ) {
        switch type {
        case .audio:
            if let audioTrack = track as? RTCAudioTrack {
                audioTracks[id] = audioTrack
            }

        case .video:
            if let videoTrack = track as? RTCVideoTrack {
                videoTracks[id] = videoTrack
            }

        case .screenshare:
            if let videoTrack = track as? RTCVideoTrack {
                screenShareTracks[id] = videoTrack
            }

        default:
            break
        }

        guard !participants.isEmpty else { return }

        assignTracksToParticipants(
            participants,
            fileName: #file,
            functionName: #function,
            line: #line
        )
    }

    func didRemoveTrack(for id: String) {
        audioTracks[id] = nil
        videoTracks[id] = nil
        screenShareTracks[id] = nil

        guard !participants.isEmpty else { return }

        assignTracksToParticipants(
            participants,
            fileName: #file,
            functionName: #function,
            line: #line
        )
    }

    func track(
        for id: String,
        of trackType: TrackType
    ) -> RTCMediaStreamTrack? {
        switch trackType {
        case .audio:
            return audioTracks[id]
        case .video:
            return videoTracks[id]
        case .screenshare:
            return screenShareTracks[id]
        default:
            return nil
        }
    }

    // MARK: - Private

    private func peerConnectionReceivedTrackEvent(
        _ peerConnectionType: PeerConnectionType,
        event: TrackEvent
    ) {
        switch event {
        case let .added(id, trackType, track):
            didAddTrack(track, type: trackType, for: id)
        case let .removed(id, _, _):
            didRemoveTrack(for: id)
        }
    }

    private func didUpdate(videoOptions: VideoOptions) {
        publisher?.videoOptions = videoOptions
        subscriber?.videoOptions = videoOptions
    }

    func didUpdateParticipants(
        _ participants: [String: CallParticipant],
        fileName: StaticString = #file,
        functionName: StaticString = #function,
        line: UInt = #line
    ) {
        assignTracksToParticipants(
            participants,
            fileName: fileName,
            functionName: functionName,
            line: line
        )
    }

    private func assignTracksToParticipants(
        _ participants: [String: CallParticipant],
        fileName: StaticString,
        functionName: StaticString,
        line: UInt
    ) {
        log.debug(
            """
            Assigning tracks to participants
            ParticipantsCount: \(participants.count)
            AudioTracksCount: \(audioTracks.count)
            VideoTracksCount: \(videoTracks.count)
            ScreenShareTracksCount: \(screenShareTracks.count)
            """,
            subsystems: .webRTC,
            functionName: functionName,
            fileName: fileName,
            lineNumber: line
        )

        var updatedParticipants: [String: CallParticipant] = [:]
        for (key, participant) in participants {
            var updatedParticipant = participant
            let isLocalUser = updatedParticipant.sessionId == sessionID

            let videoTrack: RTCVideoTrack? = {
                if
                    let trackLookupPrefix = updatedParticipant.trackLookupPrefix,
                    let videoTrack = videoTracks[trackLookupPrefix],
                    videoTrack.readyState != .ended {
                    return videoTrack
                } else {
                    return videoTracks[key]
                }
            }()

            if
                let videoTrack = videoTrack,
                updatedParticipant.track == nil || updatedParticipant.track?.readyState == .ended {
                updatedParticipant = updatedParticipant.withUpdated(track: videoTrack)
            } else if videoTrack == nil {
                updatedParticipant = updatedParticipant.withUpdated(track: nil)
            }

            let screenSharingTrack: RTCVideoTrack? = {
                if
                    let trackLookUpPrefix = updatedParticipant.trackLookupPrefix,
                    let screenSharingTrack = screenShareTracks[trackLookUpPrefix] {
                    return screenSharingTrack

                } else if let screenSharingTrack = screenShareTracks[key] {
                    return screenSharingTrack

                } else if
                    isLocalUser,
                    updatedParticipant.isScreensharing,
                    let screenSharingTrack = screenShareTracks[sessionID] {
                    return screenSharingTrack

                } else {
                    return nil
                }
            }()

            if
                let screenSharingTrack,
                updatedParticipant.screenshareTrack == nil || updatedParticipant.screenshareTrack?.readyState == .ended {
                updatedParticipant = updatedParticipant
                    .withUpdated(screensharingTrack: screenSharingTrack)
            } else if screenSharingTrack == nil {
                updatedParticipant = updatedParticipant
                    .withUpdated(screensharingTrack: nil)
            }

            updatedParticipants[key] = updatedParticipant
        }

        let usersWithVideoTracks = updatedParticipants
            .filter { $0.value.track != nil }

        let videoTracksKeys = Set(participants.flatMap { [$0.value.trackLookupPrefix, $0.key].compactMap { $0 } })
        let unusedVideoTracks = videoTracks.filter { !videoTracksKeys.contains($0.key) }

        let usersWithScreenSharingTracks = updatedParticipants
            .filter { $0.value.screenshareTrack != nil }

        log.debug(
            """
            Participants count: \(updatedParticipants.count)

            Participant TrackKeys:
            \(
                participants.map {
                    """
                    Name: \($0.value.name)
                        Id: \($0.key)
                        LookUpPrefix: \($0.value.trackLookupPrefix ?? "-")
                    """
                }
                .joined(separator: "\n")
            )

            Total tracks:
            AudioTracks: \(audioTracks.count)
            VideoTracks: \(videoTracks.count)
            ScreenShareTracks: \(screenShareTracks.count)

            After assigning tracks to participants the following ones have:
            VideoTracks: \(usersWithVideoTracks.map(\.value.name).joined(separator: ","))
            ScreenShareTracks: \(usersWithScreenSharingTracks.map(\.value.name).joined(separator: ","))

            Muted tracks:
            AudioTracks: \(audioTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))
            VideoTracks: \(videoTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))
            ScreenShareTracks: \(screenShareTracks.filter { !$0.value.isEnabled || $0.value.readyState != .live }.map(\.key))

            Unused tracks:
            VideoTracks: \(unusedVideoTracks.count) found with keys: \(unusedVideoTracks.map(\.key).joined(separator: ","))
            """,
            subsystems: .webRTC,
            functionName: functionName,
            fileName: fileName,
            lineNumber: line
        )

        self.participants = updatedParticipants
    }
}

extension AudioSettings {
    init() {
        accessRequestEnabled = false
        defaultDevice = .unknown
        micDefaultOn = false
        noiseCancellation = nil
        opusDtxEnabled = false
        redundantCodingEnabled = false
        speakerDefaultOn = false
    }
}
