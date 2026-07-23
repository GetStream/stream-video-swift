//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import StreamCore

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload {
    public func healthcheck() -> StreamCore.HealthCheckInfo? {
        if case let .healthCheckResponse(event) = self {
            return StreamCore.HealthCheckInfo(participantCount: Int(event.participantCount.total))
        }
        return nil
    }

    public func error() -> Error? {
        if case let .error(event) = self {
            return event.error
        }
        return nil
    }
}

/// Builds the SFU health-check ping sent periodically by `StreamCore.WebSocketClient`.
func makeSFUHealthCheckPing() -> any StreamCore.SendableEvent {
    var request = Stream_Video_Sfu_Event_SfuRequest()
    request.healthCheckRequest = Stream_Video_Sfu_Event_HealthCheckRequest()
    return request
}
