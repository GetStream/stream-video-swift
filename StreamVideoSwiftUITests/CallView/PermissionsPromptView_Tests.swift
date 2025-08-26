//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import SwiftUI
import XCTest

@MainActor
final class PermissionsPromptView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Rendering

    // MARK: iPhone

    func test_rendering_iPhone_missingCameraAndMicPermissions() async {
        await assert(
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_missingCameraPermissions() async {
        await assert(
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_missingMissingPermissions() async {
        await assert(
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    // MARK: iPad

    func test_rendering_iPad_missingCameraAndMicPermissions() async {
        await assert(
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_missingCameraPermissions() async {
        await assert(
            device: .iPadPro10_5,
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_missingMissingPermissions() async {
        await assert(
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    // MARK: - Private Helpers

    private func assert(
        device: ViewImageConfig = .iPhoneX,
        microphonePermission: PermissionStore.Permission = .granted,
        cameraPermission: PermissionStore.Permission = .granted,
        file: StaticString = #filePath,
        function: String = #function,
        line: UInt = #line
    ) async {
        let mockPermissions = MockPermissionsStore()
        mockPermissions.stubMicrophonePermission(microphonePermission)
        mockPermissions.stubCameraPermission(cameraPermission)

        await fulfillment {
            mockPermissions.mockStore.state.microphonePermission == microphonePermission
                && mockPermissions.mockStore.state.cameraPermission == cameraPermission
        }

        let container = VStack {
            PermissionsPromptView()
            Spacer()
        }
        .padding(.horizontal)

        AssertSnapshot(
            container,
            device: device,
            line: line,
            file: file,
            function: function
        )
    }
}
