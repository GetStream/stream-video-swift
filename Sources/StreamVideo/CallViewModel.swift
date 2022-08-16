//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Combine
import LiveKit
import OrderedCollections
import Promises
import SwiftUI

@MainActor
open class CallViewModel: ObservableObject {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public var room: VideoRoom? {
        didSet {
            connectionStatus = room?.connectionStatus ?? .disconnected(reason: nil)
            remoteParticipants = roomParticipants
            room?.$participants.receive(on: RunLoop.main).sink(receiveValue: { [weak self] participants in
                self?.callParticipants = participants
            })
                .store(in: &cancellables)
        }
    }

    @Published public var focusParticipant: RoomParticipant?
    @Published public var connectionStatus: VideoConnectionStatus = .disconnected(reason: nil) {
        didSet {
            checkRoomDisplay()
        }
    }

    @Published public var cameraTrackState: StreamTrackPublishState = .notPublished()
    @Published public var microphoneTrackState: StreamTrackPublishState = .notPublished()

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
                
    // TODO: LiveKit
    @Published public var remoteParticipants: OrderedDictionary<String, RoomParticipant> = [:] {
        didSet {
            checkRoomDisplay()
        }
    }
    
    @Published public var participantsShown = false
    
    @Published public var inviteParticipantsShown = false
    
    @Published public var callParticipants = [String: CallParticipant]()
    
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

    // TODO: LiveKit
    public var allParticipants: OrderedDictionary<String, RoomParticipant> {
        var result = remoteParticipants
        if let localParticipant = room?.localParticipant {
            result.updateValue(
                RoomParticipant(participant: localParticipant),
                forKey: localParticipant.sid,
                insertingAt: 0
            )
        }
        return result
    }
    
    // TODO: LiveKit
    private var roomParticipants: OrderedDictionary<String, RoomParticipant> {
        guard let room = room else {
            return [:]
        }
        return OrderedDictionary(uniqueKeysWithValues: room.remoteParticipants.map { (sid, participant) in
            (sid, RoomParticipant(participant: participant))
        })
    }
    
    public func toggleCameraEnabled() {
        guard let localParticipant = room?.localParticipant else {
            return
        }
        
        // TODO: connect this properly.
        withAnimation {
            self.callSettings = CallSettings(
                audioOn: self.microphoneTrackState.isPublished,
                videoOn: !self.callSettings.videoOn,
                speakerOn: self.callSettings.speakerOn
            )
        }

        guard !cameraTrackState.isBusy else {
            return
        }

        DispatchQueue.main.async {
            self.cameraTrackState = .busy(isPublishing: !self.cameraTrackState.isPublished)
        }

        localParticipant.setCamera(enabled: !cameraTrackState.isPublished).then(on: .sdk) { publication in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                defer {
                    DispatchQueue.main.async {
                        let event: Stream_Video_UserEventType = self.cameraTrackState.isPublished ? .videoStarted : .videoStopped
                        self.streamVideo.sendEvent(type: event)
                    }
                }
                guard let publication = publication else {
                    self.cameraTrackState = .notPublished()
                    return
                }

                self.cameraTrackState = .published(publication)
            }
        }.catch(on: .sdk) { error in
            DispatchQueue.main.async {
                self.cameraTrackState = .notPublished(error: error)
            }
        }
    }
    
    public func toggleMicrophoneEnabled() {
        guard let localParticipant = room?.localParticipant else {
            return
        }
        
        // TODO: connect this properly.
        callSettings = CallSettings(
            audioOn: microphoneTrackState.isPublished,
            videoOn: callSettings.videoOn,
            speakerOn: !callSettings.speakerOn
        )

        guard !microphoneTrackState.isBusy else {
            return
        }

        DispatchQueue.main.async {
            self.microphoneTrackState = .busy(isPublishing: !self.microphoneTrackState.isPublished)
        }

        localParticipant.setMicrophone(enabled: !microphoneTrackState.isPublished).then(on: .sdk) { publication in
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                defer {
                    DispatchQueue.main.async {
                        let event: Stream_Video_UserEventType = self.microphoneTrackState
                            .isPublished ? .audioUnmuted : .audioMutedUnspecified
                        self.streamVideo.sendEvent(type: event)
                    }
                }
                guard let publication = publication else {
                    self.microphoneTrackState = .notPublished()
                    return
                }

                self.microphoneTrackState = .published(publication)
            }
        }.catch(on: .sdk) { error in
            DispatchQueue.main.async {
                self.microphoneTrackState = .notPublished(error: error)
            }
        }
    }
    
    public func toggleCameraPosition() {
        guard case let .published(publication) = cameraTrackState,
              let track = publication.track as? LocalVideoTrack,
              let cameraCapturer = track.capturer as? CameraCapturer else {
            return
        }

        cameraCapturer.switchCameraPosition()
    }

    public func startCall(callId: String, participantIds: [String]) {
        calling = true
        enterCall(callId: callId, participantIds: participantIds, isStarted: false)
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
                self.room?.addDelegate(self)
                listenForParticipantEvents()
                if callSettings.audioOn && !self.microphoneTrackState.isPublished {
                    toggleMicrophoneEnabled()
                }
                if callSettings.videoOn && !self.cameraTrackState.isPublished {
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
        room?.disconnect()
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
            && (!remoteParticipants.isEmpty || streamVideo.videoConfig.joinVideoCallInstantly)
    }
}

extension CallViewModel: VideoRoomDelegate {
    
    // MARK: - RoomDelegate

    nonisolated public func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionStatus = connectionState.mapped
            log.debug("Connection status changed to \(self.connectionStatus)")
        }
        
        if case .disconnected = connectionState {
            DispatchQueue.main.async {
                // Reset state
                self.focusParticipant = nil
            }
        }
    }

    nonisolated public func room(
        _ room: Room,
        participantDidLeave participant: RemoteParticipant
    ) {
        let remoteParticipant = RoomParticipant(participant: participant)
        log.debug("Participant \(participant.name) left the room.")
        
        DispatchQueue.main.async {
            self.remoteParticipants = self.roomParticipants
            if let focusParticipant = self.focusParticipant,
               focusParticipant.id == remoteParticipant.id {
                self.focusParticipant = nil
            }
        }
    }
    
    nonisolated public func room(_ room: Room, participantDidJoin participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.remoteParticipants = self.roomParticipants
            log.debug("Participant \(participant.name) joined the room.")
        }
    }
}

public struct User: Identifiable, Equatable {
    public let name: String
    public let token: String
    public var id: String {
        name
    }
}
