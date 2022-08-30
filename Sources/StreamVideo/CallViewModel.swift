//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import SwiftUI
import WebRTC

@MainActor
open class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public var room: VideoRoom? {
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
        
    private var url: String = "wss://livekit.fucking-go-slices.com"
    private var token: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var currentEventsTask: Task<Void, Never>?
    
    public var participants: [CallParticipant] {
        callParticipants
            .filter { $0.value.id != streamVideo.userInfo.id }
            .map(\.value)
            .sorted(by: { $0.name < $1.name })
    }
    
    public var onlineParticipants: [CallParticipant] {
        callParticipants
            .filter { $0.value.isOnline }
            .map(\.value)
            .sorted(by: { $0.name < $1.name })
    }
    
    public var offlineParticipants: [CallParticipant] {
        callParticipants
            .filter { !$0.value.isOnline }
            .map(\.value)
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
        if room == nil && streamVideo.currentRoom != nil {
            room = streamVideo.currentRoom
        }
    }

    public func toggleCameraEnabled() {
        Task {
            let isEnabled = !callSettings.videoOn
            try await streamVideo.changeVideoState(isEnabled: isEnabled)
            callSettings = CallSettings(
                audioOn: callSettings.audioOn,
                videoOn: isEnabled,
                speakerOn: callSettings.speakerOn
            )
        }
    }
    
    public func toggleMicrophoneEnabled() {
        Task {
            let isEnabled = !callSettings.audioOn
            try await streamVideo.changeAudioState(isEnabled: isEnabled)
            callSettings = CallSettings(
                audioOn: isEnabled,
                videoOn: callSettings.videoOn,
                speakerOn: callSettings.speakerOn
            )
        }
    }
    
    public func toggleCameraPosition() {
        let next = callSettings.cameraPosition.next()
        streamVideo.changeCameraMode(position: next)
        callSettings.cameraPosition = next
    }

    public func startCall(callId: String, participantIds: [String]) {
        calling = true
//        enterCall(callId: callId, participantIds: participantIds, isStarted: false)
        // NOTE: uncomment this to test SFU.
        Task {
            self.room = try await streamVideo.testSFU()
            calling = false
            // TODO: only temporarly.
            shouldShowRoomView = true
        }
    }
    
    public func joinCall(callId: String) {
        enterCall(callId: callId, participantIds: [], isStarted: true)
    }
    
    private func enterCall(callId: String, participantIds: [String], isStarted: Bool) {
        Task {
            do {
                log.debug("Starting call")
                let callType = CallType(name: "video")
                let options = VideoOptions()
                let room: VideoRoom
                if isStarted {
                    room = try await streamVideo.joinCall(
                        callType: callType,
                        callId: callId,
                        videoOptions: options
                    )
                } else {
                    room = try await streamVideo.startCall(
                        callType: callType,
                        callId: callId,
                        videoOptions: options,
                        participantIds: participantIds
                    )
                }
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
