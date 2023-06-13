//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

class WSEventsMiddleware: EventMiddleware {
    
    private var subscribers = NSHashTable<AnyObject>.weakObjects()
    
    func handle(event: Event) -> Event? {
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
    
    func onEvent(_ event: Event)
    
}
