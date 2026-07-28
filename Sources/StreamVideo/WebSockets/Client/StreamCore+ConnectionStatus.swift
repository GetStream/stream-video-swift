//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore

/// StreamVideo-specific mappings for StreamCore's connection status.
extension ConnectionStatus {
    /// Creates a connection status while preserving StreamVideo's token
    /// refresh flow.
    ///
    /// StreamVideo owns invalid-token recovery, so it remains in the
    /// connecting state while it refreshes the token and reconnects. All other
    /// states use StreamCore's default mapping.
    init(
        videoWebSocketConnectionState state: WebSocketConnectionState
    ) {
        if case let .disconnected(source) = state,
           source.serverError?.isInvalidTokenError == true {
            self = .connecting
        } else {
            self.init(webSocketConnectionState: state)
        }
    }
}
