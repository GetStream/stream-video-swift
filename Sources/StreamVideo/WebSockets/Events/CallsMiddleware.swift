//
//  CallsMiddleware.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 23.7.22.
//

import Foundation

class CallsMiddleware: EventMiddleware {
    
    var onCallCreated: ((IncomingCall) -> ())?
    
    func handle(event: Event) -> Event? {
        if let callCreated = event as? Stream_Video_CallCreated {
            log.debug("Received call created \(callCreated)")
            let id = callCreated.call.id
            let userId = callCreated.call.createdByUserID
            let incomingCall = IncomingCall(id: id, callerId: userId)
            onCallCreated?(incomingCall)
        }
        
        return event
    }
    
}
