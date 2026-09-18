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

/// Resolves which system calling framework owns VoIP calls.
///
/// LiveCommunicationKit is only picked when the SDK was compiled against an OS
/// SDK that ships the framework **and** the device runs a version that supports
/// it. Everything older keeps using CallKit, no matter what
/// ``VideoConfig/useLiveCommunicationKit`` says.
enum SystemCallingServiceProvider {

    /// Whether LiveCommunicationKit can be used on the running OS version.
    static var isLiveCommunicationKitAvailable: Bool {
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *) {
            return true
        }
        #endif
        return false
    }

    /// Whether calls for `streamVideo` are handled by LiveCommunicationKit.
    ///
    /// When no client has been configured yet we assume the default
    /// configuration, which opts into LiveCommunicationKit when it's available.
    static func usesLiveCommunicationKit(for streamVideo: StreamVideo?) -> Bool {
        guard isLiveCommunicationKitAvailable else {
            return false
        }
        return streamVideo?.videoConfig.useLiveCommunicationKit ?? true
    }

    /// The service that manages calls for `streamVideo`.
    static func service(for streamVideo: StreamVideo?) -> SystemCallingService {
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *), usesLiveCommunicationKit(for: streamVideo) {
            return InjectedValues[\.liveCommunicationKitService]
        }
        #endif
        return InjectedValues[\.callKitService]
    }

    /// Applies `update` on every system calling service available on this OS.
    static func updateAll(_ update: (SystemCallingService) -> Void) {
        update(InjectedValues[\.callKitService])
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *) {
            update(InjectedValues[\.liveCommunicationKitService])
        }
        #endif
    }

    /// Whether any available system calling service is managing a call.
    ///
    /// Both services are consulted so the answer stays correct no matter which
    /// one the current configuration activated.
    static var hasActiveCall: Bool {
        if InjectedValues[\.callKitService].callCount > 0 {
            return true
        }
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *), InjectedValues[\.liveCommunicationKitService].callCount > 0 {
            return true
        }
        #endif
        return false
    }
}
