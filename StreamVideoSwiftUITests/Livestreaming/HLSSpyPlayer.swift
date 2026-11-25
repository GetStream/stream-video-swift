//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Records the commands sent to a player instead of loading a stream.
/// Xcode 16 SDKs leave the overrides nonisolated, so the counters are too.
final class HLSSpyPlayer: AVPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var playCount = 0
    private(set) nonisolated(unsafe) var pauseCount = 0
    private(set) nonisolated(unsafe) var replacedItems: [AVPlayerItem?] = []

    override nonisolated func play() { playCount += 1 }
    override nonisolated func pause() { pauseCount += 1 }
    override nonisolated func replaceCurrentItem(with item: AVPlayerItem?) {
        replacedItems.append(item)
    }
}
