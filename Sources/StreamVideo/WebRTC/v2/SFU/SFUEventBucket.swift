//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// A class that collects and processes events received by the `SFUAdapter`.
///
/// The `SFUEventBucket` class works in conjunction with the `SFUAdapter` to
/// collect all events received by the adapter up to the point where someone
/// tries to consume them. When events are consumed, the observation stops,
/// and the class filters the collected events to find the ones requested.
/// All actions are processed in the same queue to ensure thread safety and
/// synchronization.
final class SFUEventBucket {

    private let processingQueue = DispatchQueue(label: "io.getstream.sfu.event.bucket")
    private var observable: AnyCancellable?
    private var items: [Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload] = []

    init(_ sfuAdapter: SFUAdapter) {
        observable = sfuAdapter
            .publisher
            .receive(on: processingQueue)
            .sink { [weak self] in self?.items.append($0) }
    }

    /// Consumes and returns events of the specified type.
    ///
    /// This method stops the observation of new events and filters the collected
    /// events to return only those that match the specified type.
    ///
    /// - Parameter eventType: The type of events to consume.
    /// - Returns: An array of events that match the specified type.
    func consume<EventType>(_ eventType: EventType.Type) -> [Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload] {
        // Cancel the observation of new events.
        observable?.cancel()
        
        // Filter and return the collected events that match the specified type.
        let items = processingQueue.sync { self.items.filter { $0.payload(EventType.self) != nil } }
        return items
    }
}
