//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

/// `CallKitAdapter` acts as an intermediary between the application and CallKit services,
/// facilitating registration for incoming calls and managing the CallKit service instance.
open class CallKitAdapter {

    @Injected(\.callKitPushNotificationAdapter) private var callKitPushNotificationAdapter
    @Injected(\.callKitService) private var callKitService

    private var loggedInStateCancellable: AnyCancellable?

    /// The icon data used as the template for CallKit.
    open var iconTemplateImageData: Data? {
        get { callKitService.iconTemplateImageData }
        set { callKitService.iconTemplateImageData = newValue }
    }

    /// The currently active StreamVideo client.
    /// - Important: We need to update it whenever a user logins.
    public var streamVideo: StreamVideo? {
        didSet { didUpdate(streamVideo) }
    }

    /// Initializes the `CallKitAdapter`.
    public init() {}

    /// Registers for incoming calls.
    open func registerForIncomingCalls() {
        callKitPushNotificationAdapter.register()
    }

    /// Unregisters for incoming calls.
    open func unregisterForIncomingCalls() {
        callKitPushNotificationAdapter.unregister()
    }

    private func didUpdate(_ streamVideo: StreamVideo?) {
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
    nonisolated(unsafe) public static var currentValue: CallKitAdapter = .init()
}

extension InjectedValues {
    /// A property wrapper to access the `CallKitAdapter` instance.
    public var callKitAdapter: CallKitAdapter {
        get { Self[CallKitAdapter.self] }
        set { Self[CallKitAdapter.self] = newValue }
    }
}
