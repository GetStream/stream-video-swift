//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
@testable import StreamVideo

/// Records the seeks, and keeps the real `play()` and `pause()` of
/// `HLSPlayer`.
final class SeekRecordingHLSPlayer: HLSPlayer, @unchecked Sendable {
    private(set) nonisolated(unsafe) var seekTimes: [CMTime] = []

    override nonisolated func seek(to time: CMTime) { seekTimes.append(time) }
}
