//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

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

extension RTCAudioSession: AudioSessionProtocol {
    public func setCategory(_ category: AVAudioSession.Category) throws {
        lockForConfiguration()
        try setCategory(category.rawValue, with: [.allowAirPlay, .allowBluetooth])
        unlockForConfiguration()
    }
    
    public func setActive(_ active: Bool, options: AVAudioSession.SetActiveOptions) throws {
        lockForConfiguration()
        try setActive(active)
        unlockForConfiguration()
    }
    
    public func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }
}
