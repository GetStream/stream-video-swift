//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

/// A reducer responsible for managing changes to the audio session state within the WebRTC context.
/// This class listens for audio-related actions and applies corresponding updates to the shared
/// `RTCAudioSession` instance, ensuring the audio session is configured and controlled consistently.
/// It handles activation, interruption, audio enabling, category settings, output port overrides,
/// and permissions, encapsulating the logic for applying these changes safely and atomically.
final class RTCAudioSessionReducer: RTCAudioStoreReducer {

    private let source: AudioSessionProtocol

    /// Initializes the reducer with a given `RTCAudioSession` source.
    /// - Parameter source: The audio session instance to manage. Defaults to the shared singleton.
    init(store: RTCAudioStore) {
        source = store.session
    }

    // MARK: - RTCAudioStoreReducer

    /// Processes an audio-related action and returns the updated audio store state.
    ///
    /// This method interprets the provided action, performs necessary operations on the underlying
    /// `RTCAudioSession`, and returns a new state reflecting any changes. It safely handles session
    /// configuration updates and respects current state to avoid redundant operations.
    ///
    /// - Parameters:
    ///   - state: The current audio store state.
    ///   - action: The action to apply to the state.
    ///   - file: The source file from which the action originated.
    ///   - function: The function from which the action originated.
    ///   - line: The line number from which the action originated.
    /// - Throws: Rethrows errors from audio session configuration operations.
    /// - Returns: The updated audio store state after applying the action.
    func reduce(
        state: RTCAudioStore.State,
        action: RTCAudioStoreAction,
        file: StaticString,
        function: StaticString,
        line: UInt
    ) throws -> RTCAudioStore.State {
        guard
            case let .audioSession(action) = action
        else {
            return state
        }

        var updatedState = state

        switch action {
        case let .isActive(value):
            guard updatedState.isActive != value else {
                break
            }
            try source.perform { try $0.setActive(value) }
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
            try source.perform {
                /// We update the `webRTC` default configuration because, the WebRTC audioStack
                /// can be restarted for various reasons. When the stack restarts it gets reconfigured
                /// with the `webRTC` configuration. If then the configuration is invalid compared
                /// to the state we expect we may find ourselves in a difficult to recover situation,
                /// as our callSetting may be failing to get applied.
                /// By updating the `webRTC` configuration we ensure that the audioStack will
                /// start from the last known state in every restart, making things simpler to recover.
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
            try source.perform {
                try $0.overrideOutputAudioPort(port)
            }

            updatedState.overrideOutputAudioPort = port

        case let .setPrefersNoInterruptionsFromSystemAlerts(value):
            if #available(iOS 14.5, *) {
                try source.perform {
                    try $0.setPrefersNoInterruptionsFromSystemAlerts(value)
                }

                updatedState.prefersNoInterruptionsFromSystemAlerts = value
            }

        case let .setHasRecordingPermission(value):
            updatedState.hasRecordingPermission = value

        case let .setAVAudioSessionActive(value):
            /// In the case where audioOutputOn has changed the order of actions matters
            /// When activating we need:
            /// 1. activate AVAudioSession
            /// 2. set isAudioEnabled = true
            /// 3. set RTCAudioSession.isActive = true
            ///
            /// When deactivating we need:
            /// 1. set RTCAudioSession.isActive = false
            /// 2. set isAudioEnabled = false
            /// 3. deactivate AVAudioSession
            ///
            /// - Weird behaviour:
            /// We ignore the errors in AVAudioSession as in the case of CallKit we may fail to
            /// deactivate the call but the following calls will ensure that there is no audio.
            try source.perform {
                if value {
                    try? $0.avSession.setIsActive(value)
                    $0.isAudioEnabled = value
                    try $0.setActive(value)
                } else {
                    try? $0.setActive(value)
                    $0.isAudioEnabled = value
                    try? $0.avSession.setIsActive(value)
                }
            }
            updatedState.isActive = value
            updatedState.isAudioEnabled = value

        case let .setAudioDeviceModule(value):
            updatedState.audioDeviceModule = value
        }

        return updatedState
    }
}
