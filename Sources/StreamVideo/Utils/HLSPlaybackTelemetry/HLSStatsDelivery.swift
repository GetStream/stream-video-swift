//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

/// Posts one HLS playback report with the same retry policy as client events.
///
/// The published video client spec has no `hls_stats` operation, so this
/// uses ``DefaultAPI``'s request builder instead of a generated method.
final class HLSStatsDelivery: HLSStatsDelivering, @unchecked Sendable {
    private let api: DefaultAPI
    private let retryPolicy: RetryPolicy

    init?(
        endpoints: DefaultAPIEndpoints,
        retryPolicy: RetryPolicy = .clientEventReporting
    ) {
        guard let api = endpoints as? DefaultAPI else { return nil }
        self.api = api
        self.retryPolicy = retryPolicy
    }

    func deliver(
        callType: String,
        callId: String,
        report: HLSStatsReport
    ) async throws {
        var retries = 0
        while true {
            do {
                try await post(callType: callType, callId: callId, report: report)
                return
            } catch {
                guard retries < retryPolicy.maxRetries, error.hasClientErrors else {
                    log.debug(
                        "Failed to report HLS playback \(report.type): \(error)",
                        subsystems: .webRTC
                    )
                    return
                }
                let delay = retryPolicy.delay(retries)
                try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                retries += 1
            }
        }
    }

    private func post(
        callType: String,
        callId: String,
        report: HLSStatsReport
    ) async throws {
        var path = "/video/call/{type}/{id}/hls_stats"
        let type = "\(APIHelper.mapValueToPathItem(callType))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        let id = "\(APIHelper.mapValueToPathItem(callId))"
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "type"),
            with: type,
            options: .literal
        )
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "id"),
            with: id,
            options: .literal
        )
        let urlRequest = try api.makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: report
        )
        _ = try await api.send(request: urlRequest) {
            try self.api.jsonDecoder.decode(HLSStatsAcknowledgement.self, from: $0)
        }
    }
}
