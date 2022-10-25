//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

struct WebRTCEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let response = try Stream_Video_Sfu_Event_SfuEvent(serializedData: data)
        guard let payload = response.eventPayload else {
            throw ClientError.UnsupportedEventType()
        }
        switch payload {
        case let .subscriberOffer(value):
            return value
        case let .connectionQualityChanged(value):
            return value
        case let .audioLevelChanged(value):
            return value
        case let .changePublishQuality(value):
            return value
        case let .localDeviceChange(value):
            return value
        case let .muteStateChanged(value):
            return value
        case let .videoQualityChanged(value):
            return value
        case let .participantJoined(value):
            return value
        case let .participantLeft(value):
            return value
        case let .dominantSpeakerChanged(value):
            return value
        case let .publisherAnswer(value):
            return value
        case let .iceTrickle(value):
            return value
        case let .joinResponse(value):
            return value
        case let .healthCheckResponse(value):
            return value
        }
    }
}
