//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

struct JoinedStateTelemetryReporter {

    enum FlowType { case regular, fast, rejoin, migrate }

    var flowType: FlowType = .regular

    private let startTime = Date()

    /// Reports telemetry data to the SFU (Selective Forwarding Unit) to monitor and analyze the
    /// connection lifecycle.
    ///
    /// This method collects relevant metrics based on the flow type of the connection, such as
    /// connection time or reconnection details, and sends them to the SFU for logging and diagnostics.
    /// The telemetry data provides insights into the connection's performance and the strategies used
    /// during rejoin
    /// ing, fast reconnecting, or migration.
    ///
    /// The reported data includes:
    /// - Connection time in seconds for a regular flow.
    /// - Reconnection strategies (e.g., fast reconnect, rejoin, or migration) and their duration.
    func reportTelemetry(
        sessionId: String,
        unifiedSessionId: String,
        sfuAdapter: SFUAdapter
    ) async {
        var telemetry = Stream_Video_Sfu_Signal_Telemetry()
        let duration = Float(Date().timeIntervalSince(startTime))
        var reconnection = Stream_Video_Sfu_Signal_Reconnection()
        reconnection.timeSeconds = duration

        telemetry.data = {
            switch self.flowType {
            case .regular:
                return .connectionTimeSeconds(duration)
            case .fast:
                var reconnection = Stream_Video_Sfu_Signal_Reconnection()
                reconnection.strategy = .fast
                return .reconnection(reconnection)
            case .rejoin:
                reconnection.strategy = .rejoin
                return .reconnection(reconnection)
            case .migrate:
                reconnection.strategy = .migrate
                return .reconnection(reconnection)
            }
        }()

        do {
            try await sfuAdapter.sendStats(
                for: sessionId,
                unifiedSessionId: unifiedSessionId,
                telemetry: telemetry
            )
            log.debug("Join call completed in \(duration) seconds.")
        } catch {
            log.error(error)
        }
    }
}
