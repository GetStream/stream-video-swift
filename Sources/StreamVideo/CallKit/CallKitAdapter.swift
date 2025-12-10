//
// Copyright © 2025 Stream.io Inc. All rights reserved.
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
        get { callKitService.iconTemplateImageData }
        set { callKitService.iconTemplateImageData = newValue }
    }

    /// The ringtone sound to use for CallKit ringing calls.
    open var ringtoneSound: String? {
        get { callKitService.ringtoneSound }
        set { callKitService.ringtoneSound = newValue }
    }

    /// The icon data used as the template for CallKit.
    open var includesCallsInRecents: Bool {
        get { callKitService.includesCallsInRecents }
        set { callKitService.includesCallsInRecents = newValue }
    }

    /// The callSettings to use when joining a call (after accepting it on CallKit)
    /// default: nil
    open var callSettings: CallSettings? {
        didSet { callKitService.callSettings = callSettings }
    }

    /// The policy defining the availability of CallKit services.
    ///
    /// - Default: `.regionBased`
    public var availabilityPolicy: CallKitAvailabilityPolicy = .regionBased

    /// The currently active StreamVideo client.
    /// - Important: We need to update it whenever a user logins.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
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

    private func didUpdate(_ streamVideo: StreamVideo?) {
        guard availabilityPolicy.policy.isAvailable else {
            log
                .warning(
                    "CallKitAdapter cannot be activated because the current availability policy (\(availabilityPolicy.policy)) doesn't allow it."
                )
            return
        }

        callKitService.streamVideo = streamVideo

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
