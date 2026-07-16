//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Internal aliases so `CoordinatorWebSocket` (which imports StreamCore) can name
// video's own versions of types that are *also* declared in StreamCore
// (`WebSocketConnectionState`, `HealthCheckInfo`, `ClientError`). Inside a
// StreamCore-importing file those bare names are ambiguous, and
// `StreamVideo.X` resolves into the `StreamVideo` class rather than the module —
// so these aliases (declared here, in a StreamCore-free file) are the way to
// reference the video types unambiguously.
//
// TODO: [IOS-1812] Delete these aliases with `CoordinatorWebSocket` after the
// remaining connection and error types are unified.

typealias VideoWebSocketConnectionState = WebSocketConnectionState
typealias VideoHealthCheckInfo = HealthCheckInfo
typealias VideoClientError = ClientError
