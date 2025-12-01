//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import CoreImage
import Foundation
import StreamVideo

extension VideoFilter {

    static func dummy(
        id: String = .unique,
        name: String = .unique,
        filter: @escaping (Input) async -> CIImage = \.originalImage
    ) -> VideoFilter {
        .init(
            id: id,
            name: name,
            filter: filter
        )
    }
}
