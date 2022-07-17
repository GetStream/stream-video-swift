//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    func decode(from data: Data) throws -> Event {
        let response = try Stream_Video_WebsocketEvent(serializedData: data)
        guard let payload = response.eventPayload else {
            throw ClientError.UnsupportedEventType()
        }
        switch payload {
        case .healthCheck(let value):
            return value
        case .callRinging(let value):
            return value
        case .callCreated(let value):
            return value
        case .callUpdated(let value):
            return value
        case .callEnded(let value):
            return value
        case .callDeleted(let value):
            return value
        case .userUpdated(let value):
            return value
        case .participantInvited(let value):
            return value
        case .participantUpdated(let value):
            return value
        case .participantDeleted(let value):
            return value
        case .participantJoined(let value):
            return value
        case .participantLeft(let value):
            return value
        case .broadcastStarted(let value):
            return value
        case .broadcastEnded(let value):
            return value
        }
    }
}

extension ClientError {
    public class UnsupportedEventType: ClientError {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public class EventDecoding: ClientError {
        override init(_ message: String, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init(message, file, line)
        }
        
        init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }
        
        init(missingValue: String, for type: EventType, _ file: StaticString = #file, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type.rawValue)` event.", file, line)
        }
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

extension EventDecoder: AnyEventDecoder {}
