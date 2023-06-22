//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public protocol SendableEvent: Sendable, ProtoModel {}

public protocol Event {}

internal enum WrappedEvent: Event {
    case coordinatorEvent(VideoEvent)
    case sfuEvent(Stream_Video_Sfu_Event_SfuEvent)
    
    func error() -> Error? {
        switch self {
        case let .coordinatorEvent(event):
            if case let .typeConnectionErrorEvent(errorEvent) = event {
                return errorEvent.error
            }
        case .sfuEvent(_):
            // TODO: do we have error messages from SFU? we should check and handle this properly
            return nil
        }
        return nil
    }

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
            guard let payload = event.eventPayload else {
                return nil
            }
            if case let .healthCheckResponse(healthCheckEvent) = payload {
                return HealthCheckInfo(sfuHealthCheck: healthCheckEvent)
            }
        }
        return nil
    }
}

