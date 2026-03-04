//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

protocol SignalServerEvent: ReflectiveStringConvertible {}

// MARK: - Shared SFU Models

extension Stream_Video_Sfu_Models_ClientDetails: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_CallEndedReason: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_CallGrants: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_CallState: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ClientCapability: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Codec: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ConnectionQuality: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Device: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_GoAwayReason: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ICETrickle: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_OS: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Participant: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ParticipantCount: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ParticipantSource: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_PeerType: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Pin: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_PublishOption: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Sdk: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_SubscribeOption: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_TrackInfo: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_TrackType: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_TrackUnpublishReason: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoDimension: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoLayer: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoQuality: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_WebsocketReconnectStrategy: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails: ReflectiveStringConvertible {}

// MARK: - Events (events.pb.swift)

extension Stream_Video_Sfu_Event_SfuEvent: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ChangePublishOptions: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ChangePublishOptionsComplete: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ParticipantMigrationComplete: SignalServerEvent {}
extension Stream_Video_Sfu_Event_PinsChanged: SignalServerEvent {}
extension Stream_Video_Sfu_Event_Error: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ICETrickle: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ICERestart: SignalServerEvent {}
extension Stream_Video_Sfu_Event_SfuRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Event_LeaveCallRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Event_HealthCheckRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Event_HealthCheckResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Event_TrackPublished: SignalServerEvent {}
extension Stream_Video_Sfu_Event_TrackUnpublished: SignalServerEvent {}
extension Stream_Video_Sfu_Event_JoinRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ReconnectDetails: SignalServerEvent {}
extension Stream_Video_Sfu_Event_Migration: SignalServerEvent {}
extension Stream_Video_Sfu_Event_JoinResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ParticipantJoined: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ParticipantLeft: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ParticipantUpdated: SignalServerEvent {}
extension Stream_Video_Sfu_Event_SubscriberOffer: SignalServerEvent {}
extension Stream_Video_Sfu_Event_PublisherAnswer: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ConnectionQualityChanged: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ConnectionQualityInfo: SignalServerEvent {}
extension Stream_Video_Sfu_Event_DominantSpeakerChanged: SignalServerEvent {}
extension Stream_Video_Sfu_Event_AudioLevel: SignalServerEvent {}
extension Stream_Video_Sfu_Event_AudioLevelChanged: SignalServerEvent {}
extension Stream_Video_Sfu_Event_AudioSender: SignalServerEvent {}
extension Stream_Video_Sfu_Event_VideoLayerSetting: SignalServerEvent {}
extension Stream_Video_Sfu_Event_VideoSender: SignalServerEvent {}
extension Stream_Video_Sfu_Event_ChangePublishQuality: SignalServerEvent {}
extension Stream_Video_Sfu_Event_CallGrantsUpdated: SignalServerEvent {}
extension Stream_Video_Sfu_Event_GoAway: SignalServerEvent {}
extension Stream_Video_Sfu_Event_CallEnded: SignalServerEvent {}
extension Stream_Video_Sfu_Event_InboundStateNotification: SignalServerEvent {}
extension Stream_Video_Sfu_Event_InboundVideoState: SignalServerEvent {}

// MARK: - Signal Service Messages

extension Stream_Video_Sfu_Signal_ICERestartResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_ICETrickleResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_SendAnswerRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_SendAnswerResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_SendStatsResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_SetPublisherRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_SetPublisherResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_StartNoiseCancellationResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_StopNoiseCancellationResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_TrackMuteState: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse: SignalServerEvent {}

extension Stream_Video_Sfu_Event_SfuEvent.OneOf_EventPayload:
    CustomStringConvertible {
    var description: String {
        switch self {
        case let .subscriberOffer(payload):
            return ".subscriberOffer(\(payload))"
        case let .publisherAnswer(payload):
            return ".publisherAnswer(\(payload))"
        case let .connectionQualityChanged(payload):
            return ".connectionQualityChanged(\(payload))"
        case let .audioLevelChanged(payload):
            return ".audioLevelChanged(\(payload))"
        case let .iceTrickle(payload):
            return ".iceTrickle(\(payload))"
        case let .changePublishQuality(payload):
            return ".changePublishQuality(\(payload))"
        case let .participantJoined(payload):
            return ".participantJoined(\(payload))"
        case let .participantLeft(payload):
            return ".participantLeft(\(payload))"
        case let .dominantSpeakerChanged(payload):
            return ".dominantSpeakerChanged(\(payload))"
        case let .joinResponse(payload):
            return ".joinResponse(\(payload))"
        case let .healthCheckResponse(payload):
            return ".healthCheckResponse(\(payload))"
        case let .trackPublished(payload):
            return ".trackPublished(\(payload))"
        case let .trackUnpublished(payload):
            return ".trackUnpublished(\(payload))"
        case let .error(payload):
            return ".error(\(payload))"
        case let .callGrantsUpdated(payload):
            return ".callGrantsUpdated(\(payload))"
        case let .goAway(payload):
            return ".goAway(\(payload))"
        case let .iceRestart(payload):
            return ".iceRestart(\(payload))"
        case let .pinsUpdated(payload):
            return ".pinsUpdated(\(payload))"
        case let .callEnded(payload):
            return ".callEnded(\(payload))"
        case let .participantUpdated(payload):
            return ".participantUpdated(\(payload))"
        case let .participantMigrationComplete(payload):
            return ".participantMigrationComplete(\(payload))"
        case let .changePublishOptions(payload):
            return ".changePublishOptions(\(payload))"
        case let .inboundStateNotification(payload):
            return ".inboundStateNotification(\(payload))"
        }
    }
}
