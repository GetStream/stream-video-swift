//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamVideo

extension Credentials {
    static func dummy(
        iceServers: [ICEServer] = [],
        server: SFUResponse = .dummy(),
        token: String = ""
    ) -> Credentials {
        .init(
            iceServers: iceServers,
            server: server,
            token: token
        )
    }
}
