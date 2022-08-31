//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class ParticipantsMiddleware: EventMiddleware {
    
    var room: Room?
    
    // TODO: probably not needed anymore.
    func handle(event: Event) -> Event? {
        if let participantJoined = event as? Stream_Video_ParticipantJoined {
            let participant = participantJoined.participant.toCallParticipant()
            log.debug("Received participant joined event with id \(participant.id)")
            room?.add(participant: participant)
            notifyRoom(with: participant, action: .join)
        } else if let participantLeft = event as? Stream_Video_ParticipantLeft {
            let participant = participantLeft.participant.toCallParticipant()
            log.debug("Received participant left event with id \(participant.id)")
            room?.remove(participant: participant)
            notifyRoom(with: participant, action: .leave)
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
    
    private func notifyRoom(with participant: CallParticipant, action: ParticipantAction) {
        let event = ParticipantEvent(
            id: participant.id,
            action: action,
            user: participant.name,
            imageURL: participant.profileImageURL
        )
        room?.onParticipantEvent?(event)
    }
}
