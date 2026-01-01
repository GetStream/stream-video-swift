//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SnapshotTesting
import StreamSwiftTestHelpers
@testable import StreamVideo
@testable import StreamVideoSwiftUI
import XCTest

@MainActor
final class MicrophoneCheckView_Tests: StreamVideoUITestCase, @unchecked Sendable {

    private nonisolated(unsafe) var mockPermissions: MockPermissionsStore! = .init()

    override func tearDown() {
        mockPermissions = nil
        super.tearDown()
    }

    func test_microphoneCheckView_withAudioLevels_snapshot() async throws {
        for count in 0...5 {
            let view = MicrophoneCheckView(
                audioLevels: (0..<count).map { 0.2 * Float($0) },
                microphoneOn: true,
                isSilent: false,
                isPinned: false
            )
            .frame(width: 100, height: 50)
            AssertSnapshot(
                view,
                variants: snapshotVariants,
                size: sizeThatFits,
                suffix: "with_\(count)_audioLevels"
            )
        }
    }
    
    func test_microphoneCheckView_withoutAudioLevels_snapshot() throws {
        let view = MicrophoneCheckView(
            audioLevels: [],
            microphoneOn: true,
            isSilent: true,
            isPinned: false
        )
        .frame(width: 100, height: 50)
        AssertSnapshot(
            view,
            variants: [.defaultLight],
            size: sizeThatFits
        )
    }
    
    func test_microphoneCheckView_micOff_snapshot() throws {
        let view = MicrophoneCheckView(
            audioLevels: [],
            microphoneOn: false,
            isSilent: false,
            isPinned: false
        )
        .frame(width: 100, height: 50)
        AssertSnapshot(
            view,
            variants: [.defaultLight],
            size: sizeThatFits
        )
    }

    func test_microphoneCheckView_pinned_snapshot() throws {
        let view = MicrophoneCheckView(
            audioLevels: [],
            microphoneOn: false,
            isSilent: false,
            isPinned: true
        )
        .frame(width: 100, height: 50)
        AssertSnapshot(
            view,
            variants: [.defaultLight],
            size: sizeThatFits
        )
    }
}
