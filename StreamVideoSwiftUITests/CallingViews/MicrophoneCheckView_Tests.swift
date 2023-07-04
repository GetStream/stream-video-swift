//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import SnapshotTesting
import XCTest

@MainActor
final class MicrophoneCheckView_Tests: StreamVideoUITestCase {
    
    let decibels = [Float](repeating: 0.0, count: 10)
    
    func test_microphoneCheckView_withDecibels_snapshot() throws {
        for count in 0...5 {
            let view = MicrophoneCheckView(
                decibels: [Float](repeating: 0.0, count: count),
                microphoneOn: true,
                hasDecibelValues: true
            )
            AssertSnapshot(view, variants: [.defaultLight], size: sizeThatFits, suffix: "with_\(count)_decibels")
        }
    }
    
    func test_microphoneCheckView_withoutDecibels_snapshot() throws {
        let view = MicrophoneCheckView(
            decibels: decibels,
            microphoneOn: true,
            hasDecibelValues: false
        )
        AssertSnapshot(view, variants: [.defaultLight], size: sizeThatFits)
    }
    
    func test_microphoneCheckView_micOff_snapshot() throws {
        let view = MicrophoneCheckView(
            decibels: decibels,
            microphoneOn: false,
            hasDecibelValues: true
        )
        AssertSnapshot(view, variants: [.defaultLight], size: sizeThatFits)
    }
}
