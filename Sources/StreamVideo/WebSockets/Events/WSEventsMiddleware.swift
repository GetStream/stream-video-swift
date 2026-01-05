//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

final class WSEventsMiddleware: EventMiddleware, @unchecked Sendable {

    private var subscribers = NSHashTable<AnyObject>.weakObjects()
    private let processingQueue = OperationQueue(maxConcurrentOperationCount: 1)

    func handle(event: WrappedEvent) -> WrappedEvent? {
        processingQueue.addTaskOperation { [weak self] in
            guard let self else { return }
            let allObjects = subscribers.allObjects
            var streamVideo: StreamVideo?
            for subscriber in allObjects {
                if let subscriber = subscriber as? StreamVideo {
                    streamVideo = subscriber
                } else {
                    await (subscriber as? WSEventsSubscriber)?.onEvent(event)
                }
            }
            await streamVideo?.onEvent(event)
        }

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
    
    func onEvent(_ event: WrappedEvent) async
}
