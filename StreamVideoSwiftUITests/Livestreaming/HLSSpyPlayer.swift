//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Records the commands sent to a player instead of loading a stream.
final class HLSSpyPlayer: AVPlayer {
    private(set) var playCount = 0
    private(set) var pauseCount = 0
    private(set) var replacedItems: [AVPlayerItem?] = []

    override func play() { playCount += 1 }
    override func pause() { pauseCount += 1 }
    override func replaceCurrentItem(with item: AVPlayerItem?) {
        replacedItems.append(item)
    }
}
