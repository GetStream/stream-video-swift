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
            let participant = participantJoined.participant.toCallParticipant()
            log.debug("Received participant joined event with id \(participant.id)")
            room?.add(participant: participant)
        } else if let participantLeft = event as? Stream_Video_ParticipantLeft {
            let participant = participantLeft.participant.toCallParticipant()
            log.debug("Received participant left event with id \(participant.id)")
            room?.remove(participant: participant)
        } else if let participantUpdated = event as? Stream_Video_ParticipantUpdated {
            let participant = participantUpdated.participant.toCallParticipant()
            log.debug("Received participant updated event with id \(participant.id)")
            room?.add(participant: participant)
        } else if let participantInvited = event as? Stream_Video_ParticipantInvited {
            let participant = participantInvited.participant.toCallParticipant()
            log.debug("Received participant invited event with id \(participant.id)")
            room?.add(participant: participant)
        }
        
        return event
    }
    
}
