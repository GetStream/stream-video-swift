//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// Conforms the WebRTC audio session to the lightweight protocol used by the
/// store so tests can swap the implementation with fakes.
extension RTCAudioSession: AudioSessionProtocol {
    var avSession: any AVAudioSessionProtocol {
        session
    }
    
    var prefersNoInterruptionsFromSystemAlerts: Bool {
        if #available(iOS 14.5, *) {
            return session.prefersNoInterruptionsFromSystemAlerts
        } else {
            return false
        }
    }
    
    func setPrefersNoInterruptionsFromSystemAlerts(_ newValue: Bool) throws {
        guard #available(iOS 14.5, *) else {
            return
        }
        try session.setPrefersNoInterruptionsFromSystemAlerts(newValue)
    }

    var recordPermissionGranted: Bool {
        if #available(iOS 17.0, *) {
            return AVAudioApplication.shared.recordPermission == .granted
        } else {
            return session.recordPermission == .granted
        }
    }

    func requestRecordPermission() async -> Bool {
        await withCheckedContinuation { continuation in
            session.requestRecordPermission { result in
                continuation.resume(returning: result)
            }
        }
    }

    /// Locks the session for configuration while running the supplied closure.
    func perform(
        _ operation: (AudioSessionProtocol) throws -> Void
    ) throws {
        lockForConfiguration()
        defer { unlockForConfiguration() }
        try operation(self)
    }
}
