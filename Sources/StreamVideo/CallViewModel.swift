//
// Copyright © 2022 Stream.io Inc. All rights reserved.
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
    
    @Published public var callingState: CallingState = .idle
    
    @Published public var shouldShowError: Bool = false
    public var latestError: Error?
                        
    @Published public var participantsShown = false
    
    @Published public var inviteParticipantsShown = false
    
    @Published public var outgoingCallMembers = [UserInfo]()
    
    @Published public var callParticipants = [String: CallParticipant]() {
        didSet {
            log.debug("Call participants updated")
            updateCallStateIfNeeded()
            localParticipant = callParticipants.first(where: { (key, _) in
                key == streamVideo.userInfo.id
            })
                .map { $1 }
        }
    }
    
    @Published public var participantEvent: ParticipantEvent?
    
    @Published public var callSettings = CallSettings()
    
    @Published public var localParticipant: CallParticipant?
            
    private var participantUpdates: AnyCancellable?
    private var currentEventsTask: Task<Void, Never>?
    
    private var callController: CallController?
    
    public var participants: [CallParticipant] {
        callParticipants
            .filter { $0.value.id != streamVideo.userInfo.id }
            .map(\.value)
            .sorted(by: { $0.layoutPriority.rawValue < $1.layoutPriority.rawValue })
            .sorted(by: { $0.name < $1.name })
    }
    
    public init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkForOngoingCall),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        subscribeToIncomingCalls()
    }
    
    public func setCallController(_ callController: CallController) {
        self.callController = callController
        call = callController.call
        callingState = .inCall
    }

    public func toggleCameraEnabled() {
        // TODO: throw error
        guard let callController = callController else {
            return
        }
        Task {
            let isEnabled = !callSettings.videoOn
            try await callController.changeVideoState(isEnabled: isEnabled)
            callSettings = CallSettings(
                audioOn: callSettings.audioOn,
                videoOn: isEnabled,
                speakerOn: callSettings.speakerOn
            )
        }
    }
    
    /// Toggles the state of the microphone (muted vs unmuted).
    public func toggleMicrophoneEnabled() {
        // TODO: throw error
        guard let callController = callController else {
            return
        }
        Task {
            let isEnabled = !callSettings.audioOn
            try await callController.changeAudioState(isEnabled: isEnabled)
            callSettings = CallSettings(
                audioOn: isEnabled,
                videoOn: callSettings.videoOn,
                speakerOn: callSettings.speakerOn
            )
        }
    }
    
    /// Toggles the state of the camera (visible vs non-visible).
    public func toggleCameraPosition() {
        // TODO: throw error
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
    public func startCall(callId: String, type: String? = nil, participants: [UserInfo]) {
        outgoingCallMembers = participants
        callController = streamVideo.makeCallController(callType: callType(from: type), callId: callId)
        callingState = .outgoing
        enterCall(callId: callId, participantIds: participants.map(\.id))
    }
    
    /// Joins an existing call with the provided info.
    /// - Parameters:
    ///  - callId: the id of the call.
    ///  - type: optional type of a call. If not provided, the default would be used.
    public func joinCall(callId: String, type: String? = nil) {
        callController = streamVideo.makeCallController(callType: callType(from: type), callId: callId)
        enterCall(callId: callId, participantIds: participants.map(\.id))
    }
    
    // TODO: temp method
    public func testSFU(callId: String, participantIds: [String], url: String, token: String) {
        callController = streamVideo.makeCallController(callType: .default, callId: callId)
        callingState = .outgoing
        Task {
            self.call = try await callController?.testSFU(callSettings: callSettings, url: url, token: token)
            self.callingState = .inCall
            listenForParticipantEvents()
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
    
    /// Leaves the current call.
    public func leaveCall() {
        participantUpdates?.cancel()
        participantUpdates = nil
        call = nil
        callParticipants = [:]
        outgoingCallMembers = []
        streamVideo.leaveCall()
        currentEventsTask?.cancel()
        callingState = .idle
    }
    
    // MARK: - private
    
    private func enterCall(callId: String, participantIds: [String]) {
        guard let callController = callController else {
            return
        }

        Task {
            do {
                log.debug("Starting call")
                let callType = CallType.default
                let options = VideoOptions()
                let call: Call = try await callController.joinCall(
                    callType: callType,
                    callId: callId,
                    callSettings: callSettings,
                    videoOptions: options,
                    participantIds: participantIds
                )
                self.call = call
                self.updateCallStateIfNeeded()
                listenForParticipantEvents()
                // TODO: add a check if microphone is already on.
                if callSettings.audioOn {
                    toggleMicrophoneEnabled()
                }
                // TODO: add a check if camera is already on.
                if callSettings.videoOn {
                    toggleCameraEnabled()
                }
                log.debug("Started call")
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                callingState = .idle
            }
        }
    }
    
    private func subscribeToIncomingCalls() {
        Task {
            for await incomingCall in streamVideo.incomingCalls() {
                // TODO: implement holding a call.
                if callingState == .idle {
                    callingState = .incoming(incomingCall)
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
}

/// The state of the call.
public enum CallingState: Equatable {
    /// Call is not started (idle state).
    case idle
    /// There's an incoming call.
    case incoming(IncomingCall)
    /// There's an outgoing call.
    case outgoing
    /// The user is in a call.
    case inCall
    /// The user is trying to reconnect to a call.
    case reconnecting
}
