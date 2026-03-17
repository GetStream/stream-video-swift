//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Builds and sends telemetry for a join flow once the state machine reaches
/// the point where the flow outcome is known.
struct JoinedStateTelemetryReporter {

    /// Describes the join or reconnection path that completed.
    enum FlowType { case regular, fast, rejoin, migrate }

    /// The join flow that should be encoded in the telemetry payload.
    var flowType: FlowType = .regular

    private let startTime = Date()

    /// Reports telemetry for the completed join flow.
    ///
    /// Regular joins send the elapsed connection time. Reconnect flows send a
    /// reconnection payload with the selected strategy and elapsed duration.
    ///
    /// - Parameters:
    ///   - sessionId: The SFU session identifier for the active participant.
    ///   - unifiedSessionId: The identifier shared across reconnect attempts.
    ///   - sfuAdapter: The adapter that submits telemetry to the SFU.
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
