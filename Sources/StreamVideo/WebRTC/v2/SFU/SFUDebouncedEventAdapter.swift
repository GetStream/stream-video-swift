//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

final class SFUEventBucket {

    private var observable: AnyCancellable?
    private let processingQueue = DispatchQueue(label: "sfu.event.bucket")
    private var items: [Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload] = []

    init(_ sfuAdapter: SFUAdapter) {
        observable = sfuAdapter
            .publisher
            .receive(on: processingQueue)
            .sink { [weak self] in self?.items.append($0) }
    }

    func consume<EventType>(_ eventType: EventType.Type) -> [Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload] {
        observable?.cancel()
        let items = processingQueue.sync { self.items.filter { $0.payload(EventType.self) != nil } }
        return items
    }
}
