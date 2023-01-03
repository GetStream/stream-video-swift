//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CallsMiddleware: EventMiddleware {

    var onCallEvent: ((CallEvent) -> Void)?

    func handle(event: Event) -> Event? {
        if let incomingCallEvent = event as? IncomingCallEvent {
            log.debug("Received call created \(incomingCallEvent)")
            let cId = incomingCallEvent.callCid
            let id = cId.components(separatedBy: ":").last ?? cId
            let userId = incomingCallEvent.createdBy
            let type = incomingCallEvent.type
            let incomingCall = IncomingCall(
                id: id,
                callerId: userId,
                type: type,
                participants: incomingCallEvent.users.map { $0.toCallParticipant() }
            )
            onCallEvent?(.incoming(incomingCall))
        } else if let event = event as? CallEventInfo {
            var callEvent: CallEvent
            switch event.action {
            case .accept:
                callEvent = .accepted(event)
            case .reject:
                callEvent = .rejected(event)
            case .cancel:
                callEvent = .canceled(event)
            }
            onCallEvent?(callEvent)
        }

        return event
    }
}
