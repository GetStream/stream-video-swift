//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

struct HTTPConfig {
    var retryStrategy: RetryStrategy
    let maxRetries: Int
}

extension HTTPConfig {
    static let `default` = HTTPConfig(
        retryStrategy: DefaultRetryStrategy(),
        maxRetries: 5
    )
}
