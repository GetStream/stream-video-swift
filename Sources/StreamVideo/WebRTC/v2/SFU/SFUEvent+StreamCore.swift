//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload {
    public func healthcheck() -> HealthCheckInfo? {
        if case let .healthCheckResponse(event) = self {
            return HealthCheckInfo(participantCount: Int(event.participantCount.total))
        }
        return nil
    }

    /// Classifies errors that must change the StreamCore connection state.
    /// Unspecified errors stay on the event stream without disconnecting.
    public func error() -> Error? {
        if case let .error(event) = self,
           event.reconnectStrategy != .unspecified {
            return event
        }
        return nil
    }
}

/// Builds the SFU health-check ping sent periodically by `WebSocketClient`.
func makeSFUHealthCheckPing() -> any SendableEvent {
    var request = Stream_Video_Sfu_Event_SfuRequest()
    request.healthCheckRequest = Stream_Video_Sfu_Event_HealthCheckRequest()
    return request
}
