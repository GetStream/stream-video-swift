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

    private var mockStreamVideo: MockStreamVideo! = .init()

    override func tearDown() async throws {
        mockStreamVideo = nil
        try await super.tearDown()
    }

    // MARK: - Rendering

    // MARK: iPhone

    func test_rendering_iPhone_requiresCameraAndMicrophone_missingCameraAndMicPermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_requiresCameraAndMicrophone_missingCameraPermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_requiresCameraAndMicrophone_missingMicrophonePermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    func test_rendering_iPhone_requiresCamera_missingCamera() async {
        await assert(
            ownCapabilities: [.sendVideo],
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_requiresCamera_hasCamera_doesNotAppear() async {
        await assert(
            ownCapabilities: [.sendVideo],
            variants: [.defaultLight],
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    func test_rendering_iPhone_requiresMicrophone_missingMicrophone() async {
        await assert(
            ownCapabilities: [.sendAudio],
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_requiresMicrophone_hasMicrophone_doesNotAppear() async {
        await assert(
            ownCapabilities: [.sendAudio],
            variants: [.defaultLight],
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPhone_requiresNone_doesNotAppear() async {
        await assert(
            ownCapabilities: [],
            variants: [.defaultLight],
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    // MARK: iPad

    func test_rendering_iPad_requiresCameraAndMicrophone_missingCameraAndMicPermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_requiresCameraAndMicrophone_missingCameraPermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            device: .iPadPro10_5,
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_requiresCameraAndMicrophone_missingMicrophonePermissions() async {
        await assert(
            ownCapabilities: [.sendAudio, .sendVideo],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    func test_rendering_iPad_requiresCamera_missingCamera() async {
        await assert(
            ownCapabilities: [.sendVideo],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_requiresCamera_hasCamera_doesNotAppear() async {
        await assert(
            ownCapabilities: [.sendVideo],
            variants: [.defaultLight],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .granted
        )
    }

    func test_rendering_iPad_requiresMicrophone_missingMicrophone() async {
        await assert(
            ownCapabilities: [.sendAudio],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_requiresMicrophone_hasMicrophone_doesNotAppear() async {
        await assert(
            ownCapabilities: [.sendAudio],
            variants: [.defaultLight],
            device: .iPadPro10_5,
            microphonePermission: .granted,
            cameraPermission: .denied
        )
    }

    func test_rendering_iPad_requiresNone_doesNotAppear() async {
        await assert(
            ownCapabilities: [],
            variants: [.defaultLight],
            device: .iPadPro10_5,
            microphonePermission: .denied,
            cameraPermission: .denied
        )
    }

    // MARK: - Private Helpers

    private func assert(
        ownCapabilities: Set<OwnCapability>,
        variants: [SnapshotVariant] = SnapshotVariant.all,
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

        let call = MockCall()
        call.state.ownCapabilities = .init(ownCapabilities)
        let container = VStack {
            PermissionsPromptView(call: call)
            Spacer()
        }
        .padding(.horizontal)

        AssertSnapshot(
            container,
            variants: variants,
            device: device,
            line: line,
            file: file,
            function: function
        )
    }
}
