//
//  Room.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import SwiftUI
import LiveKit
import OrderedCollections
import AVFoundation
import Promises

import WebRTC
import CoreImage.CIFilterBuiltins
import ReplayKit

extension ObservableParticipant {

    public var mainVideoPublication: TrackPublication? {
        firstScreenSharePublication ?? firstCameraPublication
    }

    public var mainVideoTrack: VideoTrack? {
        firstScreenShareVideoTrack ?? firstCameraVideoTrack
    }

    public var subVideoTrack: VideoTrack? {
        firstScreenShareVideoTrack != nil ? firstCameraVideoTrack : nil
    }
}

class VideoRoom: ObservableRoom {

    let queue = DispatchQueue(label: "example.observableroom")
    
    @Published var focusParticipant: ObservableParticipant?
    @Published var connectionStatus: ConnectionStatus = .disconnected(reason: nil)
    
    static func create(with room: Room) -> VideoRoom {
        return VideoRoom(room: room)
    }
    
    private init(room: Room) {
        super.init(room)
        self.connectionStatus = room.connectionState.mapped
    }

    // MARK: - RoomDelegate

    override internal func room(_ room: Room, didUpdate connectionState: ConnectionState, oldValue: ConnectionState) {
        super.room(room, didUpdate: connectionState, oldValue: oldValue)
        
        self.connectionStatus = connectionState.mapped
        
        if case .disconnected = connectionState {
            DispatchQueue.main.async {
                // Reset state
                self.focusParticipant = nil
                self.objectWillChange.send()
            }
        }
    }

    override internal func room(_ room: Room,
                       participantDidLeave participant: RemoteParticipant) {
        DispatchQueue.main.async {
            // self.participants.removeValue(forKey: participant.sid)
            if let focusParticipant = self.focusParticipant,
               focusParticipant.sid == participant.sid {
                self.focusParticipant = nil
            }
            self.objectWillChange.send()
        }
    }

    override internal func room(_ room: Room,
                       participant: RemoteParticipant?, didReceive data: Data) {
        print("did receive data \(data)")
    }
}

struct VideoOptions {
    //TODO:
}

public enum ConnectionStatus: Equatable {
    case disconnected(reason: DisconnectionReason? = nil)
    case connecting
    case reconnecting
    case connected
}

public enum DisconnectionReason: Equatable {
    
    public static func == (lhs: DisconnectionReason, rhs: DisconnectionReason) -> Bool {
        switch (lhs, rhs) {
        case (.user, .user):
            return true
        case (.networkError(_), .networkError(_)):
            return true
        default:
            return false
        }
    }
    
    case user // User initiated
    case networkError(_ error: Error)
}

extension DisconnectReason {
    
    var mapped: DisconnectionReason {
        switch self {
        case .user:
            return .user
        case .networkError(let error):
            return .networkError(error)
        }
    }
    
}

extension ConnectionState {
    
    var mapped: ConnectionStatus {
        switch self {
        case .disconnected(reason: let reason):
            return .disconnected(reason: reason?.mapped)
        case .connected:
            return .connected
        case .reconnecting:
            return .reconnecting
        case .connecting:
            return .connecting
        }
    }
    
}
