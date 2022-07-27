//
//  Room.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import SwiftUI
import LiveKit
import AVFoundation

public class VideoRoom: ObservableObject {
        
    private let room: Room
    
    @Published var participants = [String: CallParticipant]() {
        didSet {
            log.debug("Participants changed: \(participants)")
        }
    }
    
    static func create(with room: Room) -> VideoRoom {
        return VideoRoom(room: room)
    }
    
    private init(room: Room) {
        self.room = room
    }
    
    func addDelegate(_ delegate: VideoRoomDelegate) {
        self.room.add(delegate: delegate)
    }
    
    func disconnect() {
        self.room.disconnect()
    }
    
    func add(participants: [CallParticipant]) {
        var result = [String: CallParticipant]()
        for participant in participants {
            result[participant.id] = participant
        }
        self.participants = result
    }
    
    func clearParticipants() {
        self.participants = [:]
    }
    
    func add(participant: CallParticipant) {
        participants[participant.id] = participant
    }
    
    func remove(participant: CallParticipant) {
        participants[participant.id] = nil
    }
    
    internal var remoteParticipants: [Sid : RemoteParticipant] {
        self.room.remoteParticipants
    }
    
    internal var localParticipant: LocalParticipant? {
        self.room.localParticipant
    }
    
    internal var connectionStatus: VideoConnectionStatus {
        self.room.connectionState.mapped
    }
}

typealias VideoRoomDelegate = RoomDelegate

public struct VideoOptions {
    //TODO:
}
