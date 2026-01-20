//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

final class StatelessMicrophoneIconView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    // MARK: - Appearance

    @MainActor
    func test_appearance_micOn_hasPermission_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                true
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_micOff_hasPermission_wasConfiguredCorrectly() async throws {
        AssertSnapshot(
            try await makeSubject(
                false
            ),
            variants: snapshotVariants,
            size: sizeThatFits
        )
    }

    @MainActor
    func test_appearance_micOn_noPermission_canRequest_wasConfiguredCorrectly() async throws {
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
    func test_appearance_micOn_noPermission_cannotRequestPermission_wasConfiguredCorrectly() async throws {
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
        _ micOn: Bool,
        hasPermission: Bool = true,
        canRequestPermission: Bool = true,
        actionHandler: (() -> Void)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async throws -> StatelessMicrophoneIconView {
        let mockPermissions = MockPermissionsStore()

        if hasPermission {
            mockPermissions.stubMicrophonePermission(.granted)
            await fulfillment { mockPermissions.mockStore.state.microphonePermission == .granted }
        } else {
            if canRequestPermission {
                mockPermissions.stubMicrophonePermission(.unknown)
                await fulfillment { mockPermissions.mockStore.state.microphonePermission == .unknown }
            } else {
                mockPermissions.stubMicrophonePermission(.denied)
                await fulfillment { mockPermissions.mockStore.state.microphonePermission == .denied }
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
                    audio: .dummy(micDefaultOn: micOn)
                )
            )
        )

        return .init(call: call, actionHandler: actionHandler)
    }
}
