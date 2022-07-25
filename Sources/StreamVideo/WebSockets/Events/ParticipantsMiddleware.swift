//
//  ParticipantsMiddleware.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 23.7.22.
//

import Foundation

class ParticipantsMiddleware: EventMiddleware {
    
    var room: VideoRoom?
    
    func handle(event: Event) -> Event? {
        if let participantJoined = event as? Stream_Video_ParticipantJoined {
            room?.add(participant: participantJoined.participant)
        } else if let participantLeft = event as? Stream_Video_ParticipantLeft {
            room?.remove(participant: participantLeft.participant)
        }
        
        return event
    }
    
}
