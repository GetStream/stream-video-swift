//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension SFUResponse {
    static func dummy(
        edgeName: String = "",
        url: String = "getstream.io",
        wsEndpoint: String = "wss://getstream.io"
    ) -> SFUResponse {
        .init(
            edgeName: edgeName,
            url: url,
            wsEndpoint: wsEndpoint
        )
    }
}
