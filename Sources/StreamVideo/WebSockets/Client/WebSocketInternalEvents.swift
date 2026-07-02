//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Internal marker events emitted on coordinator connect/disconnect. Retained
// from the deleted video `WebSocketClient` since `StreamVideo` still publishes
// them.

struct WSDisconnected: Event {}
struct WSConnected: Event {}

// Event delivery over `NotificationCenter`, retained from the deleted video
// `WebSocketClient` (the coordinator event pipeline still posts/reads events
// this way via `EventNotificationCenter`).

extension Notification.Name {
    static let NewEventReceived = Notification.Name("io.getStream.video.core.new_event_received")
}

extension Notification {
    private static let eventKey = "io.getStream.video.core.event_key"

    init(newEventReceived event: Event, sender: Any) {
        self.init(name: .NewEventReceived, object: sender, userInfo: [Self.eventKey: event])
    }

    var event: WrappedEvent? {
        userInfo?[Self.eventKey] as? WrappedEvent
    }
}
