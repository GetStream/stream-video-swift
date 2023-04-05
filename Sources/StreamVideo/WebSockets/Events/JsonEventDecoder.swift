//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.stream
        let event = try decoder.decode(WSEvent.self, from: data)
        
        switch event {
        case .typeBlockedUserEvent(let callBlocked):
            let callId = callBlocked.callCid
            return CallEventInfo(
                callId: callId,
                user: User(id: callBlocked.user.id),
                action: .block
            )
        case .typeCallAcceptedEvent(let callAccepted):
            let callId = callAccepted.callCid
            return CallEventInfo(
                callId: callId,
                user: callAccepted.user.toUser,
                action: .accept
            )
        case .typeCallCreatedEvent(let callCreated):
            let call = callCreated.call
            let members = callCreated.members.compactMap { $0.user.toUser }
            return IncomingCallEvent(
                callCid: call.cid,
                createdBy: call.createdBy.id,
                type: call.type,
                users: members,
                ringing: callCreated.ringing
            )
        case .typeCallEndedEvent(let callEnded):
            let callId = callEnded.callCid
            return CallEventInfo(
                callId: callId,
                user: callEnded.user?.toUser,
                action: .end
            )
        case .typeCallMemberAddedEvent(let value):
            return value
        case .typeCallMemberRemovedEvent(let value):
            return value
        case .typeCallMemberUpdatedEvent(let value):
            return value
        case .typeCallMemberUpdatedPermissionEvent(let value):
            return value
        case .typeCallReactionEvent(let value):
            return value
        case .typeCallRecordingStartedEvent(let value):
            return value
        case .typeCallRecordingStoppedEvent(let value):
            return value
        case .typeCallRejectedEvent(let callRejected):
            let callId = callRejected.callCid
            return CallEventInfo(
                callId: callId,
                user: callRejected.user.toUser,
                action: .reject
            )
        case .typeCallUpdatedEvent(let value):
            return value
        case .typeCustomVideoEvent(let value):
            return value
        case .typeHealthCheckEvent(let value):
            return value
        case .typePermissionRequestEvent(let value):
            return value
        case .typeUnblockedUserEvent(let callUnblocked):
            let callId = callUnblocked.callCid
            return CallEventInfo(
                callId: callId,
                user: User(id: callUnblocked.user.id),
                action: .unblock
            )
        case .typeUpdatedCallPermissionsEvent(let value):
            return value
        case .typeWSConnectedEvent(let value):
            return value
        }
    }
}

extension CallCreatedEvent: Event {}
extension CallRejectedEvent: Event {}
extension CallAcceptedEvent: Event {}
extension CallEndedEvent: Event {}
extension PermissionRequestEvent: Event {}
extension UpdatedCallPermissionsEvent: Event {}
extension CustomVideoEvent: Event {}
extension HealthCheckEvent: HealthCheck {}
extension CallReactionEvent: Event {}
extension CallRecordingStartedEvent: Event {}
extension CallRecordingStoppedEvent: Event {}
extension CallUpdatedEvent: Event {}
extension BlockedUserEvent: Event {}
extension CallMemberAddedEvent: Event {}
extension CallMemberRemovedEvent: Event {}
extension CallMemberUpdatedPermissionEvent: Event {}
extension CallMemberUpdatedEvent: Event {}
extension UnblockedUserEvent: Event {}
extension WSConnectedEvent: HealthCheck {}
extension WSEvent: Event {}

extension UserResponse {
    var toUser: User {
        User(
            id: id,
            name: name,
            imageURL: URL(string: image ?? "")
        )
    }
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
    static let callRejected: Self = "call.rejected"
    static let callAccepted: Self = "call.accepted"
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
