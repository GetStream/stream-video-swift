//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

struct HTTPConfig: Sendable {
    var retryStrategy: RetryStrategy
    let maxRetries: Int
}

extension HTTPConfig {
    static let `default` = HTTPConfig(
        retryStrategy: DefaultRetryStrategy(),
        maxRetries: 5
    )
}
