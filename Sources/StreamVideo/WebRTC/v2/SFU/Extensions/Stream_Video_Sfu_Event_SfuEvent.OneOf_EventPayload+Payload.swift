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
        boxedPayload as? T
    }

    /// The associated value of the current case, type-erased.
    ///
    /// Extracting the value in a non-generic property keeps the large switch
    /// below out of every specialisation of `payload(_:)`.
    private var boxedPayload: Any {
        switch self {
        case let .subscriberOffer(payload):
            return payload
        case let .publisherAnswer(payload):
            return payload
        case let .connectionQualityChanged(payload):
            return payload
        case let .audioLevelChanged(payload):
            return payload
        case let .iceTrickle(payload):
            return payload
        case let .changePublishQuality(payload):
            return payload
        case let .participantJoined(payload):
            return payload
        case let .participantLeft(payload):
            return payload
        case let .dominantSpeakerChanged(payload):
            return payload
        case let .joinResponse(payload):
            return payload
        case let .healthCheckResponse(payload):
            return payload
        case let .trackPublished(payload):
            return payload
        case let .trackUnpublished(payload):
            return payload
        case let .error(payload):
            return payload
        case let .callGrantsUpdated(payload):
            return payload
        case let .goAway(payload):
            return payload
        case let .iceRestart(payload):
            return payload
        case let .pinsUpdated(payload):
            return payload
        case let .callEnded(payload):
            return payload
        case let .participantUpdated(payload):
            return payload
        case let .participantMigrationComplete(payload):
            return payload
        case let .changePublishOptions(payload):
            return payload
        case let .inboundStateNotification(payload):
            return payload
        }
    }
}
