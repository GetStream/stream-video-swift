//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

// Internal aliases so `CoordinatorWebSocket` (which imports StreamCore) can name
// video's own versions of types that are *also* declared in StreamCore
// (`WebSocketConnectionState`, `HealthCheckInfo`, `ClientError`,
// `EventNotificationCenter`). Inside a StreamCore-importing file those bare names
// are ambiguous, and `StreamVideo.X` resolves into the `StreamVideo` class rather
// than the module — so these aliases (declared here, in a StreamCore-free file)
// are the way to reference the video types unambiguously.
//
// TODO: [StreamCore migration] These aliases only exist to bridge video's
// duplicated types across the wrapper boundary. Once `ClientError`,
// `EventNotificationCenter`, and the connection-state/health-check types are
// unified on StreamCore (leaf migration) and the wrapper is retired, delete
// these aliases.

typealias VideoWebSocketConnectionState = WebSocketConnectionState
typealias VideoHealthCheckInfo = HealthCheckInfo
typealias VideoClientError = ClientError
typealias VideoEventNotificationCenter = EventNotificationCenter
