//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Records the commands sent to a player instead of loading a stream.
final class MockHLSPlayer: AVPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var playCount = 0
    private(set) nonisolated(unsafe) var pauseCount = 0
    private(set) nonisolated(unsafe) var replacedItems: [AVPlayerItem?] = []
    private(set) nonisolated(unsafe) var seekTimes: [CMTime] = []
    /// What `rate` reports. A player without an item stays at 0.
    nonisolated(unsafe) var stubbedRate: Float = 0
    /// The item `currentItem` reports, until the player clears its item.
    nonisolated(unsafe) var stubbedItem: AVPlayerItem?

    override nonisolated var rate: Float {
        get { stubbedRate }
        set { stubbedRate = newValue }
    }

    override nonisolated var currentItem: AVPlayerItem? { stubbedItem ?? super.currentItem }

    override nonisolated func play() { playCount += 1 }

    override nonisolated func pause() { pauseCount += 1 }

    override nonisolated func replaceCurrentItem(with item: AVPlayerItem?) {
        replacedItems.append(item)
        stubbedItem = item
    }

    override nonisolated func seek(to time: CMTime) { seekTimes.append(time) }
}
