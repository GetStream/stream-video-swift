//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class StatelessVideoIconView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Appearance

    @MainActor
    func test_appearance_videoOn_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_videoOff_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_videoOn_noPermission_canRequest_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                true,
                hasPermission: false,
                canRequestPermission: true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_videoOn_noPermission_cannotRequestPermission_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                true,
                hasPermission: false,
                canRequestPermission: false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    // MARK: Private helpers

    @MainActor
    private func makeSubject(
        _ videoOn: Bool,
        hasPermission: Bool = true,
        canRequestPermission: Bool = true,
        actionHandler: (() -> Void)? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) async throws -> StatelessVideoIconView {
        let mockPermissions = MockPermissionsStore()

        if hasPermission {
            mockPermissions.stubCameraPermission(.granted)
            await fulfillment { mockPermissions.mockStore.state.cameraPermission == .granted }
        } else {
            if canRequestPermission {
                mockPermissions.stubCameraPermission(.unknown)
                await fulfillment { mockPermissions.mockStore.state.cameraPermission == .unknown }
            } else {
                mockPermissions.stubCameraPermission(.denied)
                await fulfillment { mockPermissions.mockStore.state.cameraPermission == .denied }
            }
        }

        let call = try XCTUnwrap(
            streamVideoUI?.streamVideo.call(
                callType: .default,
                callId: "test"
            ),
            file: file,
            line: line
        )
        call.state.update(
            from: .dummy(
                settings: .dummy(
                    video: .dummy(
                        cameraDefaultOn: videoOn
                    )
                )
            )
        )

        return .init(call: call, actionHandler: actionHandler)
    }
}
