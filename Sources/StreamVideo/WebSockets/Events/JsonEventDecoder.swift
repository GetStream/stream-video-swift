//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.stream
        let typeDto = try decoder.decode(JsonEvent.self, from: data)
        switch typeDto.type {
        case .healthCheck:
            return try decoder.decode(HealthCheck.self, from: data)
        case .callCreated:
            return try decoder.decode(CallCreated.self, from: data)
        case .callCancelled:
            return try decoder.decode(CallCancelled.self, from: data)
        case .callRejected:
            return try decoder.decode(CallRejected.self, from: data)
        case .callAccepted:
            return try decoder.decode(CallAccepted.self, from: data)
        case .callEnded:
            return try decoder.decode(CallEnded.self, from: data)
        case .userUpdated:
            return try decoder.decode(UserUpdated.self, from: data)
        default:
            throw ClientError.UnsupportedEventType()
        }
    }
}

extension CallCreated: Event {}
extension CallCancelled: Event {}
extension CallRejected: Event {}
extension CallAccepted: Event {}
extension CallEnded: Event {}
extension UserUpdated: Event {}

class JsonEvent: Decodable {
    let type: EventType
}

public struct EventType: RawRepresentable, Codable, Hashable, ExpressibleByStringLiteral {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

public extension EventType {
    static let healthCheck: Self = "health.check"
    static let callCreated: Self = "call.created"
    static let callCancelled: Self = "call.cancelled"
    static let callRejected: Self = "call.rejected"
    static let callAccepted: Self = "call.accepted"
    static let callEnded: Self = "call.ended"
    static let userUpdated: Self = "user.updated"
}
