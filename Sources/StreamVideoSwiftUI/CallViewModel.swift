//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import StreamVideo
import StreamWebRTC
import SwiftUI

// View model that provides methods for views that present a call.
@MainActor
open class CallViewModel: ObservableObject {

    @Injected(\.streamVideo) var streamVideo
    @Injected(\.pictureInPictureAdapter) var pictureInPictureAdapter
    @Injected(\.callAudioRecorder) var audioRecorder
    @Injected(\.applicationStateAdapter) var applicationStateAdapter

    /// Provides access to the current call.
    @Published public private(set) var call: Call? {
        didSet {
            guard call?.cId != oldValue?.cId else { return }
            pictureInPictureAdapter.call = call
            lastLayoutChange = Date()
            participantUpdates = call?.state.$participantsMap
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] participants in
                    self?.callParticipants = participants
                })

            blockedUserUpdates = call?.state.$blockedUserIds
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
                    guard let self else { return }
                    switch reconnectionStatus {
                    case .reconnecting where callingState != .reconnecting:
                        setCallingState(.reconnecting)
                    default:
                        if callingState != .inCall, callingState != .outgoing {
                            setCallingState(.inCall)
                        }
                    }
                })
            screenSharingUpdates = call?.state.$screenSharingSession
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] screenSharingSession in
                    if screenSharingSession?.participant.id != self?.lastScreenSharingParticipant?.id {
                        self?.lastLayoutChange = Date()
                    }
                    self?.lastScreenSharingParticipant = screenSharingSession?.participant
                })
            callSettingsUpdates = call?.state.$callSettings
                .receive(on: RunLoop.main)
                .sink(receiveValue: { [weak self] settings in
                    self?.callSettings = settings
                })

            // We only update the outgoingCallMembers if they are empty (which
            // means that the call was created externally)
            outgoingCallMembersUpdates = call?
                .state
                .$members
                .filter { [weak self] _ in
                    self?.outgoingCallMembers.isEmpty == true
                        && self?.callingState == .outgoing
                }
                .receive(on: RunLoop.main)
                .assign(to: \.outgoingCallMembers, onWeak: self)
            if let callSettings = call?.state.callSettings {
                self.callSettings = callSettings
            }
        }
    }

    /// Tracks the current state of a call. It should be used to show different UI in your views.
    @Published public var callingState: CallingState = .idle {
        didSet {
            // When we join a call and then ring, we need to disable the speaker.
            // If the dashboard settings have the speaker on, we need to enable it
            // again when we transition into a call.
            if let temporaryCallSettings, oldValue == .outgoing && callingState == .inCall {
                if temporaryCallSettings.speakerOn {
                    Task {
                        do {
                            try await call?.speaker.enableSpeakerPhone()
                        } catch {
                            log.error("Error enabling the speaker: \(error.localizedDescription)")
                        }
                    }
                }
                self.temporaryCallSettings = nil
            }
            handleRingingEvents()
        }
    }

    /// Optional, has a value if there was an error. You can use it to display more detailed error messages to the users.
    public var error: Error? {
        didSet {
            errorAlertShown = error != nil
            if let error = error as? APIError {
                toast = Toast(style: .error, message: error.message)
            } else if let error {
                toast = Toast(style: .error, message: error.localizedDescription)
            } else {
                toast = nil
            }
        }
    }

    /// Controls the display of toast messages.
    @Published public var toast: Toast?

    /// If the `error` property has a value, it's true. You can use it to control the visibility of an alert presented to the user.
    @Published public var errorAlertShown = false

    /// Whether the list of participants is shown during the call.
    @Published public var participantsShown = false

    /// Whether the list of participants is shown during the call.
    @Published public var moreControlsShown = false

    /// List of the outgoing call members.
    @Published public var outgoingCallMembers = [Member]()

    /// Dictionary of the call participants.
    @Published public private(set) var callParticipants = [String: CallParticipant]() {
        didSet {
            updateCallStateIfNeeded()
        }
    }

    /// Contains info about a participant event. It's reset to nil after 2 seconds.
    @Published public var participantEvent: ParticipantEvent?

    /// Provides information about the current call settings, such as the camera position and whether there's an audio and video turned on.
    @Published public internal(set) var callSettings: CallSettings {
        didSet {
            localCallSettingsChange = true
        }
    }

    /// Whether the call is in minimized mode.
    @Published public var isMinimized = false

    /// `false` by default. It becomes `true` when the current user's local video is shown as a primary view.
    @Published public var localVideoPrimary = false

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

    /// A flag controlling whether picture-in-picture should be enabled for the call. Default value is `true`.
    @Published public var isPictureInPictureEnabled = true

    /// Returns the local participant of the call.
    public var localParticipant: CallParticipant? {
        call?.state.localParticipant
    }

    /// Returns the noiseCancellationFilter if available.
    public var noiseCancellationAudioFilter: AudioFilter? { streamVideo.videoConfig.noiseCancellationFilter }

    private var participantUpdates: AnyCancellable?
    private var blockedUserUpdates: AnyCancellable?
    private var reconnectionUpdates: AnyCancellable?
    private var recordingUpdates: AnyCancellable?
    private var screenSharingUpdates: AnyCancellable?
    private var callSettingsUpdates: AnyCancellable?
    private var outgoingCallMembersUpdates: AnyCancellable?
    private var applicationLifecycleUpdates: AnyCancellable?

    private var ringingCancellable: AnyCancellable?
    private var lastScreenSharingParticipant: CallParticipant?

    private var lastLayoutChange = Date()
    private var enteringCallTask: Task<Void, Never>?
    private var participantsSortComparators = defaultSortPreset
    private let callEventsHandler = CallEventsHandler()
    private let disposableBag = DisposableBag()

    private lazy var participantEventResetAdapter = ParticipantEventResetAdapter(self)

    /// The variable is `true` if CallSettings have been set on the CallViewModel instance (directly or indirectly).
    /// The variable will be reset to `false` when `leaveCall` will be invoked.
    private(set) var localCallSettingsChange = false

    private var hasAcceptedCall = false
    private var skipCallStateUpdates = false
    private var temporaryCallSettings: CallSettings?

    public var participants: [CallParticipant] {
        let updateParticipants = call?.state.participants ?? []
        return updateParticipants.filter {
            // In Grid layout with less than 3 participants the local user
            // will be presented on the floating video track view. For this
            // reason we filter out the participant to avoid showing them twice.
            if
                participantsLayout == .grid,
                updateParticipants.count <= 3,
                (call?.state.screenSharingSession == nil || call?.state.isCurrentUserScreensharing == true) {
                return $0.id != call?.state.sessionId
            } else {
                return true
            }
        }
    }

    private var automaticLayoutHandling = true

    /// The policy to whenever call events occur in order to decide if the current user should remain
    /// in the call or not. Default value is the no operation policy `DefaultParticipantAutoLeavePolicy`,
    public var participantAutoLeavePolicy: ParticipantAutoLeavePolicy = DefaultParticipantAutoLeavePolicy() {
        didSet {
            var oldValue = oldValue
            oldValue.onPolicyTriggered = nil
            participantAutoLeavePolicy.onPolicyTriggered = { [weak self] in self?.participantAutoLeavePolicyTriggered() }
        }
    }

    public init(
        participantsLayout: ParticipantsLayout = .grid,
        callSettings: CallSettings? = nil
    ) {
        self.participantsLayout = participantsLayout
        self.callSettings = callSettings ?? .default
        localCallSettingsChange = callSettings != nil

        subscribeToCallEvents()
        subscribeToApplicationLifecycleEvents()

        // As we are setting the value on init, the `didSet` won't trigger, thus
        // we are firing it manually.
        // For any subsequent changes, `didSet` will trigger as expected.
        participantAutoLeavePolicy.onPolicyTriggered = { [weak self] in self?.participantAutoLeavePolicyTriggered() }

        _ = participantEventResetAdapter
    }

    deinit {
        enteringCallTask?.cancel()
        disposableBag.removeAll()
    }

    /// Toggles the state of the camera (visible vs non-visible).
    public func toggleCameraEnabled() {
        guard let call = call else {
            callSettings = callSettings.withUpdatedVideoState(!callSettings.videoOn)
            return
        }
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await call.camera.toggle()
                localCallSettingsChange = true
            } catch {
                log.error("Error toggling camera", error: error)
            }
        }
    }

    /// Toggles the state of the microphone (muted vs unmuted).
    public func toggleMicrophoneEnabled() {
        guard let call = call else {
            callSettings = callSettings.withUpdatedAudioState(!callSettings.audioOn)
            return
        }
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await call.microphone.toggle()
                localCallSettingsChange = true
            } catch {
                log.error("Error toggling microphone", error: error)
            }
        }
    }

    /// Toggles the camera position (front vs back).
    public func toggleCameraPosition() {
        guard let call = call, callSettings.videoOn else {
            self.callSettings = callSettings.withUpdatedCameraPosition(callSettings.cameraPosition.next())
            return
        }
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await call.camera.flip()
                localCallSettingsChange = true
            } catch {
                log.error("Error toggling camera position", error: error)
            }
        }
    }

    /// Enables or disables the audio output.
    public func toggleAudioOutput() {
        guard let call = call else {
            callSettings = callSettings.withUpdatedAudioOutputState(!callSettings.audioOutputOn)
            return
        }
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                if callSettings.audioOutputOn {
                    try await call.speaker.disableAudioOutput()
                } else {
                    try await call.speaker.enableAudioOutput()
                }
                localCallSettingsChange = true
            } catch {
                log.error("Error toggling audio output", error: error)
            }
        }
    }

    /// Enables or disables the speaker.
    public func toggleSpeaker() {
        guard let call = call else {
            callSettings = callSettings.withUpdatedSpeakerState(!callSettings.speakerOn)
            return
        }
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await call.speaker.toggleSpeakerPhone()
                localCallSettingsChange = true
            } catch {
                log.error("Error toggling speaker", error: error)
            }
        }
    }

    /// Starts a call with the provided info.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    ///  - members: list of members that are part of the call.
    ///  - ring: whether the call should ring.
    ///  - maxDuration: An optional integer representing the maximum duration of the call in seconds.
    ///  - maxParticipants: An optional integer representing the maximum number of participants allowed in the call.
    ///  - startsAt: An optional date when the call starts.
    ///  - backstage: An optional request for setting up backstage.
    ///  - video: A boolean indicating if the call will be video or only audio. Still requires appropriate
    ///   setting of ``CallSettings`.`
    public func startCall(
        callType: String,
        callId: String,
        members: [Member],
        team: String? = nil,
        ring: Bool = false,
        maxDuration: Int? = nil,
        maxParticipants: Int? = nil,
        startsAt: Date? = nil,
        backstage: BackstageSettingsRequest? = nil,
        customData: [String: RawJSON]? = nil,
        video: Bool? = nil
    ) {
        outgoingCallMembers = members
        setCallingState(ring ? .outgoing : .joining)
        let membersRequest: [MemberRequest]? = members.isEmpty
            ? nil
            : members.map(\.toMemberRequest)
        if !ring {
            enterCall(
                callType: callType,
                callId: callId,
                members: membersRequest ?? [],
                team: team,
                ring: ring,
                maxDuration: maxDuration,
                maxParticipants: maxParticipants,
                startsAt: startsAt,
                backstage: backstage,
                customData: customData
            )
        } else {
            /// If no CallSettings have been provided, we skip passing the default ones, in order to
            /// respect any dashboard changes.
            let callSettings = localCallSettingsChange ? callSettings : nil
            let call = streamVideo.call(
                callType: callType,
                callId: callId,
                callSettings: callSettings
            )
            self.call = call
            Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    let callData = try await call.create(
                        members: membersRequest,
                        custom: customData,
                        team: team,
                        ring: ring,
                        maxDuration: maxDuration,
                        maxParticipants: maxParticipants,
                        video: video
                    )
                    let timeoutSeconds = TimeInterval(
                        callData.settings.ring.autoCancelTimeoutMs / 1000
                    )
                    startTimer(timeout: timeoutSeconds)
                } catch {
                    self.error = error
                    setCallingState(.idle)
                    self.call = nil
                }
            }
        }
    }

    /// Joins an existing call with the provided info.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func joinCall(
        callType: String,
        callId: String,
        customData: [String: RawJSON]? = nil
    ) {
        setCallingState(.joining)
        enterCall(
            callType: callType,
            callId: callId,
            members: [],
            customData: customData
        )
    }
    
    /// Joins a call and then rings the specified members.
    /// - Parameters:
    ///   - callType: The type of the call to join (for example, "default").
    ///   - callId: The unique identifier of the call.
    ///   - members: The members who should be rung for this call.
    ///   - team: An optional team identifier to associate with the call.
    ///   - maxDuration: The maximum duration of the call in seconds.
    ///   - maxParticipants: The maximum number of participants allowed in the call.
    ///   - startsAt: An optional scheduled start time for the call.
    ///   - customData: Optional custom payload to associate with the call on creation.
    ///   - video: Optional flag indicating whether the ring should suggest a video call.
    public func joinAndRingCall(
        callType: String,
        callId: String,
        members: [Member],
        team: String? = nil,
        maxDuration: Int? = nil,
        maxParticipants: Int? = nil,
        startsAt: Date? = nil,
        customData: [String: RawJSON]? = nil,
        video: Bool? = nil
    ) {
        outgoingCallMembers = members
        skipCallStateUpdates = true
        setCallingState(.outgoing)
        let membersRequest: [MemberRequest]? = members.isEmpty
            ? nil
            : members.map(\.toMemberRequest)
        
        if enteringCallTask != nil || callingState == .inCall {
            return
        }
        enteringCallTask = Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                log.debug("Starting call")
                let call = call ?? streamVideo.call(
                    callType: callType,
                    callId: callId,
                    callSettings: callSettings
                )
                var settingsRequest: CallSettingsRequest?
                var limits: LimitsSettingsRequest?
                if maxDuration != nil || maxParticipants != nil {
                    limits = .init(maxDurationSeconds: maxDuration, maxParticipants: maxParticipants)
                }
                settingsRequest = .init(limits: limits)
                let options = CreateCallOptions(
                    members: membersRequest,
                    custom: customData,
                    settings: settingsRequest,
                    startsAt: startsAt,
                    team: team
                )
                let settings = localCallSettingsChange ? callSettings : nil

                call.updateParticipantsSorting(with: participantsSortComparators)

                let joinResponse = try await call.join(
                    create: true,
                    options: options,
                    ring: false,
                    callSettings: settings
                )
                
                temporaryCallSettings = call.state.callSettings
                try? await call.speaker.disableSpeakerPhone()

                try await call.ring(
                    request: .init(membersIds: members.map(\.id).filter { $0 != self.streamVideo.user.id }, video: video)
                )
                
                let autoCancelTimeoutMs = call.state.settings?.ring.autoCancelTimeoutMs
                    ?? joinResponse.call.settings.ring.autoCancelTimeoutMs
                let timeoutSeconds = TimeInterval(autoCancelTimeoutMs) / 1000
                startTimer(timeout: timeoutSeconds)
                save(call: call)
                enteringCallTask = nil
                hasAcceptedCall = false
            } catch {
                hasAcceptedCall = false
                log.error("Error starting a call", error: error)
                self.error = error
                setCallingState(.idle)
                audioRecorder.stopRecording()
                enteringCallTask = nil
            }
        }
    }
    
    /// Enters into a lobby before joining a call.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    ///  - members: list of members that are part of the call.
    public func enterLobby(
        callType: String,
        callId: String,
        members: [Member]
    ) {
        let lobbyInfo = LobbyInfo(callId: callId, callType: callType, participants: members)
        setCallingState(.lobby(lobbyInfo))
        if !localCallSettingsChange {
            Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
                guard let self else { return }
                do {
                    let call = streamVideo.call(callType: callType, callId: callId)
                    let info = try await call.get()
                    self.callSettings = .init(info.call.settings)
                } catch {
                    log.error(error)
                }
            }
        }
    }

    /// Accepts the call with the provided call id and type.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func acceptCall(
        callType: String,
        callId: String,
        customData: [String: RawJSON]? = nil
    ) {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let call = streamVideo.call(callType: callType, callId: callId)
            do {
                hasAcceptedCall = true
                try await call.accept()
                enterCall(
                    call: call,
                    callType: callType,
                    callId: callId,
                    members: [],
                    customData: customData
                )
            } catch {
                hasAcceptedCall = false
                self.error = error
                setCallingState(.idle)
                self.call = nil
            }
        }
    }

    /// Rejects the call with the provided call id and type.
    /// - Parameters:
    ///  - callType: the type of the call.
    ///  - callId: the id of the call.
    public func rejectCall(
        callType: String,
        callId: String
    ) {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            let call = streamVideo.call(callType: callType, callId: callId)
            let rejectionReason = await streamVideo
                .rejectionReasonProvider
                .reason(for: call.cId, ringTimeout: false)
            log.debug(
                """
                Rejecting with reason: \(rejectionReason ?? "nil")
                call:\(call.callId)
                callType: \(call.callType)
                ringTimeout: \(false)
                """
            )
            _ = try? await call.reject(reason: rejectionReason)
            setCallingState(.idle)
        }
    }

    /// Changes the track visibility for a participant (not visible if they go off-screen).
    /// - Parameters:
    ///  - participant: the participant whose track visibility would be changed.
    ///  - isVisible: whether the track should be visible.
    public func changeTrackVisibility(for participant: CallParticipant, isVisible: Bool) {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            await call?.changeTrackVisibility(for: participant, isVisible: isVisible)
        }
    }

    /// Updates the track size for the provided participant.
    /// - Parameters:
    ///  - trackSize: the size of the track.
    ///  - participant: the call participant.
    public func updateTrackSize(_ trackSize: CGSize, for participant: CallParticipant) {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            log.debug("Updating track size for participant \(participant.name) to \(trackSize)")
            await call?.updateTrackSize(trackSize, for: participant)
        }
    }

    /// Starts screensharing for the current call.
    /// - Parameters:
    ///   - type: The screensharing type (in-app or broadcasting).
    ///   - includeAudio: Whether to capture app audio during screensharing.
    ///     Only valid for `.inApp`; ignored otherwise.
    public func startScreensharing(type: ScreensharingType, includeAudio: Bool = true) {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                await disablePictureInPictureIfRequired(type)
                try await call?.startScreensharing(type: type, includeAudio: includeAudio)
            } catch {
                log.error(error)
            }
        }
    }

    public func stopScreensharing() {
        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                try await call?.stopScreensharing()
            } catch {
                log.error(error)
            }
        }
    }

    /// Hangs up from the active call.
    public func hangUp() {
        handleCallHangUp(ringTimeout: false)
    }

    /// Sets a video filter for the current call.
    /// - Parameter videoFilter: the video filter to be set.
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        call?.setVideoFilter(videoFilter)
    }

    /// Updates the participants layout.
    /// - Parameter participantsLayout: the new participants layout.
    public func update(participantsLayout: ParticipantsLayout) {
        automaticLayoutHandling = false
        self.participantsLayout = participantsLayout
    }

    public func setActiveCall(
        _ call: Call?,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        log.debug(
            "Will setActiveCall to cID:\(call?.cId ?? "-")",
            functionName: function,
            fileName: file,
            lineNumber: line
        )
        if let call, (callingState != .inCall || self.call?.cId != call.cId) {
            if !skipCallStateUpdates {
                setCallingState(.inCall)
            }
            self.call = call
        } else if call == nil, callingState != .idle {
            setCallingState(.idle)
            Task { @MainActor in
                self.call = nil
            }
        }
    }

    /// Updates the participants sorting.
    /// - Parameter participantsSortComparators: the new sort comparators.
    public func update(participantsSortComparators: [StreamSortComparator<CallParticipant>]) {
        self.participantsSortComparators = participantsSortComparators
    }

    // MARK: - private

    func setCallingState(
        _ newValue: CallingState,
        file: StaticString = #file,
        function: StaticString = #function,
        line: UInt = #line
    ) {
        guard callingState != newValue else {
            return
        }
        log.debug(
            "CallingState will be updated \(callingState) → \(newValue)",
            functionName: function,
            fileName: file,
            lineNumber: line
        )
        guard !Thread.isMainThread else {
            callingState = newValue
            return
        }
        Task { @MainActor in
            setCallingState(
                newValue,
                file: file,
                function: function,
                line: line
            )
        }
    }

    /// Leaves the current call.
    private func leaveCall() {
        log.debug("Leaving call")
        enteringCallTask?.cancel()
        enteringCallTask = nil
        participantUpdates?.cancel()
        participantUpdates = nil
        blockedUserUpdates?.cancel()
        blockedUserUpdates = nil
        automaticLayoutHandling = true
        reconnectionUpdates?.cancel()
        reconnectionUpdates = nil
        screenSharingUpdates?.cancel()
        screenSharingUpdates = nil
        recordingUpdates?.cancel()
        recordingUpdates = nil
        skipCallStateUpdates = false
        temporaryCallSettings = nil
        call?.leave()

        pictureInPictureAdapter.call = nil
        pictureInPictureAdapter.sourceView = nil

        call = nil
        callParticipants = [:]
        outgoingCallMembers = []
        setCallingState(.idle)
        isMinimized = false
        localVideoPrimary = false
        hasAcceptedCall = false
        audioRecorder.stopRecording()

        // Reset the CallSettings so that the next Call will be joined
        // with either new overrides or the values provided from the API.
        callSettings = .default
        localCallSettingsChange = false
    }

    private func enterCall(
        call: Call? = nil,
        callType: String,
        callId: String,
        members: [MemberRequest],
        team: String? = nil,
        ring: Bool = false,
        maxDuration: Int? = nil,
        maxParticipants: Int? = nil,
        startsAt: Date? = nil,
        backstage: BackstageSettingsRequest? = nil,
        customData: [String: RawJSON]? = nil
    ) {
        if enteringCallTask != nil || callingState == .inCall {
            return
        }
        enteringCallTask = Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                log.debug("Starting call")
                let call = call ?? streamVideo.call(
                    callType: callType,
                    callId: callId,
                    callSettings: callSettings
                )
                var settingsRequest: CallSettingsRequest?
                var limits: LimitsSettingsRequest?
                if maxDuration != nil || maxParticipants != nil {
                    limits = .init(maxDurationSeconds: maxDuration, maxParticipants: maxParticipants)
                }
                settingsRequest = .init(backstage: backstage, limits: limits)
                let options = CreateCallOptions(
                    members: members,
                    custom: customData,
                    settings: settingsRequest,
                    startsAt: startsAt,
                    team: team
                )
                let settings = localCallSettingsChange ? callSettings : nil

                call.updateParticipantsSorting(with: participantsSortComparators)

                try await call.join(
                    create: true,
                    options: options,
                    ring: ring,
                    callSettings: settings
                )
                save(call: call)
                enteringCallTask = nil
                hasAcceptedCall = false
            } catch {
                hasAcceptedCall = false
                log.error("Error starting a call", error: error)
                self.error = error
                setCallingState(.idle)
                audioRecorder.stopRecording()
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
        setActiveCall(call)
        log.debug("Started call")
    }

    private func handleRingingEvents() {
        if callingState != .outgoing {
            ringingCancellable?.cancel()
            ringingCancellable = nil
        }
    }

    private func startTimer(timeout: TimeInterval) {
        ringingCancellable = Foundation
            .Timer
            .publish(every: timeout, on: .main, in: .default)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                log.debug("Detected ringing timeout, hanging up...")
                handleCallHangUp(ringTimeout: true)
            }
    }

    private func handleCallHangUp(ringTimeout: Bool = false) {
        if skipCallStateUpdates {
            skipCallStateUpdates = false
        }
        guard
            let call,
            callingState == .outgoing
        else {
            leaveCall()
            return
        }

        Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
            guard let self else { return }
            do {
                let rejectionReason = await streamVideo
                    .rejectionReasonProvider
                    .reason(for: call.cId, ringTimeout: ringTimeout)
                log.debug(
                    """
                    Rejecting with reason: \(rejectionReason ?? "nil")
                    call:\(call.callId)
                    callType: \(call.callType)
                    ringTimeout: \(ringTimeout)
                    """
                )
                try await call.reject(reason: rejectionReason)
            } catch {
                log.error(error)
            }

            leaveCall()
        }
    }

    private func subscribeToCallEvents() {
        streamVideo
            .eventPublisher()
            .sink { [weak self] event in
                guard let self else { return }
                if let callEvent = callEventsHandler.checkForCallEvents(from: event) {
                    switch callEvent {
                    case let .incoming(incomingCall):
                        let currentUserId = streamVideo.user.id
                        Task { @MainActor [weak self] in
                            if incomingCall.caller.id != currentUserId {
                                let isAppActive = UIApplication.shared.applicationState == .active
                                // TODO: implement holding a call.
                                if self?.callingState == .idle && isAppActive {
                                    self?.setCallingState(.incoming(incomingCall))
                                    /// We start the ringing timer, so we can cancel when the timeout
                                    /// is over.
                                    self?.startTimer(timeout: incomingCall.timeout)
                                }
                            }
                        }
                    case .accepted:
                        handleAcceptedEvent(callEvent)
                    case .rejected:
                        handleRejectedEvent(callEvent)
                    case let .ended(event) where event.callCid == call?.cId:
                        Task { @MainActor [weak self] in
                            self?.leaveCall()
                        }
                    case .ended:
                        // Another call ended. No action is required.
                        break
                    case let .userBlocked(callEventInfo):
                        if
                            callEventInfo.user?.id == streamVideo.user.id,
                            callEventInfo.callCid == call?.cId {
                            leaveCall()
                        }
                    case .userUnblocked:
                        break
                    case .sessionStarted:
                        break
                    }
                } else if
                    let participantEvent = callEventsHandler.checkForParticipantEvents(from: event),
                    participantEvent.callCid == call?.cId {
                    guard participants.count < 25 else {
                        log.debug("Skipping participant events for big calls")
                        return
                    }

                    Task(disposableBag: disposableBag, priority: .userInitiated) { @MainActor [weak self] in
                        self?.participantEvent = participantEvent
                    }
                }
            }
            .store(in: disposableBag)
    }

    private func handleAcceptedEvent(_ callEvent: CallEvent) {
        guard case let .accepted(event) = callEvent else {
            return
        }

        switch callingState {
        case let .incoming(incomingCall):
            guard
                event.callCid == callCid(from: incomingCall.id, callType: incomingCall.type),
                event.user?.id == streamVideo.user.id,
                hasAcceptedCall == false
            else {
                break
            }
            /// If the call that was accepted is the incoming call we are presenting, then we reject
            /// and set the activeCall to the current one in order to reset the callingState to
            /// inCall or idle.
            Task {
                log
                    .debug(
                        "Will reject call as isEnteringCall:\(enteringCallTask != nil) isUserIDSameAsLoggedInUser:\(event.user?.id == streamVideo.user.id)"
                    )
                _ = try? await streamVideo
                    .call(callType: incomingCall.type, callId: incomingCall.id)
                    .reject()
                setActiveCall(call)
            }
        case .outgoing where call?.cId == event.callCid:
            skipCallStateUpdates = false
            enterCall(
                call: call,
                callType: event.type,
                callId: event.callId,
                members: []
            )
        default:
            break
        }
    }

    private func handleRejectedEvent(_ callEvent: CallEvent) {
        guard case let .rejected(event) = callEvent else {
            return
        }

        switch callingState {
        case let .incoming(incomingCall) where event.callCid == callCid(from: incomingCall.id, callType: incomingCall.type):
            let isCurrentUserRejection = event.user?.id == streamVideo.user.id
            let isCallCreatorRejection = event.user?.id == incomingCall.caller.id

            guard
                (isCurrentUserRejection || isCallCreatorRejection)
            else {
                return
            }

            setActiveCall(call)
        case .outgoing where call?.cId == event.callCid:
            guard let outgoingCall = call else {
                return
            }
            let outgoingMembersCount = outgoingCallMembers.filter { $0.id != streamVideo.user.id }.count
            let rejections = {
                if outgoingMembersCount == 1, event.user?.id != streamVideo.user.id {
                    return 1
                } else {
                    return outgoingCall.state.session?.rejectedBy.count ?? 0
                }
            }()
            let accepted = outgoingCall.state.session?.acceptedBy.count ?? 0
            if accepted == 0, rejections >= outgoingMembersCount {
                if skipCallStateUpdates {
                    skipCallStateUpdates = false
                    setCallingState(.idle)
                }
                Task(disposableBag: disposableBag, priority: .userInitiated) { [weak self] in
                    _ = try? await outgoingCall.reject(
                        reason: "Call rejected by all \(outgoingMembersCount) outgoing call members."
                    )
                    self?.leaveCall()
                }
            }
        default:
            break
        }
    }

    private func updateCallStateIfNeeded() {
        guard !skipCallStateUpdates else { return }
        if callingState == .outgoing {
            if !callParticipants.isEmpty {
                setCallingState(.inCall)
            }
            return
        }
        guard call != nil || !callParticipants.isEmpty else { return }
        if callingState != .reconnecting, callingState != .inCall {
            setCallingState(.inCall)
        } else {
            let shouldGoInCall = callParticipants.count > 1
            if shouldGoInCall, callingState != .inCall {
                setCallingState(.inCall)
            }
        }
    }

    private func participantAutoLeavePolicyTriggered() {
        leaveCall()
    }

    private func subscribeToApplicationLifecycleEvents() {
        applicationLifecycleUpdates = applicationStateAdapter
            .statePublisher
            .filter { $0 == .foreground }
            .sink { [weak self] _ in self?.applicationDidBecomeActive() }
    }

    private func applicationDidBecomeActive() {
        guard let call else { return }

        let tracksToBeActivated = call
            .state
            .participants
            .filter { $0.hasVideo && $0.track?.isEnabled == false }

        guard !tracksToBeActivated.isEmpty else {
            log.debug("\(type(of: self)) application lifecycle observer found no tracks to activate.")
            return
        }

        log.debug(
            """
            \(tracksToBeActivated.count) tracks have been deactivate while in background 
            and now the app is active need to be activated again.
            """
        )

        tracksToBeActivated.forEach { $0.track?.isEnabled = true }
    }

    /// Disables Picture-in-Picture mode when in-app screen sharing is initiated.
    ///
    /// This method ensures compatibility between screen sharing and Picture-in-Picture features
    /// by automatically disabling PiP when in-app screen sharing is started.
    ///
    /// - Parameter type: The type of screen sharing being initiated (in-app or broadcast).
    ///
    /// - Important: In-app screen sharing and Picture-in-Picture are mutually exclusive features.
    /// When using in-app screen sharing, PiP will be automatically disabled to prevent conflicts.
    /// Consider using broadcast screen sharing if you need to maintain PiP functionality.
    ///
    /// - Note: This method only takes action when:
    ///   - The screen sharing type is `.inApp`
    ///   - Picture-in-Picture is currently enabled
    ///
    /// For more information, see [Screen Sharing Documentation](https://getstream.io/video/docs/ios/advanced/screensharing/#broadcasting)
    private func disablePictureInPictureIfRequired(_ type: ScreensharingType) async {
        guard type == .inApp, isPictureInPictureEnabled else {
            return
        }

        _ = await Task { @MainActor in
            pictureInPictureAdapter.call = nil
            pictureInPictureAdapter.sourceView = nil
            isPictureInPictureEnabled = false
        }.result

        log.warning(
            "InApp screenSharing and Picture-in-Picture are mutually exclusive features. In order to allow the inApp screenSharing operation to go through, we automatically disabled the Picture-in-Picture feature. We recommend transition to a different method to share your screen in your app (e.g. broadcast). You can find more information here: https://getstream.io/video/docs/ios/advanced/screensharing/#broadcasting"
        )
    }
}

/// The state of the call.
public enum CallingState: Equatable, CustomStringConvertible, Sendable {
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

    public var description: String {
        switch self {
        case .idle:
            return ".idle"
        case let .lobby(lobbyInfo):
            return ".lobby(type:\(lobbyInfo.callType), id:\(lobbyInfo.callId))"
        case let .incoming(incomingCall):
            return ".incoming(type:\(incomingCall.type), id:\(incomingCall.id))"
        case .outgoing:
            return ".outgoing"
        case .joining:
            return ".joining"
        case .inCall:
            return ".inCall"
        case .reconnecting:
            return ".reconnecting"
        }
    }
}

public struct LobbyInfo: Equatable, Sendable {
    public let callId: String
    public let callType: String
    public let participants: [Member]
}

public enum ParticipantsLayout {
    case grid
    case spotlight
    case fullScreen
}
