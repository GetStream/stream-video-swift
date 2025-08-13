//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum CallAudioRecording: StoreNamespace {
    typealias State = StoreState
    typealias Action = StoreAction

    static let identifier: String = "call.audio.recording.store"

    static func reducers() -> [Reducer<CallAudioRecording>] {
        [
            DefaultReducer()
        ]
    }

    static func middleware() -> [Middleware<CallAudioRecording>] {
        [
            InterruptionMiddleware(),
            CategoryMiddleware(),
            AVAudioRecorderMiddleware(),
            ActiveCallMiddleware(),
            ApplicationStateMiddleware()
        ]
    }

    static func logger() -> StoreLogger<CallAudioRecording> {
        CallAudioRecordingLogger(logSubsystem: .audioSession)
    }
}
