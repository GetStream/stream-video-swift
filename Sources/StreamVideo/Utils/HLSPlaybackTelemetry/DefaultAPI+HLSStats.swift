//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

private struct HLSStatsAcknowledgement: Decodable {}

@_spi(StreamVideo)
extension DefaultAPI: HLSStatsSending {
    public func reportHLSStats(
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
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: report
        )
        _ = try await send(request: urlRequest) {
            try self.jsonDecoder.decode(HLSStatsAcknowledgement.self, from: $0)
        }
    }
}
