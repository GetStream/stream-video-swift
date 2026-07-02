//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Boxes a video `WrappedEvent` as a `StreamCore.Event`.
///
/// The coordinator socket runs on `StreamCore.WebSocketClient`, whose pipeline is
/// typed on `StreamCore.Event`. We keep video's own event types + middleware
/// handling, so decoded coordinator events are carried through StreamCore inside
/// this box and unboxed at the `CoordinatorWebSocket` boundary.
///
/// - TODO: [StreamCore migration] This boxing exists only because video keeps
///   its own `Event`/`EventNotificationCenter` pipeline. Once the event system
///   is unified on StreamCore (leaf migration), events can flow through
///   StreamCore's pipeline directly and this box + decoder can be removed.
struct CoordinatorEvent: StreamCore.Event {
    let wrapped: WrappedEvent

    /// Surfaces the connection id to StreamCore so it can populate its connected
    /// state (StreamCore drives the auth handshake off `healthcheck()`).
    func healthcheck() -> StreamCore.HealthCheckInfo? {
        guard let info = wrapped.healthcheck() else { return nil }
        return StreamCore.HealthCheckInfo(
            connectionId: info.coordinatorHealthCheck?.connectionId,
            participantCount: nil
        )
    }

    func error() -> Error? {
        wrapped.error()
    }
}

/// A `StreamCore.AnyEventDecoder` that reuses video's `JsonEventDecoder` and
/// boxes the result so it can flow through `StreamCore.WebSocketClient`.
struct CoordinatorEventDecoder: StreamCore.AnyEventDecoder {
    private let base = JsonEventDecoder()

    func decode(from data: Data) throws -> StreamCore.Event {
        CoordinatorEvent(wrapped: try base.decode(from: data))
    }
}
