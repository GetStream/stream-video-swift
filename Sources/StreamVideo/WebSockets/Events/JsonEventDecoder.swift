//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

struct JsonEventDecoder: AnyEventDecoder {
    
    func decode(from data: Data) throws -> Event {
        let decoder = JSONDecoder.stream
        let videoEvent = try decoder.decode(VideoEvent.self, from: data)
        let event = unpack(event: videoEvent)
        return CoordinatorEvent(wrapped: videoEvent, event: event)
    }
    
    private func unpack(event: VideoEvent) -> Event {
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
        case .typeConnectionErrorEvent(let value):
            return value
        }
    }
}

struct CoordinatorEvent: Event {
    let wrapped: VideoEvent
    let event: Event
}

extension CallCreatedEvent: @unchecked Sendable, Event {}
extension CallRejectedEvent: @unchecked Sendable, Event {}
extension CallAcceptedEvent: @unchecked Sendable, Event {}
extension CallEndedEvent: @unchecked Sendable, Event {}
extension PermissionRequestEvent: @unchecked Sendable, Event {}
extension UpdatedCallPermissionsEvent: @unchecked Sendable, Event {}
extension CustomVideoEvent: @unchecked Sendable, Event {}
extension HealthCheckEvent: @unchecked Sendable, HealthCheck {}
extension CallReactionEvent: @unchecked Sendable, Event {}
extension CallRecordingStartedEvent: @unchecked Sendable, Event {}
extension CallRecordingStoppedEvent: @unchecked Sendable, Event {}
extension CallUpdatedEvent: @unchecked Sendable, Event {}
extension BlockedUserEvent: @unchecked Sendable, Event {}
extension CallMemberAddedEvent: @unchecked Sendable, Event {}
extension CallMemberRemovedEvent: @unchecked Sendable, Event {}
extension CallMemberUpdatedPermissionEvent: @unchecked Sendable, Event {}
extension CallMemberUpdatedEvent: @unchecked Sendable, Event {}
extension UnblockedUserEvent: @unchecked Sendable, Event {}
extension ConnectedEvent: @unchecked Sendable, HealthCheck {}
extension VideoEvent: @unchecked Sendable, Event {}
extension CallBroadcastingStartedEvent: @unchecked Sendable, Event {}
extension CallBroadcastingStoppedEvent: @unchecked Sendable, Event {}
extension CallLiveStartedEvent: @unchecked Sendable, Event {}
extension CallSessionEndedEvent: @unchecked Sendable, Event {}
extension CallSessionParticipantJoinedEvent: @unchecked Sendable, Event {}
extension CallSessionParticipantLeftEvent: @unchecked Sendable, Event {}
extension CallSessionStartedEvent: @unchecked Sendable, Event {}
extension CallNotificationEvent: @unchecked Sendable, Event {}
extension CallRingEvent: @unchecked Sendable, Event {}
extension ConnectionErrorEvent: @unchecked Sendable, Event {}

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
