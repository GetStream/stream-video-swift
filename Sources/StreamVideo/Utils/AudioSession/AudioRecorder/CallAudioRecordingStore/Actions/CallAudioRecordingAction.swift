//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

enum CallAudioRecordingAction: Sendable {
    case setIsRecording(Bool)
    case setIsInterrupted(Bool)
    case setShouldRecord(Bool)
    case setMeter(Float)
}
