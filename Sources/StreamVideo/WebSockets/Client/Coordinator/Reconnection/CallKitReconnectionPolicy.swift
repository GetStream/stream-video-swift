//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import StreamCore

/// Allows reconnection while there's an active CallKit call.
///
/// This is the video-specific policy StreamCore's recovery handler lacks; it lets
/// the coordinator socket recover in the background during a VoIP call. The
/// "has active call" check is injected as a closure because `callKitService` is
/// resolved via video's DI (`@Injected`), which is ambiguous inside a
/// StreamCore-importing file.
struct CallKitReconnectionPolicy: AutomaticReconnectionPolicy {
    private let hasActiveCall: @Sendable () -> Bool

    init(hasActiveCall: @escaping @Sendable () -> Bool) {
        self.hasActiveCall = hasActiveCall
    }

    func canBeReconnected() -> Bool {
        hasActiveCall()
    }
}
