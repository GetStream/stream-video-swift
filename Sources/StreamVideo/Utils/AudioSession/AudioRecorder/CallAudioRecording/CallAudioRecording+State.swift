//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallAudioRecording {
    struct StoreState: Equatable {
        var isRecording: Bool
        var isInterrupted: Bool
        var shouldRecord: Bool
        var meter: Float

        static let initial = State(
            isRecording: false,
            isInterrupted: false,
            shouldRecord: false,
            meter: 0
        )
    }
}
