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
            let call = callCreated.call
            let members = callCreated.members.compactMap { member in
                User(
                    id: member.userId,
                    name: member.user.name,
                    imageURL: URL(string: member.user.image ?? "")
                )
            }
            return IncomingCallEvent(
                callCid: call.cid,
                createdBy: call.createdBy.id,
                type: call.type,
                users: members
            )
        case .callCancelled:
            let callCanceled = try decoder.decode(CallCancelled.self, from: data)
            let callId = callCanceled.callCid
            return CallEventInfo(
                callId: callId,
                action: .cancel
            )
        case .callRejected:
            let callRejected = try decoder.decode(CallRejected.self, from: data)
            let callId = callRejected.callCid
            return CallEventInfo(
                callId: callId,
                action: .reject
            )
        case .callAccepted:
            let callAccepted = try decoder.decode(CallAccepted.self, from: data)
            let callId = callAccepted.callCid
            return CallEventInfo(
                callId: callId,
                action: .accept
            )
        case .callEnded:
            let callEnded = try decoder.decode(CallEnded.self, from: data)
            let callId = callEnded.callCid
            return CallEventInfo(
                callId: callId,
                action: .end
            )
        case .permissionRequest:
            return try decoder.decode(CallPermissionRequest.self, from: data)
        case .permissionsUpdated:
            return try decoder.decode(CallPermissionsUpdated.self, from: data)
        default:
            do {
                // Try to decode a custom event.
                return try decoder.decode(Custom.self, from: data)
            } catch {
                throw ClientError.UnsupportedEventType()
            }
        }
    }
}

extension CallCreated: Event {}
extension CallCancelled: Event {}
extension CallRejected: Event {}
extension CallAccepted: Event {}
extension CallEnded: Event {}
extension CallPermissionRequest: Event {}
extension CallPermissionsUpdated: Event {}
extension Custom: Event {}

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
    static let permissionRequest: Self = "call.permission_request"
    static let permissionsUpdated: Self = "call.permissions_updated"
}
