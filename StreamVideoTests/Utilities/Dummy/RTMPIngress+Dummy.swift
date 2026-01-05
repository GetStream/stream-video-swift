//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension RTMPIngress {
    static func dummy(
        address: String = ""
    ) -> RTMPIngress {
        .init(address: address)
    }
}
