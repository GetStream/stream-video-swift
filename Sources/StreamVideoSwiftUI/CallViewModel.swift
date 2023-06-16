//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import SwiftUI
import WebRTC

// View model that provides methods for views that present a call.
@MainActor
open class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    /// Provides access to the current call.
    @Published public private(set) var call: Call? {
        didSet {
            lastLayoutChange = Date()
            participantUpdates = call?.state.$participants
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] participants in
                    self?.callParticipants = participants
            })
            callUpdates = call?.state.$blockedUserIds
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] blockedUserIds in
                    self?.blockedUsers = blockedUserIds.map { User(id: $0) }
            })
            recordingUpdates = call?.state.$recordingState
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] newState in
                    self?.recordingState = newState
            })
            reconnectionUpdates = call?.state.$reconnectionStatus
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] reconnectionStatus in
                    if reconnectionStatus == .reconnecting {
                        if self?.callingState != .reconnecting {
                            self?.callingState = .reconnecting
                        }
                    } else if reconnectionStatus == .disconnected {
                        self?.leaveCall()
                    } else {
                        if self?.callingState != .inCall && self?.callingState != .outgoing {
                            self?.callingState = .inCall
                        }
                    }
                })
        }
    }
    
    /// Tracks the current state of a call. It should be used to show different UI in your views.
    @Published public var callingState: CallingState = .idle {
        didSet {
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
    @Published public var outgoingCallMembers = [Member]()
    
    /// Dictionary of the call participants.
    @Published public private(set) var callParticipants = [String: CallParticipant]() {
        didSet {
            if let id = pinnedParticipant?.id, callParticipants[id]?.isPinned == false {
                callParticipants[id] = callParticipants[id]?.withUpdated(pinState: true)
            }
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
    @Published public var screensharingSession: ScreensharingSession? {
        didSet {
            if screensharingSession?.participant.id != oldValue?.participant.id {
                lastLayoutChange = Date()
            }
        }
    }
    
    /// Whether the UI elements, such as the call controls should be hidden (for example while screensharing).
    @Published public var hideUIElements = false
    
    /// A list of the blocked users in the call.
    @Published public var blockedUsers = [User]()
    
    /// The current recording state of the call.
    @Published public var recordingState: RecordingState = .noRecording
    
    /// The participants layout.
    @Published public private(set) var participantsLayout: ParticipantsLayout {
        didSet {
            if participantsLayout != oldValue {
                lastLayoutChange = Date()
            }
        }
    }
        
    @Published public var pinnedParticipant: CallParticipant? {
        didSet {
            if let id = pinnedParticipant?.id, callParticipants[id]?.isPinned == false {
                callParticipants[id] = callParticipants[id]?.withUpdated(pinState: true)
            }
            if let id = oldValue?.id, callParticipants[id]?.isPinned == true {
                callParticipants[id] = callParticipants[id]?.withUpdated(pinState: false)
            }
            if !automaticLayoutHandling {
                return
            }
            if pinnedParticipant != nil && participantsLayout == .grid {
                participantsLayout = .spotlight
            } else if pinnedParticipant == nil && participantsLayout == .spotlight {
                participantsLayout = .grid
            }
        }
    }
    
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
        
    private var ringingTimer: Foundation.Timer?
    
    private var lastLayoutChange = Date()
    private var enteringCallTask: Task<Void, Never>?
    private var participantsSortComparators = defaultComparators
    private let callEventsHandler = CallEventsHandler()
    
    public var participants: [CallParticipant] {
        callParticipants
            .filter {
                if participantsLayout == .grid && screensharingSession == nil {
                    return $0.value.id != call?.sessionId
                } else {
                    return true
                }
            }
            .map(\.value)
            .sorted(using: participantsSortComparators)
    }
        
    private var automaticLayoutHandling = true
    
    public init(
        participantsLayout: ParticipantsLayout = .grid
    ) {
        self.participantsLayout = participantsLayout
        self.subscribeToCallEvents()
    }

    /// Toggles the state of the camera (visible vs non-visible).
    public func toggleCameraEnabled() {
        guard let call = call else { return }
        Task {
            do {
                let isEnabled = !callSettings.videoOn
                try await call.changeVideoState(isEnabled: isEnabled)
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
        guard let call = call else { return }
        Task {
            do {
                let isEnabled = !callSettings.audioOn
                try await call.changeAudioState(isEnabled: isEnabled)
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
        guard let call = call, callSettings.videoOn else { return }
        let next = callSettings.cameraPosition.next()
        call.changeCameraMode(position: next) { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.callSettings = self.callSettings.withUpdatedCameraPosition(next)
            }
        }
    }
    
    /// Enables or disables the audio output.
    public func toggleAudioOutput() {
        guard let call = call else { return }
        Task {
            do {
                let isEnabled = !callSettings.audioOutputOn
                try await call.changeSoundState(isEnabled: isEnabled)
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
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    ///  - members: list of members that are part of the call.
    ///  - ring: whether the call should ring.
    public func startCall(callType: String, callId: String, members: [Member], ring: Bool = false) {
        outgoingCallMembers = members
        callingState = ring ? .outgoing : .joining
        if !ring {
            enterCall(callType: callType, callId: callId, members: members, ring: ring)
        } else {
            let call = streamVideo.call(callType: callType, callId: callId)
            self.call = call
            Task {
                do {
                    let callData = try await call.getOrCreate(members: members, ring: ring)
                    let timeoutSeconds = TimeInterval(
                        callData.settings.ring.autoCancelTimeoutMs / 1000
                    )
                    startTimer(timeout: timeoutSeconds)
                } catch {
                    self.error = error
                    callingState = .idle
                    self.call = nil
                }
            }
        }
    }
    
    /// Joins an existing call with the provided info.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func joinCall(callType: String, callId: String) {
        callingState = .joining
        enterCall(callType: callType, callId: callId, members: [])
    }
    
    /// Enters into a lobby before joining a call.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    ///  - members: list of members that are part of the call.
    public func enterLobby(callType: String, callId: String, members: [Member]) {
        let lobbyInfo = LobbyInfo(callId: callId, callType: callType, participants: members)
        callingState = .lobby(lobbyInfo)
    }
    
    /// Accepts the call with the provided call id and type.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func acceptCall(callType: String, callId: String) {
        Task {
            let call = streamVideo.call(callType: callType, callId: callId)
            do {
                try await call.accept()
                enterCall(call: call, callType: callType, callId: callId, members: [])
            } catch {
                self.error = error
                callingState = .idle
                self.call = nil
            }
        }
    }
    
    /// Rejects the call with the provided call id and type.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func rejectCall(callType: String, callId: String) {
        Task {
            let call = streamVideo.call(callType: callType, callId: callId)
            _ = try? await call.reject()
            self.callingState = .idle
        }
    }
    
    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisbility(for participant: CallParticipant, isVisible: Bool) {
        if !isVisible {
            if participantsLayout == .fullScreen || participantsLayout == .spotlight {
                if participant.id == participants.first?.id {
                    log.debug("Skip hiding the track for the top participant")
                    return
                }
            }
            if participantsLayout == .grid && participants.count < 6 {
                log.debug("Skip hiding tracks in small grids")
                return
            } else {
                let diff = abs(lastLayoutChange.timeIntervalSinceNow)
                if diff < 3 {
                    log.debug("Ignore track changes because of recent layout change")
                    return
                }
            }
        }
        Task {
            await call?.changeTrackVisibility(for: participant, isVisible: isVisible)
        }
    }
    
    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    public func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) {
        Task {
            log.debug("Updating track size for participant \(participant.name) to \(trackSize)")
            await call?.updateTrackSize(trackSize, for: participant)
        }
    }
    
    /// Hangs up from the active call.
    public func hangUp() {
        if callingState == .outgoing {
            Task {
                _ = try? await call?.reject()
                leaveCall()
            }
        } else {
            leaveCall()
        }
    }
    
    /// Sets a video filter for the current call.
    /// - Parameter videoFilter: the video filter to be set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        call?.setVideoFilter(videoFilter)
    }
    
    /// Updates the participants layout.
    /// - Parameter participantsLayout: the new participants layout.
    public func update(participantsLayout: ParticipantsLayout) {
        self.automaticLayoutHandling = false
        self.participantsLayout = participantsLayout
    }
    
    public func setActiveCall(_ call: Call?) {
        if let call {
            self.callingState = .inCall
            self.call = call
        } else {
            self.callingState = .idle
            self.call = nil
        }
    }

    /// Updates the participants sorting.
    /// - Parameter participantsSortComparators: the new sort comparators.
    public func update(participantsSortComparators: [StreamSortComparator<CallParticipant>]) {
        self.participantsSortComparators = participantsSortComparators
    }
    
    // MARK: - private
    
    /// Leaves the current call.
    private func leaveCall() {
        log.debug("Leaving call")
        enteringCallTask?.cancel()
        enteringCallTask = nil
        participantUpdates?.cancel()
        participantUpdates = nil
        callUpdates?.cancel()
        callUpdates = nil
        automaticLayoutHandling = true
        reconnectionUpdates?.cancel()
        reconnectionUpdates = nil
        recordingUpdates?.cancel()
        recordingUpdates = nil
        call?.leave()
        call = nil
        callParticipants = [:]
        outgoingCallMembers = []
        callingState = .idle
        isMinimized = false
        localVideoPrimary = false
    }
    
    private func enterCall(
        call: Call? = nil,
        callType: String,
        callId: String,
        members: [Member],
        ring: Bool = false
    ) {
        if enteringCallTask != nil || callingState == .inCall {
            return
        }
        enteringCallTask = Task {
            do {
                log.debug("Starting call")
                let call = call ?? streamVideo.call(callType: callType, callId: callId)
                try await call.join(members: members, ring: ring, callSettings: callSettings)
                save(call: call)
                enteringCallTask = nil
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                self.error = error
                callingState = .idle
                enteringCallTask = nil
            }
        }
    }
    
    private func save(call: Call) {
        guard enteringCallTask != nil else {
            call.leave()
            self.call = nil
            return
        }
        self.call = call
        updateCallStateIfNeeded()
        log.debug("Started call")
    }
    
    private func handleRingingEvents() {
        if callingState != .outgoing {
            ringingTimer?.invalidate()
        }
    }
    
    private func startTimer(timeout: TimeInterval) {
        ringingTimer = Foundation.Timer.scheduledTimer(
            withTimeInterval: timeout,
            repeats: false,
            block: { [weak self] _ in
                guard let self = self else { return }
                log.debug("Detected ringing timeout, hanging up...")
                Task {
                    await self.hangUp()
                }
            }
        )
    }
    
    private func subscribeToCallEvents() {
        Task {
            for await event in streamVideo.subscribe() {
                if let callEvent = callEventsHandler.checkForCallEvents(from: event) {
                    if case let .incoming(incomingCall) = callEvent,
                       incomingCall.caller.id != streamVideo.user.id {
                        let isAppActive = UIApplication.shared.applicationState == .active
                        // TODO: implement holding a call.
                        if callingState == .idle && isAppActive {
                            callingState = .incoming(incomingCall)
                        }
                    } else if case let .accepted(callEventInfo) = callEvent {
                        if callingState == .outgoing {
                            enterCall(call: call, callType: callEventInfo.type, callId: callEventInfo.callId, members: [])
                        } else if case .incoming(_) = callingState, callEventInfo.user?.id == streamVideo.user.id && enteringCallTask == nil {
                            // Accepted on another device.
                            callingState = .idle
                        }
                    } else if case .rejected = callEvent {
                        handleRejectedEvent(callEvent)
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
                    } else {
                        log.debug("Received call event \(callEvent)")
                    }
                } else if let participantEvent = callEventsHandler.checkForParticipantEvents(from: event) {
                    self.participantEvent = participantEvent
                    if participantEvent.action == .leave &&
                        callParticipants.count == 1
                        && call?.state.session?.acceptedBy.isEmpty == false {
                        leaveCall()
                    } else {
                        // The event is shown for 2 seconds.
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                    }
                    self.participantEvent = nil
                }
            }
        }
    }
    
    private func handleRejectedEvent(_ callEvent: CallEvent) {
        if case .rejected(_) = callEvent {
            let outgoingMembersCount = outgoingCallMembers.filter({ $0.id != streamVideo.user.id }).count
            let rejections = call?.state.session?.rejectedBy.count ?? 0
            let accepted = call?.state.session?.acceptedBy.count ?? 0
                        
            if rejections >= outgoingMembersCount && accepted == 0 {
                Task {
                    _ = try? await call?.reject()
                    leaveCall()
                }
            }
        }
    }
    
    private func updateCallStateIfNeeded() {
        if callingState == .outgoing {
            if callParticipants.count > 0 {
                callingState = .inCall
            }
            return
        }
        guard call != nil || !callParticipants.isEmpty else { return }
        if callingState != .reconnecting {
            callingState = .inCall
        } else {
            let shouldGoInCall = callParticipants.count > 1
            if shouldGoInCall {
                callingState = .inCall
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
    /// The user is joining a call.
    case joining
    /// The user is in a call.
    case inCall
    /// The user is trying to reconnect to a call.
    case reconnecting
}

public struct LobbyInfo: Equatable {
    public let callId: String
    public let callType: String
    public let participants: [Member]
}

public struct ScreensharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}

public enum ParticipantsLayout {
    case grid
    case spotlight
    case fullScreen
}
