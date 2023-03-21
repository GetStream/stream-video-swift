//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI
import WebRTC

// View model that provides methods for views that present a call.
@MainActor
open class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    /// Provides access to the current call.
    @Published public var call: Call? {
        didSet {
            participantUpdates = call?.$participants
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] participants in
                    self?.callParticipants = participants
            })
            callUpdates = call?.$callInfo
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] callInfo in
                    self?.blockedUsers = callInfo.blockedUsers
            })
            recordingUpdates = call?.$recordingState
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] newState in
                    self?.recordingState = newState
            })
            reconnectionUpdates = call?.$reconnecting
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] reconnecting in
                    if reconnecting {
                        if self?.callingState != .reconnecting {
                            self?.callingState = .reconnecting
                        }
                    } else {
                        if self?.callingState != .inCall {
                            self?.callingState = .inCall
                        }
                    }
                })
        }
    }
    
    /// Tracks the current state of a call. It should be used to show different UI in your views.
    @Published public var callingState: CallingState = .idle {
        didSet {
            if callingState == .idle {
                edgeServer = nil
            }
            handleRingingEvents()
        }
    }
    
    /// Optional, has a value if there was an error. You can use it to display more detailed error messages to the users.
    public var error: Error? {
        didSet {
            errorAlertShown = error != nil
        }
    }
    
    /// If the `error` property has a value, it's true. You can use it to control the visibility of an alert presented to the user.
    @Published public var errorAlertShown = false
       
    /// Whether the list of participants is shown during the call.
    @Published public var participantsShown = false
        
    /// List of the outgoing call members.
    @Published public var outgoingCallMembers = [User]()
    
    /// Dictionary of the call participants.
    @Published public var callParticipants = [String: CallParticipant]() {
        didSet {
            log.debug("Call participants updated")
            updateCallStateIfNeeded()
            checkForScreensharingSession()
            checkCallSettingsForCurrentUser()
        }
    }
    
    /// Contains info about a participant event. It's reset to nil after 2 seconds.
    @Published public var participantEvent: ParticipantEvent?
    
    /// Provides information about the current call settings, such as the camera position and whether there's an audio and video turned on.
    @Published public var callSettings = CallSettings()
    
    /// Whether the call is in minimized mode.
    @Published public var isMinimized = false
    
    /// `false` by default. It becomes `true` when the current user's local video is shown as a primary view.
    @Published public var localVideoPrimary = false
    
    /// Optional property about the ongoing screensharing session (if any).
    @Published public var screensharingSession: ScreensharingSession?
    
    /// Whether the UI elements, such as the call controls should be hidden (for example while screensharing).
    @Published public var hideUIElements = false
    
    /// The current edge server. Can be used in the lobby view.
    @Published public private(set) var edgeServer: EdgeServer?
    
    /// A list of the blocked users in the call.
    @Published public var blockedUsers = [User]()
    
    /// The current recording state of the call.
    @Published public var recordingState: RecordingState = .noRecording
    
    /// Returns the local participant of the call.
    public var localParticipant: CallParticipant? {
        callParticipants.first(where: { (_, value) in
            value.id == call?.sessionId
        })
            .map { $1 }
    }
    
    public var videoOptions = VideoOptions()
            
    private var participantUpdates: AnyCancellable?
    private var callUpdates: AnyCancellable?
    private var reconnectionUpdates: AnyCancellable?
    private var recordingUpdates: AnyCancellable?
    private var currentEventsTask: Task<Void, Never>?
    
    private var callController: CallController?
    
    private var ringingTimer: Foundation.Timer?
    
    public var participants: [CallParticipant] {
        callParticipants
            .filter { $0.value.id != call?.sessionId }
            .map(\.value)
            .sorted(by: { $0.id < $1.id })
    }
    
    private var ringingSupported: Bool = false
    
    public init(listenToRingingEvents: Bool = false) {
        ringingSupported = listenToRingingEvents
        if !streamVideo.videoConfig.videoEnabled {
            callSettings = CallSettings(speakerOn: false)
        }
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkForOngoingCall),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        subscribeToCallEvents()
    }
    
    public func setCallController(_ callController: CallController) {
        self.callController = callController
        call = callController.call
        callingState = .inCall
    }

    /// Toggles the state of the camera (visible vs non-visible).
    public func toggleCameraEnabled() {
        guard let callController = callController else {
            return
        }
        Task {
            do {
                let isEnabled = !callSettings.videoOn
                try await callController.changeVideoState(isEnabled: isEnabled)
                callSettings = CallSettings(
                    audioOn: callSettings.audioOn,
                    videoOn: isEnabled,
                    speakerOn: callSettings.speakerOn,
                    audioOutputOn: callSettings.audioOutputOn
                )
            } catch {
                log.error("Error toggling camera")
            }
        }
    }
    
    /// Toggles the state of the microphone (muted vs unmuted).
    public func toggleMicrophoneEnabled() {
        guard let callController = callController else {
            return
        }
        Task {
            do {
                let isEnabled = !callSettings.audioOn
                try await callController.changeAudioState(isEnabled: isEnabled)
                callSettings = CallSettings(
                    audioOn: isEnabled,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn,
                    audioOutputOn: callSettings.audioOutputOn
                )
            } catch {
                log.error("Error toggling microphone")
            }
        }
    }
    
    /// Toggles the camera position (front vs back).
    public func toggleCameraPosition() {
        guard let callController = callController else {
            return
        }
        let next = callSettings.cameraPosition.next()
        callController.changeCameraMode(position: next) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.callSettings = self.callSettings.withUpdatedCameraPosition(next)
            }
        }
    }
    
    /// Enables or disables the audio output.
    public func toggleAudioOutput() {
        guard let callController = callController else {
            return
        }
        Task {
            do {
                let isEnabled = !callSettings.audioOutputOn
                try await callController.changeSoundState(isEnabled: isEnabled)
                callSettings = CallSettings(
                    audioOn: callSettings.audioOutputOn,
                    videoOn: callSettings.videoOn,
                    speakerOn: callSettings.speakerOn,
                    audioOutputOn: isEnabled
                )
            } catch {
                log.error("Error toggling audio output")
            }
        }
    }

    /// Starts a call with the provided info.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: the type of the call.
    ///  - participants: list of participants that are part of the call.
    ///  - ring: whether the call should ring.
    public func startCall(callId: String, type: String, participants: [User], ring: Bool = false) {
        outgoingCallMembers = participants
        ringingSupported = ring
        setupCallController(callId: callId, type: type)
        callingState = .outgoing
        let callType = callType(from: type)
        enterCall(callId: callId, callType: callType, participants: participants, ring: ring)
    }
    
    /// Joins an existing call with the provided info.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: optional type of a call. If not provided, the default would be used.
    public func joinCall(callId: String, type: String) {
        setupCallController(callId: callId, type: type)
        let callType = callType(from: type)
        enterCall(callId: callId, callType: callType, participants: [])
    }
    
    /// Enters into a lobby before joining a call.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: the type of the call.
    ///  - participants: list of participants that are part of the call.
    public func enterLobby(callId: String, type: String, participants: [User]) {
        let callType = callType(from: type)
        let lobbyInfo = LobbyInfo(callId: callId, callType: callType, participants: participants)
        callingState = .lobby(lobbyInfo)
        setupCallController(callId: callId, type: type)
        Task {
            self.edgeServer = try await callController?.selectEdgeServer(
                videoOptions: VideoOptions(),
                participants: participants
            )
        }
    }
    
    /// Joins a call from the lobby. `enterLobby` needs to be called first.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: the type of the call.
    ///  - participants: list of participants that are part of the call.
    public func joinCallFromLobby(callId: String, type: String, participants: [User]) throws {
        guard let edgeServer = edgeServer, let callController = callController else {
            throw ClientError.Unexpected("Edge server not available")
        }
        
        Task {
            do {
                log.debug("Starting call")
                let call: Call = try await callController.joinCall(
                    on: edgeServer,
                    callType: callType(from: type),
                    callId: callId,
                    callSettings: callSettings,
                    videoOptions: VideoOptions()
                )
                save(call: call)
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                self.error = error
                callingState = .idle
            }
        }
    }
    
    /// Accepts the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func acceptCall(callId: String, type: String) {
        let callType = callType(from: type)
        setupCallController(callId: callId, type: type)
        Task {
            try await streamVideo.acceptCall(callId: callId, callType: callType)
            enterCall(callId: callId, callType: callType, participants: [])
        }
    }
    
    /// Rejects the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func rejectCall(callId: String, type: String) {
        Task {
            try await streamVideo.rejectCall(callId: callId, callType: callType(from: type))
            self.callingState = .idle
        }
    }
    
    /// Starts capturing the local video.
    public func startCapturingLocalVideo() {
        callController?.startCapturingLocalVideo()
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisbility(for participant: CallParticipant, isVisible: Bool) {
        Task {
            await callController?.changeTrackVisibility(for: participant, isVisible: isVisible)
        }
    }
    
    /// Hangs up from the active call.
    public func hangUp() {
        if let call = call, callingState != .inCall {
            Task {
                try await streamVideo.cancelCall(callId: call.callId, callType: call.callType)
            }
        }
        leaveCall()
    }
    
    /// Sets a video filter for the current call.
    /// - Parameter videoFilter: the video filter to be set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        callController?.setVideoFilter(videoFilter)
    }
    
    // MARK: - private
    
    /// Leaves the current call.
    private func leaveCall() {
        log.debug("Leaving call")
        participantUpdates?.cancel()
        participantUpdates = nil
        callUpdates?.cancel()
        callUpdates = nil
        reconnectionUpdates?.cancel()
        reconnectionUpdates = nil
        recordingUpdates?.cancel()
        recordingUpdates = nil
        call = nil
        callParticipants = [:]
        outgoingCallMembers = []
        streamVideo.leaveCall()
        currentEventsTask?.cancel()
        callingState = .idle
        isMinimized = false
    }
    
    private func enterCall(callId: String, callType: CallType, participants: [User], ring: Bool = false) {
        guard let callController = callController else {
            return
        }

        Task {
            do {
                log.debug("Starting call")
                let call: Call = try await callController.joinCall(
                    callType: callType,
                    callId: callId,
                    callSettings: callSettings,
                    videoOptions: videoOptions,
                    participants: participants,
                    ring: ring
                )
                save(call: call)
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                self.error = error
                callingState = .idle
            }
        }
    }
    
    private func save(call: Call) {
        self.call = call
        updateCallStateIfNeeded()
        listenForParticipantEvents()
        log.debug("Started call")
    }
    
    private func handleRingingEvents() {
        let ringingTimeout = streamVideo.videoConfig.ringingTimeout
        guard ringingSupported, ringingTimeout > 0 else { return }
        if callingState == .outgoing {
            ringingTimer = Foundation.Timer.scheduledTimer(
                withTimeInterval: ringingTimeout,
                repeats: false,
                block: { [weak self] _ in
                    guard let self = self else { return }
                    log.debug("Detected ringing timeout, hanging up...")
                    Task {
                        await self.hangUp()
                    }
                }
            )
        } else {
            ringingTimer?.invalidate()
        }
    }
    
    private func subscribeToCallEvents() {
        Task {
            for await callEvent in streamVideo.callEvents() {
                if case let .incoming(incomingCall) = callEvent,
                   ringingSupported,
                   incomingCall.callerId != streamVideo.user.id {
                    // TODO: implement holding a call.
                    if callingState == .idle {
                        callingState = .incoming(incomingCall)
                    }
                } else if case .rejected = callEvent, ringingSupported {
                    leaveCall()
                } else if case .canceled = callEvent, callParticipants.count < 2, ringingSupported {
                    leaveCall()
                } else if case .ended = callEvent {
                    leaveCall()
                } else if case let .userBlocked(callEventInfo) = callEvent {
                    if callEventInfo.user?.id == streamVideo.user.id {
                        leaveCall()
                    } else if let user = callEventInfo.user {
                        call?.add(blockedUser: user)
                    }
                } else if case let .userUnblocked(callEventInfo) = callEvent,
                            let user = callEventInfo.user {
                    call?.remove(blockedUser: user)
                }
            }
        }
    }
    
    private func callType(from: String?) -> CallType {
        var type: CallType = .default
        if let from = from {
            type = CallType(name: from)
        }
        return type
    }
    
    private func updateCallStateIfNeeded() {
        if !ringingSupported && callingState != .reconnecting {
            callingState = .inCall
        } else {
            let shouldGoInCall = callParticipants.count > 1
            if shouldGoInCall {
                callingState = .inCall
            }
        }
    }
    
    @objc private func checkForOngoingCall() {
        if call == nil && callController?.call != nil {
            call = callController?.call
        }
    }
    
    private func setupCallController(callId: String, type: String?) {
        callController = streamVideo.makeCallController(callType: callType(from: type), callId: callId)
        callController?.onCallUpdated = { [weak self] updatedCall in            
            DispatchQueue.main.async {
                guard let updatedCall = updatedCall else {
                    self?.leaveCall()
                    return
                }
                self?.save(call: updatedCall)
            }
        }
    }
    
    private func listenForParticipantEvents() {
        guard let call = call else {
            return
        }
        currentEventsTask = Task {
            for await event in call.participantEvents() {
                self.participantEvent = event
                // The event is shown for 2 seconds.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.participantEvent = nil
            }
        }
    }
    
    private func checkForScreensharingSession() {
        for (_, participant) in callParticipants {
            if participant.screenshareTrack != nil {
                screensharingSession = ScreensharingSession(
                    track: participant.screenshareTrack,
                    participant: participant
                )
                return
            }
        }
        screensharingSession = nil
    }
    
    private func checkCallSettingsForCurrentUser() {
        guard let localParticipant = localParticipant,
              // Skip updates for the initial period while the connection is established.
              Date().timeIntervalSince(localParticipant.joinedAt) > 5.0 else {
            return
        }
        if localParticipant.hasAudio != callSettings.audioOn
            || localParticipant.hasVideo != callSettings.videoOn {
            let previous = callSettings
            callSettings = CallSettings(
                audioOn: localParticipant.hasAudio,
                videoOn: localParticipant.hasVideo,
                speakerOn: previous.speakerOn,
                audioOutputOn: previous.audioOutputOn,
                cameraPosition: previous.cameraPosition
            )
        }
    }
}

/// The state of the call.
public enum CallingState: Equatable {
    /// Call is not started (idle state).
    case idle
    /// The user is in a waiting room.
    case lobby(LobbyInfo)
    /// There's an incoming call.
    case incoming(IncomingCall)
    /// There's an outgoing call.
    case outgoing
    /// The user is in a call.
    case inCall
    /// The user is trying to reconnect to a call.
    case reconnecting
}

public struct LobbyInfo: Equatable {
    public let callId: String
    public let callType: CallType
    public let participants: [User]
}

public struct ScreensharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}
