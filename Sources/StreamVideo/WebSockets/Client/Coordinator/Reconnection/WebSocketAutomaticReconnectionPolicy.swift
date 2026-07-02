//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// Coordinator reconnection policies, re-implemented against StreamCore's public
// APIs (StreamCore's own policies are `internal`, so they can't be composed with
// video-specific ones like ``CallKitReconnectionPolicy``). Used to build the
// StreamCore `DefaultConnectionRecoveryHandler` inside ``CoordinatorWebSocket``.

/// Allows reconnection only when the socket's state permits it (e.g. not on
/// invalid-token / client errors).
///
/// - TODO: [StreamCore migration] Delete this and reuse StreamCore's own
///   `WebSocketAutomaticReconnectionPolicy` (+ its convenience init) once
///   StreamCore makes that policy `public`. Currently it's `internal`, so we
///   re-implement it here. Logic is identical.
struct WebSocketAutomaticReconnectionPolicy: StreamCore.AutomaticReconnectionPolicy {
    private let webSocketClient: StreamCore.WebSocketClient

    init(_ webSocketClient: StreamCore.WebSocketClient) {
        self.webSocketClient = webSocketClient
    }

    func canBeReconnected() -> Bool {
        webSocketClient.connectionState.isAutomaticReconnectionEnabled
    }
}
