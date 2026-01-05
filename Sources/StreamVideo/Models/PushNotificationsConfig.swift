//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationsConfig: Sendable, Equatable {
    /// Config for regular push notifications.
    public let pushProviderInfo: PushProviderInfo
    /// Config for voip push notifications.
    public let voipPushProviderInfo: PushProviderInfo
    
    public init(pushProviderInfo: PushProviderInfo, voipPushProviderInfo: PushProviderInfo) {
        self.pushProviderInfo = pushProviderInfo
        self.voipPushProviderInfo = voipPushProviderInfo
    }
}

public extension PushNotificationsConfig {
    /// Default push notifications config.
    static let `default` = PushNotificationsConfig(
        pushProviderInfo: PushProviderInfo(name: "ios-apn", pushProvider: .apn),
        voipPushProviderInfo: PushProviderInfo(name: "ios-voip", pushProvider: .apn)
    )
    
    /// Creates a push notifications config with the provided parameters.
    /// - Parameters:
    ///  - pushProviderName: the push provider name.
    ///  - voipProviderName: the push provider name for VoIP notifications.
    /// - Returns: `PushNotificationsConfig`.
    static func make(pushProviderName: String, voipProviderName: String) -> PushNotificationsConfig {
        PushNotificationsConfig(
            pushProviderInfo: PushProviderInfo(name: pushProviderName, pushProvider: .apn),
            voipPushProviderInfo: PushProviderInfo(name: voipProviderName, pushProvider: .apn)
        )
    }
}

public struct PushProviderInfo: Sendable, Equatable {
    public let name: String
    public let pushProvider: PushNotificationsProvider

    public init(name: String, pushProvider: PushNotificationsProvider) {
        self.name = name
        self.pushProvider = pushProvider
    }
}
