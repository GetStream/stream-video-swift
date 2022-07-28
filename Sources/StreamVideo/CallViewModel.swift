//
//  CallViewModel.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 29.6.22.
//

import SwiftUI
import Combine
import LiveKit
import Promises
import OrderedCollections

@MainActor
open class CallViewModel: ObservableObject  {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published public var room: VideoRoom? {
        didSet {
            self.connectionStatus = room?.connectionStatus ?? .disconnected(reason: nil)
            self.remoteParticipants = roomParticipants
            self.room?.$participants.receive(on: RunLoop.main).sink(receiveValue: { [weak self] participants in
                self?.callParticipants = participants
            })
            .store(in: &cancellables)
        }
    }
    @Published public var focusParticipant: RoomParticipant?
    @Published public var connectionStatus: VideoConnectionStatus = .disconnected(reason: nil) {
        didSet {
            self.shouldShowRoomView = connectionStatus == .connected || connectionStatus == .reconnecting
        }
    }
    @Published public var cameraTrackState: StreamTrackPublishState = .notPublished()
    @Published public var microphoneTrackState: StreamTrackPublishState = .notPublished()

    
    public var shouldShowRoomView: Bool = false
    
    @Published public var shouldShowError: Bool = false
    public var latestError: Error?
    
    @Published public var loading = false
                
    //TODO: LiveKit
    @Published public var remoteParticipants: OrderedDictionary<String, RoomParticipant> = [:]
    
    @Published public var participantsShown = false
    
    @Published public var callParticipants = [String: CallParticipant]()
    
    @Published public var participantEvent: ParticipantEvent?
    
    private var url: String = "wss://livekit.fucking-go-slices.com"
    private var token: String = ""
    
    private var cancellables = Set<AnyCancellable>()
    private var currentEventsTask: Task<Void, Never>?
    
    public var onlineParticipants: [CallParticipant] {
        callParticipants.filter { $0.value.isOnline }.map { $0.value }
    }
    
    public var offlineParticipants: [CallParticipant] {
        callParticipants.filter { !$0.value.isOnline }.map { $0.value }
    }
    
    public init() {}

    //TODO: LiveKit
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
    
    //TODO: LiveKit
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
                        let event: Stream_Video_UserEventType = self.microphoneTrackState.isPublished ? .audioUnmuted : .audioMutedUnspecified
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
        guard case .published(let publication) = self.cameraTrackState,
              let track = publication.track as? LocalVideoTrack,
              let cameraCapturer = track.capturer as? CameraCapturer else {
            return
        }

        cameraCapturer.switchCameraPosition()
    }

    public func startCall(callId: String, participantIds: [String]) {
        Task {
            do {
                loading = true
                log.debug("Starting call")
                let callType = CallType(name: "video")
                let room = try await streamVideo.startCall(
                    callType: callType,
                    callId: callId,
                    videoOptions: VideoOptions(),
                    participantIds: participantIds
                )
                self.room = room
                self.room?.addDelegate(self)
                listenForParticipantEvents()
                toggleCameraEnabled()
                loading = false
                log.debug("Started call")
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                loading = false
            }
        }
    }
    
    public func joinCall(callId: String) {
        Task {
            do {
                loading = true
                log.debug("Joining call")
                let callType = CallType(name: "video")
                let room = try await streamVideo.joinCall(
                    callType: callType,
                    callId: callId,
                    videoOptions: VideoOptions()
                )
                self.room = room
                self.room?.addDelegate(self)
                listenForParticipantEvents()
                toggleCameraEnabled()
                loading = false
                log.debug("Joined call")
            } catch {
                log.error("Error joining a call \(error.localizedDescription)")
                loading = false
            }
        }
    }
    
    public func leaveCall() {
        self.streamVideo.leaveCall()
        self.room?.disconnect()
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
