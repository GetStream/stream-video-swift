//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
