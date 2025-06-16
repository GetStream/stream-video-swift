//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension WebRTCTrace {
    static func dummy(
        id: String? = nil,
        tag: String = .unique,
        data: AnyEncodable? = nil,
        timestamp: Int64 = 0
    ) -> WebRTCTrace {
        .init(
            id: id,
            tag: tag,
            data: data,
            timestamp: timestamp
        )
    }
}
