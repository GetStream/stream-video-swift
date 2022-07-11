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
import LiveKit
import OrderedCollections

@MainActor
class CallViewModel: ObservableObject, VideoRoomDelegate {
    
    @Injected(\.streamVideo) var streamVideo
    
    @Published var room: VideoRoom? {
        didSet {
            self.connectionStatus = room?.connectionStatus ?? .disconnected(reason: nil)
            self.remoteParticipants = roomParticipants
        }
    }
    @Published var focusParticipant: RoomParticipant?
    @Published var connectionStatus: ConnectionStatus = .disconnected(reason: nil) {
        didSet {
            self.shouldShowRoomView = connectionStatus == .connected || connectionStatus == .reconnecting
        }
    }
    @Published var cameraTrackState: StreamTrackPublishState = .notPublished()
    @Published var microphoneTrackState: StreamTrackPublishState = .notPublished()

    
    var shouldShowRoomView: Bool = false
    
    @Published var shouldShowError: Bool = false
    public var latestError: Error?
    
    private var url: String = "wss://livekit.fucking-go-slices.com"
    
    @Published var users = mockUsers
    
    @Published var selectedUser: User?
    
    let callCoordinatorService = Stream_Video_CallCoordinatorService(
        hostname: "http://localhost:26991",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.XGkxJKi33fHr3cHyLFc6HRnbPgLuwNHuETWQ2MWzz5c"
    )
    
    @Published public var remoteParticipants: OrderedDictionary<String, RoomParticipant> = [:]

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

    func selectEdgeServer() {
        Task {
            let selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
            let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
            url = "wss://\(response.edgeServer.url)"
        }
    }
    
    func makeCall() async throws {
        if selectedUser == nil {
            selectedUser = users.first
        }
        
        let token = selectedUser?.token ?? ""
        
        let room = try await streamVideo.connect(url: url, token: token, options: VideoOptions())
        self.room = room
        self.room?.addDelegate(self)
        toggleCameraEnabled()
    }
    
    // MARK: - RoomDelegate

    nonisolated func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {
        DispatchQueue.main.async {
            self.connectionStatus = connectionState.mapped
        }
        
        if case .disconnected = connectionState {
            DispatchQueue.main.async {
                // Reset state
                self.focusParticipant = nil
            }
        }
    }

    nonisolated func room(
        _ room: Room,
        participantDidLeave participant: RemoteParticipant
    ) {
        let remoteParticipant = RoomParticipant(participant: participant)
        DispatchQueue.main.async {
            self.remoteParticipants = self.roomParticipants
            if let focusParticipant = self.focusParticipant,
               focusParticipant.id == remoteParticipant.id {
                self.focusParticipant = nil
            }
        }
    }
    
    nonisolated func room(_ room: Room, participantDidJoin participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.remoteParticipants = self.roomParticipants
        }
    }

    
}

struct User: Identifiable, Equatable {
    let name: String
    let token: String
    var id: String {
        name
    }
}
