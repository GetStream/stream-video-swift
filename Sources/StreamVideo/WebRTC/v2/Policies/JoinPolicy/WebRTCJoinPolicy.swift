//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Controls when ``Call/join(create:options:ring:notify:callSettings:policy:)``
/// completes relative to the underlying WebRTC transport.
public enum WebRTCJoinPolicy: Sendable {
    /// Completes the join request as soon as the SFU join flow succeeds.
    case `default`

    /// Waits until both peer connections report `.connected`, or until the
    /// timeout elapses, before completing the join request.
    case peerConnectionReadinessAware(timeout: TimeInterval)
}
