//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// A simple protocol that abstracts the usage of AVAudioSession.
public protocol AudioSessionProtocol: AnyObject {

    func setCategory(_ category: AVAudioSession.Category) throws

    func setActive(
        _ active: Bool,
        options: AVAudioSession.SetActiveOptions
    ) throws

    func requestRecordPermission() async -> Bool
}

extension AVAudioSession: AudioSessionProtocol {

    public func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            self.requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }
}
