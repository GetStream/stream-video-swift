//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI
import WebRTC

@MainActor
open class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public var room: Room? {
        didSet {
            // TODO: refine this.
            connectionStatus = room != nil ? .connected : .disconnected(reason: nil)
            room?.$participants.receive(on: RunLoop.main).sink(receiveValue: { [weak self] participants in
                self?.callParticipants = participants
            })
                .store(in: &cancellables)
        }
    }

    @Published public var connectionStatus: VideoConnectionStatus = .disconnected(reason: nil) {
        didSet {
            checkRoomDisplay()
        }
    }

    public var shouldShowRoomView: Bool = false {
        didSet {
            if shouldShowRoomView {
                calling = false
            }
        }
    }
    
    @Published public var shouldShowError: Bool = false
    public var latestError: Error?
    
    @Published public var calling = false
                    
    @Published public var participantsShown = false
    
    @Published public var inviteParticipantsShown = false
    
    @Published public var callParticipants = [String: CallParticipant]() {
        didSet {
            log.debug("Call participants updated")
            
            localParticipant = callParticipants.first(where: { (key, _) in
                key == streamVideo.userInfo.id
            })
                .map { $1 }
            
            for (_, value) in callParticipants {
                if value.track != nil {
                    log.debug("Found a track for user \(value.name)")
                }
                if value.trackSize != .zero {
                    log.debug("Changed frame for track \(value.trackSize)")
                }
            }
        }
    }
    
    @Published public var participantEvent: ParticipantEvent?
    
    @Published public var callSettings = CallSettings()
    
    @Published public var localParticipant: CallParticipant?
        
    private var url: String = "wss://livekit.fucking-go-slices.com"
    private var token: String = ""
    
    private var cancellables = Set<AnyCancellable>()
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
    }
    
    @objc private func checkForOngoingCall() {
        if room == nil && callController?.room != nil {
            room = callController?.room
        }
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
    
    public func toggleCameraPosition() {
        // TODO: throw error
        guard let callController = callController else {
            return
        }
        let next = callSettings.cameraPosition.next()
        callController.changeCameraMode(position: next)
        callSettings = callSettings.withUpdatedCameraPosition(next)
    }

    public func startCall(callId: String, participantIds: [String]) {
        callController = streamVideo.makeCallController(callType: .default, callId: callId)
        calling = true
        enterCall(callId: callId, participantIds: participantIds)
    }
    
    // TODO: temp method
    public func testSFU(callId: String, participantIds: [String], url: String, token: String) {
        callController = streamVideo.makeCallController(callType: .default, callId: callId)
        calling = true
        Task {
            self.room = try await callController?.testSFU(callSettings: callSettings, url: url, token: token)
            calling = false
            shouldShowRoomView = true
            listenForParticipantEvents()
        }
    }
    
    public func renderLocalVideo(renderer: RTCVideoRenderer) {
        callController?.renderLocalVideo(renderer: renderer)
    }
    
    public func changeTrackVisbility(for participant: CallParticipant, isVisible: Bool) {
        Task {
            await callController?.changeTrackVisibility(for: participant, isVisible: isVisible)
        }
    }
    
    private func enterCall(callId: String, participantIds: [String]) {
        guard let callController = callController else {
            return
        }

        Task {
            do {
                log.debug("Starting call")
                let callType = CallType.default
                let options = VideoOptions()
                let room: Room = try await callController.joinCall(
                    callType: callType,
                    callId: callId,
                    callSettings: callSettings,
                    videoOptions: options,
                    participantIds: participantIds
                )
                self.room = room
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
                calling = false
            }
        }
    }
    
    public func leaveCall() {
        calling = false
        streamVideo.leaveCall()
        room = nil
        currentEventsTask?.cancel()
    }
    
    private func listenForParticipantEvents() {
        guard let room = room else {
            return
        }
        currentEventsTask = Task {
            for await event in room.participantEvents() {
                self.participantEvent = event
                // The event is shown for 2 seconds.
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                self.participantEvent = nil
            }
        }
    }
    
    private func checkRoomDisplay() {
        shouldShowRoomView = (connectionStatus == .connected || connectionStatus == .reconnecting)
            && (callParticipants.count > 1 || streamVideo.videoConfig.joinVideoCallInstantly)
    }
}

public struct User: Identifiable, Equatable {
    public let name: String
    public let token: String
    public var id: String {
        name
    }
}
