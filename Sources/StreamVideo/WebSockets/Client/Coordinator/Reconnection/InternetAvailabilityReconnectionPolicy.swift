//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Allows reconnection only while the internet is available.
///
/// - TODO: [StreamCore migration] Delete this and reuse StreamCore's own
///   `InternetAvailabilityReconnectionPolicy` once StreamCore makes it `public`.
///   Currently `internal`, so re-implemented here. Logic is identical.
struct InternetAvailabilityReconnectionPolicy: StreamCore.AutomaticReconnectionPolicy {
    private let internetConnection: StreamCore.InternetConnection

    init(_ internetConnection: StreamCore.InternetConnection) {
        self.internetConnection = internetConnection
    }

    func canBeReconnected() -> Bool {
        internetConnection.status.isAvailable
    }
}
