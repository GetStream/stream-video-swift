//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

extension SFUAdapter {
    struct CreateEvent: SFUAdapterEvent {
        var hostname: String
        var traceTag: String { "create" }
        var traceData: AnyEncodable? { .init(["url": hostname]) }
    }
    
    struct ConnectEvent: SFUAdapterEvent {
        var hostname: String

        var traceTag: String { "connect" }
    }

    struct DisconnectEvent: SFUAdapterEvent {
        var hostname: String
        var payload: SwiftProtobuf.Message? = nil

        var traceTag: String { "disconnect" }
    }

    struct JoinEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Event_JoinRequest

        var traceTag: String { "join" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct LeaveEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Event_LeaveCallRequest

        var traceTag: String { "leave" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct UpdateTrackMuteStateEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_UpdateMuteStatesRequest

        var traceTag: String { "updateTrackMuteState" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct StartNoiseCancellationEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_StartNoiseCancellationRequest

        var traceTag: String { "startNoiseCancellation" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct StopNoiseCancellationEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_StopNoiseCancellationRequest

        var traceTag: String { "stopNoiseCancellation" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct SetPublisherEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_SetPublisherRequest

        var traceTag: String { "setPublisher" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct UpdateSubscriptionsEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest

        var traceTag: String { "updateSubscriptions" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct SendAnswerEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_SendAnswerRequest

        var traceTag: String { "sendAnswer" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct ICETrickleEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Models_ICETrickle

        var traceTag: String { "iceTrickle" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }

    struct RestartICEEvent: SFUAdapterEvent {
        var hostname: String
        var payload: Stream_Video_Sfu_Signal_ICERestartRequest

        var traceTag: String { "iceRestart" }
        var traceData: AnyEncodable? { .init(try? payload.jsonString()) }
    }
}
