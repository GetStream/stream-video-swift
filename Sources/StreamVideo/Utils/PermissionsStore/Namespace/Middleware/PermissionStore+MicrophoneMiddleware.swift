//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import AVFoundation
import Foundation
import StreamWebRTC

extension PermissionStore {

    final class MicrophoneMiddleware: Middleware<Namespace>, @unchecked Sendable {

        override var dispatcher: Store<PermissionStore.Namespace>.Dispatcher? {
            didSet { dispatcher?.dispatch(.setMicrophonePermission(systemPermission)) }
        }

        override func apply(
            state: PermissionStore.StoreState,
            action: PermissionStore.StoreAction,
            file: StaticString,
            function: StaticString,
            line: UInt
        ) {
            switch action {
            case .requestMicrophonePermission:
                requestPermission()

            default:
                break
            }
        }

        // MARK: - Private Helpers

        private var systemPermission: Permission {
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

        private func requestPermission() {
            if #available(iOS 17.0, *) {
                AVAudioApplication.requestRecordPermission { [weak self] in
                    self?.dispatcher?.dispatch(.setMicrophonePermission($0 ? .granted : .denied))
                }
            } else {
                return AVAudioSession.sharedInstance().requestRecordPermission { [weak self] in
                    self?.dispatcher?.dispatch(.setMicrophonePermission($0 ? .granted : .denied))
                }
            }
        }
    }
}
