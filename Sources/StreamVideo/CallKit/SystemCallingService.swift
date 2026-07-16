//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

protocol SystemCallingService: AnyObject {
    var streamVideo: StreamVideo? { get set }
    var iconTemplateImageData: Data? { get set }
    var ringtoneSound: String? { get set }
    var supportsHolding: Bool { get set }
    var supportsVideo: Bool { get set }
    var includesCallsInRecents: Bool { get set }
    var missingPermissionPolicy: CallKitMissingPermissionPolicy { get set }
    var participantAutoLeavePolicy: ParticipantAutoLeavePolicy { get set }
    var callJoinInterceptor: CallJoinIntercepting? { get set }
    var callSettings: CallSettings? { get set }
    var eventPipeline: AnyPublisher<CallKitService.Event, Never> { get }
    var callCount: Int { get }

    func reportIncomingCall(
        _ cid: String,
        localizedCallerName: String,
        callerId: String,
        hasVideo: Bool,
        completion: @Sendable @escaping (Error?) -> Void
    )

    func callAccepted(_ response: CallAcceptedEvent)
    func callRejected(_ response: CallRejectedEvent)
    func callEnded(_ cId: String, ringingTimedOut: Bool, leaveReason: String?)
    func callParticipantLeft(_ response: CallSessionParticipantLeftEvent)
}

extension CallKitService: SystemCallingService {}
