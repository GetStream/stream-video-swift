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
    
    private var url: String = "wss://livekit.fucking-go-slices.com"
    
    @Published public var users = mockUsers
    
    @Published public var selectedUser: User?
    
    let callCoordinatorService = Stream_Video_CallCoordinatorService(
        hostname: "http://localhost:26991",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoidG9tbWFzbyJ9.XGkxJKi33fHr3cHyLFc6HRnbPgLuwNHuETWQ2MWzz5c"
    )
    
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

    public func selectEdgeServer() {
        Task {
            let selectEdgeRequest = Stream_Video_SelectEdgeServerRequest()
            let response = try await callCoordinatorService.selectEdgeServer(selectEdgeServerRequest: selectEdgeRequest)
            url = "wss://\(response.edgeServer.url)"
        }
    }
    
    public func makeCall() async throws {
        if selectedUser == nil {
            selectedUser = users.first
        }
        
        let token = selectedUser?.token ?? ""
        
        let room = try await streamVideo.connect(url: url, token: token, options: VideoOptions())
        self.room = room
        self.room?.addDelegate(self)
        toggleCameraEnabled()
    }
    
}

extension CallViewModel: VideoRoomDelegate {
    
    // MARK: - RoomDelegate

    nonisolated public func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {
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

    nonisolated public func room(
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
    
    nonisolated public func room(_ room: Room, participantDidJoin participant: RemoteParticipant) {
        DispatchQueue.main.async {
            self.remoteParticipants = self.roomParticipants
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

//TODO: Remove from here.
let mockUsers = [
    User(
        name: "User 1",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI0NjEsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDQ2MSwic3ViIjoicm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.vKC-RXDSYGqeyChwazQLO15mV1S1n4LxyeJLrJASYPA"),
    User(
        name: "User 2",
        token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE2NTkwMjI1MzMsImlzcyI6IkFQSVM0Y2F6YXg5dnFRUSIsIm5iZiI6MTY1NjQzMDUzMywic3ViIjoiYm9iIiwidmlkZW8iOnsicm9vbSI6InN0YXJrLXRvd2VyIiwicm9vbUpvaW4iOnRydWV9fQ.XTQ9nU5BJ3FdWUaOrge-u977YibNTfK-sTDRaI0_vRc")
]
