//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

final class MockCallKitPushNotificationAdapter: CallKitPushNotificationAdapter {
    private(set) var registerWasCalled = false
    private(set) var unregisterWasCalled = false

    override func register() {
        registerWasCalled = true
    }

    override func unregister() {
        unregisterWasCalled = true
    }
}
