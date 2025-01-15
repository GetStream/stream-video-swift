//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

extension AudioSettings {
    convenience init() {
        self.init(
            accessRequestEnabled: false,
            defaultDevice: .unknown,
            micDefaultOn: false,
            opusDtxEnabled: false,
            redundantCodingEnabled: false,
            speakerDefaultOn: false
        )
    }
}
