//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Carries the health-check payloads surfaced by the coordinator/SFU sockets.
///
/// Retained after the StreamCore WebSocket migration (extracted from the deleted
/// `WebSocketPingController`) since it's still the associated value of
/// ``WebSocketConnectionState/connected(healthCheckInfo:)`` and how the
/// coordinator connection id is read.
struct HealthCheckInfo: Equatable {
    var coordinatorHealthCheck: HealthCheckEvent?
    var sfuHealthCheck: Stream_Video_Sfu_Event_HealthCheckResponse?
}
