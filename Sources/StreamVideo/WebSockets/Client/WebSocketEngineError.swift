//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Error surfaced by the WebSocket engine.
///
/// Retained after the StreamCore WebSocket migration (extracted from the deleted
/// `WebSocketEngine`) because ``WebSocketConnectionState/isAutomaticReconnectionEnabled``
/// still inspects it to avoid reconnecting on `stop` errors.
struct WebSocketEngineError: Error {
    static let stopErrorCode = 1000

    let reason: String
    let code: Int
    let engineError: Error?

    var localizedDescription: String { reason }
}

extension WebSocketEngineError {
    init(error: Error?) {
        if let error = error {
            self.init(
                reason: error.localizedDescription,
                code: (error as NSError).code,
                engineError: error
            )
        } else {
            self.init(
                reason: "Unknown",
                code: 0,
                engineError: nil
            )
        }
    }
}
