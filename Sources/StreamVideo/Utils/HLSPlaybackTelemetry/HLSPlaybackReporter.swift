//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Sends the HLS playback reports for one player.
///
/// `user_session_id` stays the same from `started` through `ended`.
/// Delivery failures are logged and do not surface to playback.
actor HLSPlaybackReporter {

    private static let reservedEventTypes: Set<String> = [
        "started", "stats", "ended"
    ]

    private let callType: String
    private let callId: String
    private let callSessionId: String
    private let unifiedSessionId: String
    private let userSessionId = UUID().uuidString.lowercased()
    private let sender: HLSStatsSending
    private let now: @Sendable () -> Date
    private let sdk: String
    private let sdkVersion: String
    private let osName: String
    private let osVersion: String

    init(
        callType: String,
        callId: String,
        callSessionId: String,
        unifiedSessionId: String,
        sender: HLSStatsSending,
        now: @escaping @Sendable () -> Date = { Date() },
        sdk: String = "stream-video-ios",
        sdkVersion: String = SystemEnvironment.version,
        osName: String = "iOS",
        osVersion: String = CurrentDevice.currentValue.systemVersion
    ) {
        self.callType = callType
        self.callId = callId
        self.callSessionId = callSessionId
        self.unifiedSessionId = unifiedSessionId
        self.sender = sender
        self.now = now
        self.sdk = sdk
        self.sdkVersion = sdkVersion
        self.osName = String(osName.prefix(64))
        self.osVersion = String(osVersion.prefix(64))
    }

    func start() async {
        await send(type: "started", measurement: nil, events: [], endReason: nil, errorCode: nil)
    }

    func report(
        measurement: HLSPlaybackMeasurement,
        events: [HLSPlaybackEvent]
    ) async {
        await send(
            type: "stats",
            measurement: measurement,
            events: events,
            endReason: nil,
            errorCode: nil
        )
    }

    func stop(errorCode: String?) async {
        let code = errorCode.map { String($0.prefix(128)) }.flatMap { $0.isEmpty ? nil : $0 }
        await send(
            type: "ended",
            measurement: nil,
            events: [],
            endReason: code == nil ? "left" : "error",
            errorCode: code
        )
    }

    private func send(
        type: String,
        measurement: HLSPlaybackMeasurement?,
        events: [HLSPlaybackEvent],
        endReason: String?,
        errorCode: String?
    ) async {
        let kept = events
            .filter { !Self.reservedEventTypes.contains($0.type) }
            .suffix(100)
        let report = HLSStatsReport(
            callSessionId: callSessionId,
            userSessionId: userSessionId,
            unifiedSessionId: unifiedSessionId,
            type: type,
            timestamp: Int64(now().timeIntervalSince1970 * 1000),
            sdk: sdk,
            sdkVersion: sdkVersion,
            os: osName,
            osVersion: osVersion,
            endReason: endReason,
            errorCode: errorCode,
            stats: measurement.map(HLSPlaybackStats.init),
            events: kept.map {
                HLSStatsEvent(type: $0.type, timestamp: $0.timestamp, data: $0.data)
            }
        )
        var retries = 0
        let policy = RetryPolicy.clientEventReporting
        while true {
            do {
                try await sender.reportHLSStats(
                    callType: callType,
                    callId: callId,
                    report: report
                )
                return
            } catch {
                guard retries < policy.maxRetries, error.hasClientErrors else {
                    log.debug(
                        "Failed to report HLS playback \(type): \(error)",
                        subsystems: .webRTC
                    )
                    return
                }
                let delay = policy.delay(retries)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                retries += 1
            }
        }
    }
}

extension HLSPlaybackStats {
    init(_ measurement: HLSPlaybackMeasurement) {
        self.init(
            watchDurationMs: measurement.watchDurationMs,
            stallCount: measurement.stallCount,
            stallDurationMs: measurement.stallDurationMs,
            maxStallDurationMs: measurement.maxStallDurationMs,
            droppedFrames: measurement.droppedFrames,
            bitrateKbps: measurement.bitrateKbps,
            bufferLengthMs: measurement.bufferLengthMs,
            liveLatencyMs: measurement.liveLatencyMs,
            width: measurement.width,
            height: measurement.height
        )
    }
}
