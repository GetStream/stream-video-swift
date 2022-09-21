//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class CallsMiddleware: EventMiddleware {
    
    var onCallCreated: ((IncomingCall) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let incomingCallEvent = event as? IncomingCallEvent {
            log.debug("Received call created \(incomingCallEvent)")
            let cId = incomingCallEvent.proto.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let userId = incomingCallEvent.createdBy
            let type = incomingCallEvent.type
            let incomingCall = IncomingCall(
                id: id,
                callerId: userId,
                type: type,
                participants: incomingCallEvent.users.map { $0.toCallParticipant() }
            )
            onCallCreated?(incomingCall)
        }
        
        return event
    }
}
