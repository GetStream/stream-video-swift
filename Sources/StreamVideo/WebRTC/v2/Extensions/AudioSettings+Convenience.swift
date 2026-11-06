//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension AudioSettings {
    convenience init() {
        self.init(
            accessRequestEnabled: false,
            defaultDevice: .init(rawValue: ""),
            micDefaultOn: false,
            opusDtxEnabled: false,
            redundantCodingEnabled: false,
            speakerDefaultOn: false
        )
    }
}
