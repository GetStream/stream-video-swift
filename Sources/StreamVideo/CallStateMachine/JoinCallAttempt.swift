//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Stop rule shared by the call joining stage and the WebRTC
/// disconnected stage.
///
/// A backstage refusal, an API rate limit, or an error the backend
/// marks unrecoverable cannot succeed on another `joinCall`.
enum JoinCallAttempt {
    static func shouldStop(_ error: Error) -> Bool {
        let apiError = (error as? APIError)
            ?? (error as? ClientError)?.apiError
        guard let apiError else {
            return false
        }
        if apiError.unrecoverable == true {
            return true
        }
        if apiError.statusCode == 429 {
            return true
        }
        return apiError.statusCode == 403
            && apiError.message.contains("JoinBackstage")
    }
}
