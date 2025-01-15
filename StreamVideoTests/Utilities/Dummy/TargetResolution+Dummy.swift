//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension TargetResolution {
    static func dummy(
        bitrate: Int = 0,
        height: Int = 0,
        width: Int = 0
    ) -> TargetResolution {
        .init(bitrate: bitrate, height: height, width: width)
    }
}
