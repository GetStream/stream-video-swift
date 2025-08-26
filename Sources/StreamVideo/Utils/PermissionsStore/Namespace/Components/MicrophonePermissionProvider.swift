//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation

protocol MicrophonePermissionProviding {

    var systemPermission: PermissionStore.Permission { get }

    func requestPermission(_ completion: @escaping (Bool) -> Void)
}

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

    func requestPermission(_ completion: @escaping (Bool) -> Void) {
        if #available(iOS 17.0, *) {
            AVAudioApplication
                .requestRecordPermission(completionHandler: completion)
        } else {
            return AVAudioSession
                .sharedInstance()
                .requestRecordPermission(completion)
        }
    }
}
