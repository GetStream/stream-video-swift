//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension StreamVideo {
    var callSession: CallSession {
        .init(self)
    }
}

extension StreamVideo {

    struct CallSession {

        let user: User
        let token: UserToken

        fileprivate init(_ streamVideo: StreamVideo) {
            self.user = streamVideo.user
            self.token = streamVideo.token
        }
    }
}
