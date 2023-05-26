//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.stream
        let event = try decoder.decode(VideoEvent.self, from: data)
        
        switch event {
        case .typeBlockedUserEvent(let callBlocked):
            return callBlocked
        case .typeCallAcceptedEvent(let callAccepted):
            return callAccepted
        case .typeCallCreatedEvent(let callCreated):
            return callCreated
        case .typeCallEndedEvent(let callEnded):
            return callEnded
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
            return callRejected
        case .typeCallUpdatedEvent(let value):
            return value
        case .typeCustomVideoEvent(let value):
            return value
        case .typeHealthCheckEvent(let value):
            return value
        case .typePermissionRequestEvent(let value):
            return value
        case .typeUnblockedUserEvent(let callUnblocked):
            return callUnblocked
        case .typeUpdatedCallPermissionsEvent(let value):
            return value
        case .typeConnectedEvent(let value):
            return value
        case .typeCallBroadcastingStartedEvent(let value):
            return value
        case .typeCallBroadcastingStoppedEvent(let value):
            return value
        case .typeCallLiveStartedEvent(let value):
            return value
        case .typeCallSessionEndedEvent(let value):
            return value
        case .typeCallSessionParticipantJoinedEvent(let value):
            return value
        case .typeCallSessionParticipantLeftEvent(let value):
            return value
        case .typeCallSessionStartedEvent(let value):
            return value
        case .typeCallNotificationEvent(let value):
            return value
        case .typeCallRingEvent(let value):
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
extension ConnectedEvent: HealthCheck {}
extension VideoEvent: Event {}
extension CallBroadcastingStartedEvent: Event {}
extension CallBroadcastingStoppedEvent: Event {}
extension CallLiveStartedEvent: Event {}
extension CallSessionEndedEvent: Event {}
extension CallSessionParticipantJoinedEvent: Event {}
extension CallSessionParticipantLeftEvent: Event {}
extension CallSessionStartedEvent: Event {}
extension CallNotificationEvent: Event {}
extension CallRingEvent: Event {}

extension UserResponse {
    var toUser: User {
        User(
            id: id,
            name: name,
            imageURL: URL(string: image ?? "")
        )
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
