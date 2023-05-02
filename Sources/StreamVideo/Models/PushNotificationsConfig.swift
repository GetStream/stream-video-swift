//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

import Foundation

public struct PushNotificationsConfig {
    public let pushProviderInfo: PushProviderInfo
    public let voipPushProviderInfo: PushProviderInfo
    
    public init(pushProviderInfo: PushProviderInfo, voipPushProviderInfo: PushProviderInfo) {
        self.pushProviderInfo = pushProviderInfo
        self.voipPushProviderInfo = voipPushProviderInfo
    }
}

public extension PushNotificationsConfig {
    static let `default` = PushNotificationsConfig(
        pushProviderInfo: PushProviderInfo(name: "apn", pushProvider: .apn),
        voipPushProviderInfo: PushProviderInfo(name: "voip", pushProvider: .apn)
    )
    
    static func make(pushProviderName: String, voipProviderName: String) -> PushNotificationsConfig {
        PushNotificationsConfig(
            pushProviderInfo: PushProviderInfo(name: pushProviderName, pushProvider: .apn),
            voipPushProviderInfo: PushProviderInfo(name: voipProviderName, pushProvider: .apn)
        )
    }
}

public struct PushProviderInfo {
    public let name: String
    public let pushProvider: PushNotificationsProvider
}
