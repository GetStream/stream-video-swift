//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Decodes raw SFU WebSocket frames into events for `StreamCore.WebSocketClient`.
///
/// Since the SFU socket now runs on StreamCore, this conforms to
/// `StreamCore.AnyEventDecoder` and returns a `StreamCore.Event` (the SFU
/// payload, which is made a `StreamCore.Event` in `SFUEvent+StreamCore.swift`).
/// Previously it conformed to video's `AnyEventDecoder` and returned a
/// `WrappedEvent.sfuEvent(...)`.
///
/// - TODO: [StreamCore migration] Tied to the SFU isolation wrapper; revisit
///   together with the event-system unification / wrapper retirement.
struct WebRTCEventDecoder: StreamCore.AnyEventDecoder {

    func decode(from data: Data) throws -> StreamCore.Event {
        let response = try Stream_Video_Sfu_Event_SfuEvent(serializedBytes: data)
        guard let payload = response.eventPayload else {
            // Unknown/empty payloads are skipped (logged, not surfaced) by the
            // client's decode loop when they throw `IgnoredEventType`.
            throw StreamCore.ClientError.IgnoredEventType()
        }
        return payload
    }
}
