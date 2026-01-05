//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

extension SFUAdapter {
    /// Indicates that an SFUAdapter was created for a given host.
    struct CreateEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var traceTag: String { "create" }
        var traceData: AnyEncodable? { .init(["url": hostname]) }
    }

    /// Indicates that the adapter will attempt a WebSocket connection to the host.
    struct ConnectEvent: SFUAdapterEvent, Equatable {
        var hostname: String

        var traceTag: String { "connect" }
    }

    /// Indicates that the adapter has disconnected from the SFU.
    struct DisconnectEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: SwiftProtobuf.Message?

        var traceTag: String { "disconnect" }

        static func == (lhs: DisconnectEvent, rhs: DisconnectEvent) -> Bool {
            guard
                lhs.hostname == rhs.hostname
            else {
                return false
            }

            guard let lhsPayload = lhs.payload, let rhsPayload = rhs.payload else {
                return lhs.payload == nil && rhs.payload == nil
            }

            return lhsPayload.isEqualTo(message: rhsPayload)
        }
    }

    /// Sent when the client joins an SFU call with a join payload.
    struct JoinEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Event_JoinRequest

        var traceTag: String { "join" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when the client leaves the SFU call with an explicit leave request.
    struct LeaveEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Event_LeaveCallRequest

        var traceTag: String { "leave" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when the client updates mute states for its published tracks.
    struct UpdateTrackMuteStateEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_UpdateMuteStatesRequest

        var traceTag: String { "updateTrackMuteState" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent to instruct the SFU to start noise cancellation for the client.
    struct StartNoiseCancellationEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest

        var traceTag: String { "startNoiseCancellation" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent to instruct the SFU to stop noise cancellation for the client.
    struct StopNoiseCancellationEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest

        var traceTag: String { "stopNoiseCancellation" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when a new RTP sender/track is registered with the SFU.
    struct SetPublisherEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_SetPublisherRequest

        var traceTag: String { "setPublisher" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when subscription preferences for remote tracks are updated.
    struct UpdateSubscriptionsEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest

        var traceTag: String { "updateSubscriptions" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when the client sends an SDP answer back to the SFU.
    struct SendAnswerEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_SendAnswerRequest

        var traceTag: String { "sendAnswer" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent to deliver ICE candidates incrementally to the SFU.
    struct ICETrickleEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Models_ICETrickle

        var traceTag: String { "iceTrickle" }
        var traceData: AnyEncodable? { .init(payload) }
    }

    /// Sent when the client requests an ICE restart via the SFU.
    struct RestartICEEvent: SFUAdapterEvent, Equatable {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_ICERestartRequest

        var traceTag: String { "iceRestart" }
        var traceData: AnyEncodable? { .init(payload) }
    }
}
