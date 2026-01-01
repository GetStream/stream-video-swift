//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftProtobuf

public typealias ProtoModel = SwiftProtobuf.Message & SwiftProtobuf._ProtoNameProviding

typealias ProtoModelResponse = SwiftProtobuf.Message & SwiftProtobuf._ProtoNameProviding & ErrorProviding

protocol ErrorProviding {
    var hasError: Bool { get }
    var error: Stream_Video_Sfu_Models_Error { get }
}

extension Stream_Video_Sfu_Signal_SetPublisherResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_SendAnswerResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_ICETrickleResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_UpdateSubscriptionsResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_UpdateMuteStatesResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_ICERestartResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_SendStatsResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_StartNoiseCancellationResponse: ErrorProviding {}
extension Stream_Video_Sfu_Signal_StopNoiseCancellationResponse: ErrorProviding {}
