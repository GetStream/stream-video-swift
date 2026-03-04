//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension StreamVideo.CallSession {
    static func dummy(
        user: User = .dummy(),
        token: UserToken = .empty
    ) -> Self {
        .init(user: user, token: token)
    }
}
