//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Records the commands sent to a player instead of loading a stream.
final class HLSSpyPlayer: AVPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var playCount = 0
    private(set) nonisolated(unsafe) var pauseCount = 0
    private(set) nonisolated(unsafe) var replacedItems: [AVPlayerItem?] = []

    override func play() { playCount += 1 }
    override func pause() { pauseCount += 1 }
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        replacedItems.append(item)
    }
}
