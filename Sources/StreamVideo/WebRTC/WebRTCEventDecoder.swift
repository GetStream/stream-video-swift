//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

struct WebRTCEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let response = try Stream_Video_Sfu_Event_SfuEvent(serializedBytes: data)
        guard let payload = response.eventPayload else {
            throw ClientError.UnsupportedEventType()
        }
        return WrappedEvent.sfuEvent(payload)
    }
}
