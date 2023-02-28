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
            let callCreated = try decoder.decode(CallCreatedEvent.self, from: data)
            let call = callCreated.call
            let members = callCreated.members.compactMap { $0.user.toUser }
            return IncomingCallEvent(
                callCid: call.cid,
                createdBy: call.createdBy.id,
                type: call.type,
                users: members
            )
        case .callCancelled:
            let callCanceled = try decoder.decode(CallCancelledEvent.self, from: data)
            let callId = callCanceled.callCid
            return CallEventInfo(
                callId: callId,
                user: callCanceled.user.toUser,
                action: .cancel
            )
        case .callRejected:
            let callRejected = try decoder.decode(CallRejectedEvent.self, from: data)
            let callId = callRejected.callCid
            return CallEventInfo(
                callId: callId,
                user: callRejected.user.toUser,
                action: .reject
            )
        case .callAccepted:
            let callAccepted = try decoder.decode(CallAcceptedEvent.self, from: data)
            let callId = callAccepted.callCid
            return CallEventInfo(
                callId: callId,
                user: callAccepted.user.toUser,
                action: .accept
            )
        case .callEnded:
            let callEnded = try decoder.decode(CallEndedEvent.self, from: data)
            let callId = callEnded.callCid
            return CallEventInfo(
                callId: callId,
                user: callEnded.user?.toUser,
                action: .end
            )
        case .callBlocked:
            let callBlocked = try decoder.decode(BlockedUserEvent.self, from: data)
            let callId = callBlocked.callCid
            return CallEventInfo(
                callId: callId,
                user: User(id: callBlocked.userId),
                action: .block
            )
        case .callUnblocked:
            let callUnblocked = try decoder.decode(UnblockedUserEvent.self, from: data)
            let callId = callUnblocked.callCid
            return CallEventInfo(
                callId: callId,
                user: User(id: callUnblocked.userId),
                action: .unblock
            )
        case .permissionRequest:
            return try decoder.decode(PermissionRequestEvent.self, from: data)
        case .permissionsUpdated:
            return try decoder.decode(UpdatedCallPermissionsEvent.self, from: data)
        default:
            do {
                // Try to decode a custom event.
                return try decoder.decode(CustomVideoEvent.self, from: data)
            } catch {
                throw ClientError.UnsupportedEventType()
            }
        }
    }
}

extension CallCreatedEvent: Event {}
extension CallCancelledEvent: Event {}
extension CallRejectedEvent: Event {}
extension CallAcceptedEvent: Event {}
extension CallEndedEvent: Event {}
extension PermissionRequestEvent: Event {}
extension UpdatedCallPermissionsEvent: Event {}
extension CustomVideoEvent: Event {}

extension UserResponse {
    var toUser: User {
        User(
            id: id,
            name: name,
            imageURL: URL(string: image ?? "")
        )
    }
}

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
    static let callBlocked: Self = "call.blocked_user"
    static let callUnblocked: Self = "call.unblocked_user"
    static let permissionRequest: Self = "call.permission_request"
    static let permissionsUpdated: Self = "call.permissions_updated"
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
