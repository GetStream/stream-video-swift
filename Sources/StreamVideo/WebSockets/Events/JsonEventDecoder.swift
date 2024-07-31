//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    func decode(from data: Data) throws -> WrappedEvent {
        let event = try StreamJSONDecoder.default.decode(VideoEvent.self, from: data)
        return .coordinatorEvent(event)
    }
}

extension VideoEvent: @unchecked Sendable, Event {}

extension UserResponse {
    public var toUser: User {
        User(
            id: id,
            name: name,
            imageURL: URL(string: image ?? ""),
            role: role,
            customData: custom
        )
    }
}

extension ClientError {
    public final class UnsupportedEventType: ClientError {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public final class EventDecoding: ClientError {
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
    func decode(from: Data) throws -> WrappedEvent
}
