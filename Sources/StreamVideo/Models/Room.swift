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
    
    private var participants = [String: Stream_Video_Participant]() {
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
    
    func add(participant: Stream_Video_Participant) {
        participants[participant.userID] = participant
    }
    
    func remove(participant: Stream_Video_Participant) {
        participants[participant.userID] = nil
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
