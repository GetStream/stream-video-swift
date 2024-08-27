//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

private class ChatEventMapping: Decodable {
    let type: String
}

public enum WSClientEvent: Codable, Hashable {
    case typeUserUpdatedEvent(UserUpdatedEvent)

    public var type: String {
        switch self {
        case let .typeUserUpdatedEvent(value):
            return value.type
        }
    }

    public var rawValue: Event {
        switch self {
        case let .typeUserUpdatedEvent(value):
            return value
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case let .typeUserUpdatedEvent(value):
            try container.encode(value)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let dto = try container.decode(ChatEventMapping.self)
        if dto.type == "user.updated" {
            let value = try container.decode(UserUpdatedEvent.self)
            self = .typeUserUpdatedEvent(value)
        } else {
            throw DecodingError.typeMismatch(
                Self.Type.self,
                .init(codingPath: decoder.codingPath, debugDescription: "Unable to decode instance of WSClientEvent")
            )
        }
    }
}
