//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class CallsMiddleware: EventMiddleware {
    
    var onCallCreated: ((IncomingCall) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let callCreated = event as? Stream_Video_CallCreated {
            log.debug("Received call created \(callCreated)")
            let id = callCreated.call.id
            let userId = callCreated.call.createdByUserID
            let type = callCreated.call.type
            let incomingCall = IncomingCall(id: id, callerId: userId, type: type)
            onCallCreated?(incomingCall)
        }
        
        return event
    }
}
