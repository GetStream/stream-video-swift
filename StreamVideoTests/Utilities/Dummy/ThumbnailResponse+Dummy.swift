//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension ThumbnailResponse {
    static func dummy(
        imageUrl: String = ""
    ) -> ThumbnailResponse {
        .init(imageUrl: imageUrl)
    }
}
