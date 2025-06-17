//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation

struct AudioLevel: Identifiable {
    var id: String {
        "\(index)-\(value)"
    }

    let value: Float
    let index: Int
}
