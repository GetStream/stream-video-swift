//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamWebRTC

final class CallKitAudioSessionReducer: RTCAudioStoreReducer {

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
            case let .callKit(action) = action
        else {
            return state
        }

        var updatedState = state

        switch action {
        case let .activate(audioSession):
            source.audioSessionDidActivate(audioSession)
            updatedState.isActive = source.isActive

        case let .deactivate(audioSession):
            source.audioSessionDidDeactivate(audioSession)
            updatedState.isActive = source.isActive
        }

        return updatedState
    }
}

extension CallKitAudioSessionReducer {

    enum Action {
        case activate(AVAudioSession)

        case deactivate(AVAudioSession)
    }
}
