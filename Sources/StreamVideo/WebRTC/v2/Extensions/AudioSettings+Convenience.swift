//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

extension AudioSettings {
    init() {
        accessRequestEnabled = false
        defaultDevice = .unknown
        micDefaultOn = false
        noiseCancellation = nil
        opusDtxEnabled = false
        redundantCodingEnabled = false
        speakerDefaultOn = false
    }
}
