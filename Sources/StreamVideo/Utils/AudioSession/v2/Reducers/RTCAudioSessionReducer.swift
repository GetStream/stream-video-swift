//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class RTCAudioSessionReducer: RTCAudioStoreReducer {

    private let source: RTCAudioSession

    init(source: RTCAudioSession = .sharedInstance()) {
        self.source = source
    }

    // MARK: - RTCAudioStoreReducer

    func reduce(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> RTCAudioStore.State {
        guard
            case let .rtc(action) = action
        else {
            return state
        }

        var updatedState = state

        switch action {
        case let .isActive(value):
            guard updatedState.isActive != value else {
                break
            }
            try perform { try $0.setActive(value) }
            updatedState.isActive = value

        case let .isInterrupted(value):
            updatedState.isInterrupted = value

        case let .isAudioEnabled(value):
            source.isAudioEnabled = value
            updatedState.isAudioEnabled = value

        case let .useManualAudio(value):
            source.useManualAudio = value
            updatedState.useManualAudio = value

        case let .setCategory(category, mode, options):
            try perform {
                let webRTCConfiguration = RTCAudioSessionConfiguration.webRTC()
                webRTCConfiguration.category = category.rawValue
                webRTCConfiguration.mode = mode.rawValue
                webRTCConfiguration.categoryOptions = options

                try $0.setConfiguration(webRTCConfiguration)
                RTCAudioSessionConfiguration.setWebRTC(webRTCConfiguration)
            }

            updatedState.category = category
            updatedState.mode = mode
            updatedState.options = options

        case let .setOverrideOutputPort(port):
            try perform {
                try $0.overrideOutputAudioPort(port)
            }

            updatedState.overrideOutputAudioPort = port

        case let .setPrefersNoInterruptionsFromSystemAlerts(value):
            if #available(iOS 14.5, *) {
                try perform {
                    try $0.session.setPrefersNoInterruptionsFromSystemAlerts(value)
                }

                updatedState.prefersNoInterruptionsFromSystemAlerts = value
            }

        case let .setHasRecordingPermission(value):
            updatedState.hasRecordingPermission = value
        }

        return updatedState
    }

    // MARK: - Private Helpers

    private func perform(
        _ operation: (RTCAudioSession) throws -> Void
    ) throws {
        source.lockForConfiguration()
        defer { source.unlockForConfiguration() }
        try operation(source)
    }
}

extension RTCAudioSessionReducer {

    enum Action {
        case isActive(Bool)

        case isInterrupted(Bool)

        case isAudioEnabled(Bool)

        case useManualAudio(Bool)

        case setCategory(
            AVAudioSession.Category,
            mode: AVAudioSession.Mode,
            options: AVAudioSession.CategoryOptions
        )

        case setOverrideOutputPort(AVAudioSession.PortOverride)

        case setPrefersNoInterruptionsFromSystemAlerts(Bool)

        case setHasRecordingPermission(Bool)
    }
}
