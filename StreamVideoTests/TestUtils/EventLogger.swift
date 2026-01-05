//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// The type can be used to check the events published by `NotificationCenter`
final class EventLogger {
    @Atomic var events: [Event] = []
    var equatableEvents: [EquatableEvent] { events.map(EquatableEvent.init) }

    init(_ notificationCenter: NotificationCenter) {
        notificationCenter.addObserver(
            self,
            selector: #selector(handleNewEvent),
            name: .NewEventReceived,
            object: nil
        )
    }

    @objc
    func handleNewEvent(_ notification: Notification) {
        guard let event = notification.event else {
            return
        }
        switch event {
        case let .internalEvent(event):
            events.append(event)
        case let .coordinatorEvent(event):
            events.append(event)
        case .sfuEvent:
            break
        }
    }
}
