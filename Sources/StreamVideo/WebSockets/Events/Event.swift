//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

/// An `Event` object representing an event in the chat system.
public protocol Event: Sendable {}

public protocol SendableEvent: Event, ProtoModel {}

extension Event {
    var name: String {
        String(describing: Self.self)
    }

    func unwrap() -> VideoEvent? {
        if let unwrapped = self as? VideoEvent {
            return unwrapped
        }
        if let wrappedEvent = self as? WrappedEvent {
            if case let .coordinatorEvent(videoEvent) = wrappedEvent {
                return videoEvent
            }
        }
        return nil
    }

    // TODO: write a test for this!
    func forCall(cid: String) -> Bool {
        guard let videoEvent = self.unwrap() else {
            return false
        }
        guard let wsCallEvent = videoEvent.rawValue as? WSCallEvent else {
            print("debugging: not a WSCallEvent event")
            return false
        }
        return wsCallEvent.callCid == cid
    }
}

/// An internal object that we use to wrap the kind of events that are handled by WS: SFU and coordinator events
internal enum WrappedEvent: Event {
    case internalEvent(Event)
    case coordinatorEvent(VideoEvent)
    case sfuEvent(Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload)

    func healthcheck() -> HealthCheckInfo? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeHealthCheckEvent(healthCheckEvent) = event {
                return HealthCheckInfo(coordinatorHealthCheck: healthCheckEvent)
            }
            if case let .typeConnectedEvent(connectedEvent) = event {
                return HealthCheckInfo(coordinatorHealthCheck: .init(
                    connectionId: connectedEvent.connectionId,
                    createdAt: connectedEvent.createdAt,
                    type: connectedEvent.type)
                )
            }
        case let .sfuEvent(event):
            if case let .healthCheckResponse(healthCheckEvent) = event {
                return HealthCheckInfo(sfuHealthCheck: healthCheckEvent)
            }
        case .internalEvent(_):
            break
        }
        return nil
    }

    func error() -> Error? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeConnectionErrorEvent(errorEvent) = event {
                return errorEvent.error
            }
        case let .sfuEvent(event):
            if case let .error(errorEvent) = event {
                return errorEvent.error
            }
            return nil
        case .internalEvent(_):
            break
        }
        return nil
    }
}
