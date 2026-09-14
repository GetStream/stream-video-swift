//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Decodes raw SFU WebSocket frames into events for `WebSocketClient`.
struct WebRTCEventDecoder: AnyEventDecoder {

    func decode(from data: Data) throws -> Event {
        let response = try Stream_Video_Sfu_Event_SfuEvent(serializedBytes: data)
        guard let payload = response.eventPayload else {
            // Unknown/empty payloads are skipped (logged, not surfaced) by the
            // client's decode loop when they throw `IgnoredEventType`.
            throw ClientError.IgnoredEventType()
        }
        return payload
    }
}
