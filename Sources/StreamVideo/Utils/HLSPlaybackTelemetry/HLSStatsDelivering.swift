//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sends one HLS playback report to the coordinator.
protocol HLSStatsDelivering {
    func deliver(
        callType: String,
        callId: String,
        report: HLSStatsReport
    ) async throws
}
