//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Allows reconnection only while the app is active (foreground).
///
/// - TODO: [StreamCore migration] Delete this and reuse StreamCore's own
///   `BackgroundStateReconnectionPolicy` once StreamCore makes it `public`.
///   Currently `internal`, so re-implemented here. Logic is identical.
struct BackgroundStateReconnectionPolicy: StreamCore.AutomaticReconnectionPolicy {
    private let backgroundTaskScheduler: StreamCore.BackgroundTaskScheduler?

    init(_ backgroundTaskScheduler: StreamCore.BackgroundTaskScheduler?) {
        self.backgroundTaskScheduler = backgroundTaskScheduler
    }

    func canBeReconnected() -> Bool {
        backgroundTaskScheduler?.isAppActive ?? true
    }
}
