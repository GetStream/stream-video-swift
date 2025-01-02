//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension EgressHLSResponse {
    static func dummy(
        playlistUrl: String = ""
    ) -> EgressHLSResponse {
        .init(playlistUrl: playlistUrl)
    }
}
