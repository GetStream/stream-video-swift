//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

/// A lightweight object for decoding incoming events.
struct EventDecoder {
    func decode(from data: Data) throws -> Event {
        let response = try Stream_Video_WebsocketEvent(serializedData: data)
        guard let payload = response.event else {
            throw ClientError.UnsupportedEventType()
        }
        switch payload {
        case let .callStarted(value):
            let call = response.calls.first?.value
            return IncomingCallEvent(
                proto: value,
                createdBy: call?.createdByUserID ?? "",
                type: call?.type ?? CallType.default.name,
                users: response.users.map(\.value)
            )
        case let .callCreated(value):
            return value
        case let .callUpdated(value):
            return value
        case let .callEnded(value):
            return value
        case let .callDeleted(value):
            return value
        case let .userUpdated(value):
            return value
        case let .callMembersUpdated(value):
            return value
        case let .callMembersDeleted(value):
            return value
        case let .healthcheck(value):
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
    }
}

/// A type-erased wrapper protocol for `EventDecoder`.
protocol AnyEventDecoder {
    func decode(from: Data) throws -> Event
}

extension EventDecoder: AnyEventDecoder {}
