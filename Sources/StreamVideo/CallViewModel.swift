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
public class CallViewModel: ObservableObject  {
    
    @Injected(\.streamVideo) var streamVideo
    @Injected(\.callCoordinatorService) var callCoordinatorService
    
    @Published public var room: VideoRoom? {
        didSet {
            self.connectionStatus = room?.connectionStatus ?? .disconnected(reason: nil)
            self.remoteParticipants = roomParticipants
        }
    }
    @Published public var focusParticipant: RoomParticipant?
    @Published public var connectionStatus: ConnectionStatus = .disconnected(reason: nil) {
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
    
    private var url: String = "wss://livekit.fucking-go-slices.com"
    private var token: String = ""
            
    @Published public var remoteParticipants: OrderedDictionary<String, RoomParticipant> = [:]
    
    public init() {}

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
            DispatchQueue.main.async {
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

    public func makeCall() {
        Task {
            do {
                loading = true
                log.debug("Starting call")
                try await selectEdgeServer()
                log.debug("Joining room")
                let room = try await streamVideo.joinRoom(url: url, token: token, options: VideoOptions())
                self.room = room
                self.room?.addDelegate(self)
                toggleCameraEnabled()
                loading = false
            } catch {
                log.error("Error starting a call \(error.localizedDescription)")
                loading = false
            }
        }
    }
    
    public func leaveCall() {
        self.room?.disconnect()
    }
    
    private func selectEdgeServer() async throws {
        var selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
        selectEdgeRequest.callID = "1234"
        let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
        url = "wss://\(response.edgeServer.url)"
        token = response.token
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
