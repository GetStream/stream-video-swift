//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension SFUResponse {
    static func dummy(
        edgeName: String = "",
        url: String = "",
        wsEndpoint: String = ""
    ) -> SFUResponse {
        .init(
            edgeName: edgeName,
            url: url,
            wsEndpoint: wsEndpoint
        )
    }
}
