//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
@testable import StreamVideo
import XCTest

final class AVAudioSessionCategoryOptionsTests: XCTestCase, @unchecked Sendable {

    // MARK: - playAndRecord
    
    func test_playAndRecord_whenAccessed_thenReturnsExpectedOptions() {
        XCTAssertEqual(
            AVAudioSession.CategoryOptions.playAndRecord,
            [.allowBluetooth, .allowBluetoothA2DP, .allowAirPlay]
        )
    }
    
    // MARK: - playback
    
    func test_playback_whenAccessed_thenReturnsEmptyOptions() {
        XCTAssertEqual(AVAudioSession.CategoryOptions.playback, [])
    }
}
