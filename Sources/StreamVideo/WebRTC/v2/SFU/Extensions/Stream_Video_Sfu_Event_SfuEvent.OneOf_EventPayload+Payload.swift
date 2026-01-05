//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload {
    /// Attempts to retrieve the payload of a specific type from the event.
    ///
    /// This method provides a type-safe way to access the payload of an SFU event.
    /// It uses Swift's generic system to allow retrieval of payloads of any type.
    ///
    /// - Parameter payloadType: The type of the payload to retrieve.
    /// - Returns: The payload cast to the specified type if successful, otherwise `nil`.
    ///
    /// - Note: This method uses optional casting (`as?`) which means it will return `nil`
    ///   if the actual payload doesn't match the requested type.
    func payload<T>(_ payloadType: T.Type) -> T? {
        switch self {
        case let .subscriberOffer(payload):
            return payload as? T
        case let .publisherAnswer(payload):
            return payload as? T
        case let .connectionQualityChanged(payload):
            return payload as? T
        case let .audioLevelChanged(payload):
            return payload as? T
        case let .iceTrickle(payload):
            return payload as? T
        case let .changePublishQuality(payload):
            return payload as? T
        case let .participantJoined(payload):
            return payload as? T
        case let .participantLeft(payload):
            return payload as? T
        case let .dominantSpeakerChanged(payload):
            return payload as? T
        case let .joinResponse(payload):
            return payload as? T
        case let .healthCheckResponse(payload):
            return payload as? T
        case let .trackPublished(payload):
            return payload as? T
        case let .trackUnpublished(payload):
            return payload as? T
        case let .error(payload):
            return payload as? T
        case let .callGrantsUpdated(payload):
            return payload as? T
        case let .goAway(payload):
            return payload as? T
        case let .iceRestart(payload):
            return payload as? T
        case let .pinsUpdated(payload):
            return payload as? T
        case let .callEnded(payload):
            return payload as? T
        case let .participantUpdated(payload):
            return payload as? T
        case let .participantMigrationComplete(payload):
            return payload as? T
        case let .changePublishOptions(payload):
            return payload as? T
        case let .inboundStateNotification(payload):
            return payload as? T
        }
    }
}
