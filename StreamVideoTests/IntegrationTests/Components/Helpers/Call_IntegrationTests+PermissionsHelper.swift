//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo
import XCTest

extension Call_IntegrationTests.Helpers {
    struct PermissionsHelper: @unchecked Sendable {
        private var mockPermissionStore = MockPermissionsStore()

        func dismantle() {
            mockPermissionStore.dismantle()
        }

        func setMicrophonePermission(isGranted: Bool) {
            mockPermissionStore.stubMicrophonePermission(isGranted ? .granted : .denied)
        }

        func setCameraPermission(isGranted: Bool) {
            mockPermissionStore.stubCameraPermission(isGranted ? .granted : .denied)
        }
    }
}
