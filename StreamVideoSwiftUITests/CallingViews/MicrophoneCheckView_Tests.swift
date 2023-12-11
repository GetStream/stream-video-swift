//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
import SnapshotTesting
import XCTest

@MainActor
final class MicrophoneCheckView_Tests: StreamVideoUITestCase {

    func test_microphoneCheckView_withAudioLevels_snapshot() throws {
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
