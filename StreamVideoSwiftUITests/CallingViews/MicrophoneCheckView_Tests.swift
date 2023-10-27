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
    
    let audioLevels = [Float](repeating: 0.0, count: 10)
    
    func test_microphoneCheckView_withAudioLevels_snapshot() throws {
        for count in 0...5 {
            let view = MicrophoneCheckView(
                audioLevels: [Float](repeating: 0.0, count: count),
                microphoneOn: true,
                isSilent: false
            )
            AssertSnapshot(view, size: sizeThatFits, suffix: "with_\(count)_audioLevels")
        }
    }
    
    func test_microphoneCheckView_withoutAudioLevels_snapshot() throws {
        let view = MicrophoneCheckView(
            audioLevels: audioLevels,
            microphoneOn: true,
            isSilent: true
        )
        AssertSnapshot(view, variants: [.defaultLight], size: sizeThatFits)
    }
    
    func test_microphoneCheckView_micOff_snapshot() throws {
        let view = MicrophoneCheckView(
            audioLevels: audioLevels,
            microphoneOn: false,
            isSilent: false
        )
        AssertSnapshot(view, variants: [.defaultLight], size: sizeThatFits)
    }
}
