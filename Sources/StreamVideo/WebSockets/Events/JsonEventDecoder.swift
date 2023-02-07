//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.stream
        let typeDto = try decoder.decode(JsonEvent.self, from: data)
        log.debug("received an event with type \(typeDto.type.rawValue)")
        switch typeDto.type {
        case .healthCheck:
            return try decoder.decode(HealthCheck.self, from: data)
        case .callCreated:
            let callCreated = try decoder.decode(CallCreated.self, from: data)
            guard let call = callCreated.call,
                  let callCid = call.cid,
                  let createdBy = call.createdBy.id,
                  let type = call.type else {
                throw ClientError.Unexpected()
            }
            let members = callCreated.members?.compactMap { member in
                User(
                    id: member.userId ?? "",
                    name: member.user.name,
                    imageURL: URL(string: member.user.image ?? "")
                )
            } ?? []
            return IncomingCallEvent(
                callCid: callCid,
                createdBy: createdBy,
                type: type,
                users: members
            )
        case .callCancelled:
            let callCanceled = try decoder.decode(CallCancelled.self, from: data)
            let callId = callCanceled.callCid ?? ""
            return CallEventInfo(
                callId: callId,
                action: .cancel
            )
        case .callRejected:
            let callRejected = try decoder.decode(CallRejected.self, from: data)
            let callId = callRejected.callCid ?? ""
            return CallEventInfo(
                callId: callId,
                action: .reject
            )
        case .callAccepted:
            let callAccepted = try decoder.decode(CallAccepted.self, from: data)
            let callId = callAccepted.callCid ?? ""
            return CallEventInfo(
                callId: callId,
                action: .accept
            )
        case .callEnded:
            let callEnded = try decoder.decode(CallEnded.self, from: data)
            let callId = callEnded.callCid ?? ""
            return CallEventInfo(
                callId: callId,
                action: .end
            )
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
