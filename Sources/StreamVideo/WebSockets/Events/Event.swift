//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: Sendable {}

public protocol SendableEvent: Event, ProtoModel {}

extension Event {
    var name: String {
        String(describing: Self.self)
    }
}
