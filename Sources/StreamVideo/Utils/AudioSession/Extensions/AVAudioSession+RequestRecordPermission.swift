//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

extension AVAudioSession {
    /// Asynchronously requests permission to record audio.
    /// - Returns: A Boolean indicating whether permission was granted.
    private func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            self.requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }
}
