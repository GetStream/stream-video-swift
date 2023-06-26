//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

final class WSEventsMiddleware: EventMiddleware {
    
    private var subscribers = NSHashTable<AnyObject>.weakObjects()

    // TODO: check if this is still correctly forwarding events to subscribers
    func handle(event: WrappedEvent) -> WrappedEvent? {
        var streamVideo: StreamVideo?
        for subscriber in subscribers.allObjects {
            if let subscriber = subscriber as? StreamVideo {
                streamVideo = subscriber
            } else {
                (subscriber as? WSEventsSubscriber)?.onEvent(event)
            }
        }
        streamVideo?.onEvent(event)
        
        return event
    }
    
    func add(subscriber: WSEventsSubscriber) {
        subscribers.add(subscriber)
    }
    
    func remove(subscriber: WSEventsSubscriber) {
        subscribers.remove(subscriber)
    }
    
    func removeAllSubscribers() {
        subscribers.removeAllObjects()
    }
}

protocol WSEventsSubscriber: AnyObject {
    
    func onEvent(_ event: WrappedEvent)
    
}
