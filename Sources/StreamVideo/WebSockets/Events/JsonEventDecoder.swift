//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

struct JsonEventDecoder: AnyEventDecoder {
    func decode(from data: Data) throws -> Event {
        let event = try StreamJSONDecoder.default.decode(VideoEvent.self, from: data)
        return WrappedEvent.coordinatorEvent(event)
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
    public class UnsupportedEventType: ClientError, @unchecked Sendable {
        override public var localizedDescription: String { "The incoming event type is not supported. Ignoring." }
    }
    
    public class EventDecoding: ClientError, @unchecked Sendable {
        override init(_ message: String, _ file: StaticString = #fileID, _ line: UInt = #line) {
            super.init(message, file, line)
        }
        
        init<T>(missingValue: String, for type: T.Type, _ file: StaticString = #fileID, _ line: UInt = #line) {
            super.init("`\(missingValue)` field can't be `nil` for the `\(type)` event.", file, line)
        }
    }
}
