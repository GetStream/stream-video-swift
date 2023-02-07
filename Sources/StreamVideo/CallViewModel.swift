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
    
    @Published public var call: Call? {
        didSet {
            participantUpdates = call?.$participants.receive(on: RunLoop.main).sink(receiveValue: { [weak self] participants in
                self?.callParticipants = participants
            })
        }
    }
    
    @Published public var callingState: CallingState = .idle {
        didSet {
            if callingState == .idle {
                edgeServer = nil
            }
            handleRingingEvents()
        }
    }
    
    @Published public var shouldShowError: Bool = false
    public var latestError: Error?
                        
    @Published public var participantsShown = false
    
    @Published public var inviteParticipantsShown = false
    
    @Published public var outgoingCallMembers = [User]()
    
    @Published public var callParticipants = [String: CallParticipant]() {
        didSet {
            log.debug("Call participants updated")
            updateCallStateIfNeeded()
            checkForScreensharingSession()
        }
    }
    
    @Published public var participantEvent: ParticipantEvent?
    
    @Published public var callSettings = CallSettings()
    
    @Published public var isMinimized = false
    
    @Published public var localVideoPrimary = false
    
    @Published public var screensharingSession: ScreensharingSession?
    
    @Published public var hideUIElements = false
    
    @Published public private(set) var edgeServer: EdgeServer?
    
    public var localParticipant: CallParticipant? {
        callParticipants.first(where: { (_, value) in
            value.id == call?.sessionId
        })
            .map { $1 }
    }
    
    public var videoOptions = VideoOptions()
            
    private var participantUpdates: AnyCancellable?
    private var currentEventsTask: Task<Void, Never>?
    
    private var callController: CallController?
    
    private var ringingTimer: Foundation.Timer?
    
    public var participants: [CallParticipant] {
        callParticipants
            .filter { $0.value.id != call?.sessionId }
            .map(\.value)
            .sorted(by: { $0.layoutPriority.rawValue < $1.layoutPriority.rawValue })
            .sorted(by: { $0.name < $1.name })
    }
    
    private var ringingSupported: Bool {
        !streamVideo.videoConfig.joinVideoCallInstantly
    }
    
    public init() {
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
                    speakerOn: callSettings.speakerOn
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
                    speakerOn: callSettings.speakerOn
                )
            } catch {
                log.error("Error toggling microphone")
            }
        }
    }
    
    /// Toggles the state of the camera (visible vs non-visible).
    public func toggleCameraPosition() {
        guard let callController = callController else {
            return
        }
        let next = callSettings.cameraPosition.next()
        callController.changeCameraMode(position: next)
        callSettings = callSettings.withUpdatedCameraPosition(next)
    }

    /// Starts a call with the provided info.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: optional type of a call. If not provided, the default would be used.
    ///  - participants: list of participants that are part of the call.
    public func startCall(callId: String, type: String? = nil, participants: [User]) {
        outgoingCallMembers = participants
        callController = streamVideo.makeCallController(callType: callType(from: type), callId: callId)
        callingState = .outgoing
        let callType = callType(from: type)
        enterCall(callId: callId, callType: callType, participantIds: participants.map(\.id))
    }
    
    /// Joins an existing call with the provided info.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: optional type of a call. If not provided, the default would be used.
    public func joinCall(callId: String, type: String? = nil) {
        let callType = callType(from: type)
        callController = streamVideo.makeCallController(callType: callType, callId: callId)
        enterCall(callId: callId, callType: callType, participantIds: participants.map(\.userId))
    }
    
    public func enterWaitingRoom(callId: String, type: String? = nil, participants: [User]) {
        let callType = callType(from: type)
        let waitingRoomInfo = WaitingRoomInfo(callId: callId, callType: callType, participants: participants)
        callingState = .waitingRoom(waitingRoomInfo)
        callController = streamVideo.makeCallController(callType: callType, callId: callId)
        Task {
            self.edgeServer = try await callController?.selectEdgeServer(
                videoOptions: VideoOptions(),
                participantIds: participants.map(\.id)
            )
        }
    }
    
    public func joinCallFromWaitingRoom(callId: String, type: String? = nil, participantIds: [String]) throws {
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
                    videoOptions: VideoOptions(),
                    participantIds: participantIds
                )
                save(call: call)
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
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
        callController = streamVideo.makeCallController(callType: callType, callId: callId)
        Task {
            try await streamVideo.acceptCall(callId: callId, callType: callType)
            enterCall(callId: callId, callType: callType, participantIds: participants.map(\.userId))
        }
    }
    
    /// Rejects the call with the provided call id and type.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - callType: the type of the call.
    public func rejectCall(callId: String, type: String) {
        Task {
            try await streamVideo.rejectCall(callId: callId, callType: callType(from: type))
        }
    }
    
    /// Renders the local video in the provided renderer.
    /// - Parameter renderer: Any view (both UIKit and SwiftUI) implementing the `RTCVideoRenderer` protocol.
    public func renderLocalVideo(renderer: RTCVideoRenderer) {
        callController?.renderLocalVideo(renderer: renderer)
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
    
    public func setVideoFilter(_ videoFilter: VideoFilter?) {
        callController?.setVideoFilter(videoFilter)
    }
    
    // MARK: - private
    
    /// Leaves the current call.
    private func leaveCall() {
        log.debug("Leaving call")
        participantUpdates?.cancel()
        participantUpdates = nil
        call = nil
        callParticipants = [:]
        outgoingCallMembers = []
        streamVideo.leaveCall()
        currentEventsTask?.cancel()
        callingState = .idle
        isMinimized = false
    }
    
    private func enterCall(callId: String, callType: CallType, participantIds: [String]) {
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
                    participantIds: participantIds
                )
                save(call: call)
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
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
        if streamVideo.videoConfig.joinVideoCallInstantly {
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
}

/// The state of the call.
public enum CallingState: Equatable {
    /// Call is not started (idle state).
    case idle
    /// The user is in a waiting room.
    case waitingRoom(WaitingRoomInfo)
    /// There's an incoming call.
    case incoming(IncomingCall)
    /// There's an outgoing call.
    case outgoing
    /// The user is in a call.
    case inCall
    /// The user is trying to reconnect to a call.
    case reconnecting
}

public struct WaitingRoomInfo: Equatable {
    public let callId: String
    public let callType: CallType
    public let participants: [User]
}

public struct ScreensharingSession {
    public let track: RTCVideoTrack?
    public let participant: CallParticipant
}
