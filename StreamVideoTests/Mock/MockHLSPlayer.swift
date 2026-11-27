//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo

/// Records the commands sent to a player instead of loading a stream.
final class MockHLSPlayer: HLSPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var playCount = 0
    private(set) nonisolated(unsafe) var pauseCount = 0
    private(set) nonisolated(unsafe) var replacedItems: [AVPlayerItem?] = []
    /// The URLs of the items the player was given, in order.
    nonisolated var reloadedURLs: [URL] {
        replacedItems.compactMap { ($0?.asset as? AVURLAsset)?.url }
    }

    /// What `rate` reports. A player without an item stays at 0.
    nonisolated(unsafe) var stubbedRate: Float = 0
    /// The item `currentItem` reports, until the player clears its item.
    nonisolated(unsafe) var stubbedItem: AVPlayerItem?

    override nonisolated var rate: Float {
        get { stubbedRate }
        set {
            // Notifies KVO observers, which a stubbed property would skip.
            willChangeValue(forKey: "rate")
            stubbedRate = newValue
            didChangeValue(forKey: "rate")
        }
    }

    /// How often `currentItem` was read.
    private(set) nonisolated(unsafe) var currentItemReadCount = 0

    override nonisolated var currentItem: AVPlayerItem? {
        currentItemReadCount += 1
        return stubbedItem ?? super.currentItem
    }

    override nonisolated func play() { playCount += 1 }

    override nonisolated func pause() { pauseCount += 1 }

    override nonisolated func replaceCurrentItem(with item: AVPlayerItem?) {
        replacedItems.append(item)
        // Notifies KVO observers, which a stubbed property would skip.
        willChangeValue(forKey: "currentItem")
        stubbedItem = item
        didChangeValue(forKey: "currentItem")
    }
}
