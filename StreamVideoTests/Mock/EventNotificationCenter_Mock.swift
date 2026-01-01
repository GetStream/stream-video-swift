//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// Mock implementation of `EventNotificationCenter`
final class EventNotificationCenter_Mock: EventNotificationCenter, @unchecked Sendable {

    lazy var mock_process = MockFunc<([WrappedEvent], Bool, (@Sendable () -> Void)?), Void>.mock(for: process)

    override func process(
        _ events: [WrappedEvent],
        postNotifications: Bool = true,
        completion: (@Sendable () -> Void)? = nil
    ) {
        super.process(events, postNotifications: postNotifications, completion: completion)

        mock_process.call(with: (events, postNotifications, completion))
    }
}
