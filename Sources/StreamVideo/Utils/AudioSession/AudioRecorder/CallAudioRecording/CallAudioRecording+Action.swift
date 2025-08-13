//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension CallAudioRecording {
    enum StoreAction: Sendable {
        case setIsRecording(Bool)
        case setIsInterrupted(Bool)
        case setShouldRecord(Bool)
        case setMeter(Float)
    }
}
