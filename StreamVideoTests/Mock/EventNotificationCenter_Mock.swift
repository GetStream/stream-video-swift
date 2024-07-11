//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// Mock implementation of `EventNotificationCenter`
final class EventNotificationCenter_Mock: EventNotificationCenter {

    lazy var mock_process = MockFunc<([WrappedEvent], Bool, (() -> Void)?), Void>.mock(for: process)

    override func process(
        _ events: [WrappedEvent],
        postNotifications: Bool = true,
        completion: (@Sendable() -> Void)? = nil
    ) {
        super.process(events, postNotifications: postNotifications, completion: completion)

        mock_process.call(with: (events, postNotifications, completion))
    }
}
