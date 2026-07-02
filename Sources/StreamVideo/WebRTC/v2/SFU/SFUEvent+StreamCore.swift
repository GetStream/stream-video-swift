//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

// The SFU signaling WebSocket is served by `StreamCore.WebSocketClient`, whose
// event pipeline is typed on `StreamCore.Event`. The SFU envelope payload is
// surfaced as a `StreamCore.Event` (carrying the SFU health-check + error
// handshake), and the outbound SFU request types as `StreamCore.SendableEvent`.
//
// These conformances are StreamCore-qualified so they coexist with the
// coordinator's (video-owned) `Event`/`SendableEvent` protocols.
//
// TODO: [StreamCore migration] The dual (video + StreamCore) `Event`/
// `SendableEvent` conformances exist because the event system isn't unified yet.
// Once it is (leaf migration), collapse these onto the single StreamCore
// protocols.

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload: StreamCore.Event {
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

extension Stream_Video_Sfu_Event_SfuRequest: StreamCore.Event {}
extension Stream_Video_Sfu_Event_SfuRequest: StreamCore.SendableEvent {}

extension Stream_Video_Sfu_Event_HealthCheckRequest: StreamCore.Event {}
extension Stream_Video_Sfu_Event_HealthCheckRequest: StreamCore.SendableEvent {}

/// Builds the SFU health-check ping sent periodically by `StreamCore.WebSocketClient`.
func makeSFUHealthCheckPing() -> any StreamCore.SendableEvent {
    var request = Stream_Video_Sfu_Event_SfuRequest()
    request.healthCheckRequest = Stream_Video_Sfu_Event_HealthCheckRequest()
    return request
}
