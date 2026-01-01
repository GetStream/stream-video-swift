//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

// New protocol definition
protocol SignalServerEvent: ReflectiveStringConvertible {}

// Extensions for return types
extension Stream_Video_Sfu_Event_JoinRequest: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Event_Migration: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Event_ReconnectDetails: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Event_SfuRequest: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_ClientDetails: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Device: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_OS: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_Sdk: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_TrackInfo: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_TrackType: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoDimension: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoLayer: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_VideoQuality: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Models_WebsocketReconnectStrategy: ReflectiveStringConvertible {}
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
extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails: ReflectiveStringConvertible {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesResponse: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest: SignalServerEvent {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse: SignalServerEvent {}
