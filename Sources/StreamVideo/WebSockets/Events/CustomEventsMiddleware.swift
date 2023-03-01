//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class CustomEventsMiddleware: EventMiddleware {
    
    var onCustomEvent: ((CustomEvent) -> Void)?
    var onNewReaction: ((CallReaction) -> Void)?
    
    func handle(event: Event) -> Event? {
        if let event = event as? CustomVideoEvent {
            let customEvent = event.toCustomEvent()
            onCustomEvent?(customEvent)
        } else if let event = event as? CallReactionEvent {
            let reaction = event.toVideoReaction()
            onNewReaction?(reaction)
        }
        return event
    }
}
