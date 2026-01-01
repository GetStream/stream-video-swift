//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

/// Protocol for providing microphone permission management.
protocol MicrophonePermissionProviding {
    
    /// The current microphone permission status from the system.
    var systemPermission: PermissionStore.Permission { get }
    
    /// Requests microphone permission from the user.
    /// - Parameter completion: Called with `true` if permission granted.
    func requestPermission(_ completion: @Sendable @escaping (Bool) -> Void)
}

/// Default implementation for microphone permission management using
/// AVFoundation.
final class StreamMicrophonePermissionProvider: MicrophonePermissionProviding {
    var systemPermission: PermissionStore.Permission {
        if #available(iOS 17.0, *) {
            switch AVAudioApplication.shared.recordPermission {
            case .undetermined:
                return .unknown
            case .denied:
                return .denied
            case .granted:
                return .granted
            @unknown default:
                return .unknown
            }
        } else {
            switch AVAudioSession.sharedInstance().recordPermission {
            case .undetermined:
                return .unknown
            case .denied:
                return .denied
            case .granted:
                return .granted
            @unknown default:
                return .unknown
            }
        }
    }

    func requestPermission(_ completion: @Sendable @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication
                .requestRecordPermission(completionHandler: completion)
        } else {
            AVAudioSession
                .sharedInstance()
                .requestRecordPermission(completion)
        }
    }
}
