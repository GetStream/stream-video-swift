//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct WebRTCEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> WrappedEvent {
        let response = try Stream_Video_Sfu_Event_SfuEvent(serializedData: data)
        guard let payload = response.eventPayload else {
            throw ClientError.UnsupportedEventType()
        }
        return .sfuEvent(payload)
    }
}
