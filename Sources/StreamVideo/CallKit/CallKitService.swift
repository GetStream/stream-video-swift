//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Combine
import Foundation

open class CallKitService {

    @Injected(\.streamVideo) private var streamVideo
    @Injected(\.callKitPushNotificationAdapter) private var callKitPushNotificationAdapter
    @Injected(\.callKitAdapter) private var callKitAdapter

    private var loggedInStateCancellable: AnyCancellable?

    open var iconTemplateImageData: Data? {
        get { callKitAdapter.iconTemplateImageData }
        set { callKitAdapter.iconTemplateImageData = newValue }
    }

    public init() {
        loggedInStateCancellable = streamVideo
            .state
            .$connection
            .sink { [weak self] in
                switch $0 {
                case .connected:
                    self?.registerForIncomingCalls()
                case .disconnected:
                    self?.unregisterForIncomingCalls()
                default:
                    break
                }
            }
    }

    open func registerForIncomingCalls() {
        #if targetEnvironment(simulator)
        log.info("CallKit notifications are not supported on simulator.")
        #else
        callKitPushNotificationAdapter.register()
        #endif
    }

    open func unregisterForIncomingCalls() {
        #if targetEnvironment(simulator)
        log.info("CallKit notifications are not supported on simulator.")
        #else
        callKitPushNotificationAdapter.unregister()
        #endif
    }
}

extension CallKitService: InjectionKey {
    public static var currentValue: CallKitService = .init()
}

extension InjectedValues {
    public var callKitService: CallKitService {
        get { Self[CallKitService.self] }
        set { Self[CallKitService.self] = newValue }
    }
}
