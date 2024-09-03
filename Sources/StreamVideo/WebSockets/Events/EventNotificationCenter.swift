//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

/// The type is designed to pre-process some incoming `Event` via middlewares before being published
class EventNotificationCenter: NotificationCenter {
    private(set) var middlewares: [EventMiddleware] = []

    var eventPostingQueue = DispatchQueue(label: "io.getstream.event-notification-center")
    
    func add(middlewares: [EventMiddleware]) {
        self.middlewares.append(contentsOf: middlewares)
    }

    func add(middleware: EventMiddleware) {
        middlewares.append(middleware)
    }

    func process(_ events: [WrappedEvent], postNotifications: Bool = true, completion: (() -> Void)? = nil) {
        let processingEventsDebugMessage: () -> String = {
            let eventNames = events.map(\.name)
            return "Processing webSocket events: \(eventNames)"
        }
        log.debug(processingEventsDebugMessage(), subsystems: .webSocket)

        var eventsToPost = [Event]()
        eventsToPost = events.compactMap {
            self.middlewares.process(event: $0)
        }
        
        guard postNotifications else {
            completion?()
            return
        }

        eventPostingQueue.async {
            eventsToPost.forEach { self.post(Notification(newEventReceived: $0, sender: self)) }
            completion?()
        }
    }
}

extension EventNotificationCenter {
    func process(_ event: WrappedEvent, postNotification: Bool = true, completion: (() -> Void)? = nil) {
        process([event], postNotifications: postNotification, completion: completion)
    }
}
