//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// `CallKitAdapter` acts as an intermediary between the application and CallKit services,
/// facilitating registration for incoming calls and managing the CallKit service instance.
open class CallKitAdapter {

    @Injected(\.callKitPushNotificationAdapter) private var callKitPushNotificationAdapter
    @Injected(\.callKitService) private var callKitService
    @Injected(\.currentDevice) private var currentDevice

    private var loggedInStateCancellable: AnyCancellable?

    /// The icon data used as the template for CallKit.
    open var iconTemplateImageData: Data? {
        get { activeSystemCallingService.iconTemplateImageData }
        set { updateSystemCallingServices { $0.iconTemplateImageData = newValue } }
    }

    /// The ringtone sound to use for CallKit ringing calls.
    open var ringtoneSound: String? {
        get { activeSystemCallingService.ringtoneSound }
        set { updateSystemCallingServices { $0.ringtoneSound = newValue } }
    }

    /// Configure whether calls should appear in the Recents app.
    open var includesCallsInRecents: Bool {
        get { activeSystemCallingService.includesCallsInRecents }
        set { updateSystemCallingServices { $0.includesCallsInRecents = newValue } }
    }

    /// The callSettings to use when joining a call after accepting it on the
    /// system calling UI. Default: `nil`.
    open var callSettings: CallSettings? {
        didSet { updateSystemCallingServices { $0.callSettings = callSettings } }
    }

    /// The policy that decides if a system-managed call should leave
    /// automatically when participant state changes.
    open var participantAutoLeavePolicy: ParticipantAutoLeavePolicy {
        get { activeSystemCallingService.participantAutoLeavePolicy }
        set { updateSystemCallingServices { $0.participantAutoLeavePolicy = newValue } }
    }

    /// The policy defining the availability of system calling services.
    ///
    /// - Default: `.regionBased`
    public var availabilityPolicy: CallKitAvailabilityPolicy = .regionBased

    /// The currently active StreamVideo client.
    /// - Important: We need to update it whenever a user logins.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// Optional interceptor invoked after the call join response has been
    /// applied locally but before the SDK treats the call as fully entered.
    ///
    /// Assign this when your app needs to perform readiness work during the
    /// join flow, such as waiting for another participant or validating an
    /// external precondition. Throw from the interceptor to fail the join.
    public var callJoinInterceptor: CallJoinIntercepting? {
        get { activeSystemCallingService.callJoinInterceptor }
        set { updateSystemCallingServices { $0.callJoinInterceptor = newValue } }
    }

    /// Initializes the `CallKitAdapter`.
    public init() {}

    /// Registers for incoming calls.
    open func registerForIncomingCalls() {
        guard currentDevice.deviceType != .simulator else {
            return
        }
        callKitPushNotificationAdapter.register()
    }

    /// Unregisters for incoming calls.
    open func unregisterForIncomingCalls() {
        guard currentDevice.deviceType != .simulator else {
            return
        }
        callKitPushNotificationAdapter.unregister()
    }

    private var activeSystemCallingService: SystemCallingService {
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *), shouldUseLiveCommunicationKit {
            return InjectedValues[\.liveCommunicationKitService]
        }
        #endif
        return callKitService
    }

    private var shouldUseLiveCommunicationKit: Bool {
        streamVideo?.videoConfig.useLiveCommunicationKit ?? true
    }

    private func updateSystemCallingServices(
        _ update: (SystemCallingService) -> Void
    ) {
        update(callKitService)
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *) {
            update(InjectedValues[\.liveCommunicationKitService])
        }
        #endif
    }

    private func updateSystemCallingServices(with streamVideo: StreamVideo?) {
        guard let streamVideo else {
            updateSystemCallingServices { $0.streamVideo = nil }
            return
        }

        let useLiveCommunicationKit = streamVideo.videoConfig.useLiveCommunicationKit
        callKitService.streamVideo = useLiveCommunicationKit ? nil : streamVideo
        #if canImport(LiveCommunicationKit)
        if #available(iOS 27.0, *) {
            InjectedValues[\.liveCommunicationKitService].streamVideo = useLiveCommunicationKit
                ? streamVideo
                : nil
        }
        #endif
    }

    private func didUpdate(_ streamVideo: StreamVideo?) {
        guard availabilityPolicy.policy.isAvailable else {
            log
                .warning(
                    "CallKitAdapter cannot be activated because the current availability policy (\(availabilityPolicy.policy)) doesn't allow it."
                )
            return
        }

        updateSystemCallingServices(with: streamVideo)

        guard streamVideo != nil else {
            unregisterForIncomingCalls()
            loggedInStateCancellable = nil
            return
        }

        registerForIncomingCalls()
    }
}

extension CallKitAdapter: InjectionKey {
    /// Provides the current instance of `CallKitAdapter`.
    public nonisolated(unsafe) static var currentValue: CallKitAdapter = .init()
}

extension InjectedValues {
    /// A property wrapper to access the `CallKitAdapter` instance.
    public var callKitAdapter: CallKitAdapter {
        get { Self[CallKitAdapter.self] }
        set { Self[CallKitAdapter.self] = newValue }
    }
}
