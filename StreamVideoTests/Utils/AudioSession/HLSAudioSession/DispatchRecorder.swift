//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

/// Stands in for the audio store: records the batches it receives and
/// fails the ones that match `failing`.
final class DispatchRecorder: @unchecked Sendable {
    @Atomic private var recorded: [[RTCAudioStore.Namespace.Action]] = []
    private let failing: ([RTCAudioStore.Namespace.Action]) -> Bool

    init(failing: @escaping ([RTCAudioStore.Namespace.Action]) -> Bool = { _ in false }) {
        self.failing = failing
    }

    var batches: [[RTCAudioStore.Namespace.Action]] { recorded }

    func reset() {
        recorded = []
    }

    var dispatch: HLSAudioSession.Dispatch {
        { [self] actions in
            recorded.append(actions)
            if failing(actions.map(unwrapped)) {
                throw ClientError("Failed.")
            }
        }
    }

    /// The action inside `.conditioned`, so a test can match on it.
    private func unwrapped(_ action: RTCAudioStore.Namespace.Action) -> RTCAudioStore.Namespace.Action {
        if case let .conditioned(_, nested) = action { return nested }
        return action
    }
}
