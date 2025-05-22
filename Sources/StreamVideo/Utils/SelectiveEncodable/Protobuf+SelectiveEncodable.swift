//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

// MARK: - SelectiveEncodable Conformances

//
// All types below are made to conform to SelectiveEncodable, which provides
// generic Encodable conformance. It will encode all public properties except
// those named 'unknownFields' or any property whose name starts with an
// underscore (_). This makes encoding flexible for logging, analytics, or
// debugging, and avoids leaking internal or protocol buffer metadata fields.
//
// Usage of SelectiveEncodable removes the need to manually implement
// Encodable for every struct, ensuring consistency and maintainability.

extension Stream_Video_Sfu_Signal_StartNoiseCancellationRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_StartNoiseCancellationResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_StopNoiseCancellationRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_StopNoiseCancellationResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_Reconnection: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_Telemetry: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SendStatsRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SendStatsResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_ICERestartRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_ICERestartResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_TrackMuteState: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_AudioMuteChanged: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_VideoMuteChanged: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_TrackSubscriptionDetails: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SendAnswerRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SendAnswerResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_ICETrickleResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SetPublisherRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Signal_SetPublisherResponse: SelectiveEncodable {}
extension Stream_Video_Sfu_Models_ICETrickle: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_JoinRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_LeaveCallRequest: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_ChangePublishQuality: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_CallEnded: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_GoAway: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_Error: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_AudioSender: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_VideoSender: SelectiveEncodable {}
extension Stream_Video_Sfu_Models_Codec: SelectiveEncodable {}
extension Stream_Video_Sfu_Event_VideoLayerSetting: SelectiveEncodable {}
extension Stream_Video_Sfu_Models_Error: SelectiveEncodable {}

// MARK: - Standard Encodable Conformances

//
// The types below are simple enums or value types and are made to conform to
// Encodable using the compiler's default synthesis.

extension Stream_Video_Sfu_Models_TrackType: Encodable {}
extension Stream_Video_Sfu_Models_CallEndedReason: Encodable {}
extension Stream_Video_Sfu_Models_GoAwayReason: Encodable {}
extension Stream_Video_Sfu_Models_ErrorCode: Encodable {}
extension Stream_Video_Sfu_Models_WebsocketReconnectStrategy: Encodable {}
