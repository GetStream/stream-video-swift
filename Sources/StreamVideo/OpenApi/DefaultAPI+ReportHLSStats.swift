//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

extension DefaultAPI {
    /// Posts one HLS playback report.
    ///
    /// The path is `/video/call/{type}/{id}/hls_stats`. The published client
    /// spec does not list this operation yet, so the request lives here until
    /// generation emits it.
    func reportHLSStats(
        type: String,
        id: String,
        report: HLSStatsReport
    ) async throws -> HLSStatsAcknowledgement {
        var path = "/video/call/{type}/{id}/hls_stats"
        let typePreEscape = "\(APIHelper.mapValueToPathItem(type))"
        let typePostEscape = typePreEscape
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "type"),
            with: typePostEscape,
            options: .literal,
            range: nil
        )
        let idPreEscape = "\(APIHelper.mapValueToPathItem(id))"
        let idPostEscape = idPreEscape
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? ""
        path = path.replacingOccurrences(
            of: String(format: "{%@}", "id"),
            with: idPostEscape,
            options: .literal,
            range: nil
        )
        let urlRequest = try makeRequest(
            uriPath: path,
            httpMethod: "POST",
            request: report
        )
        return try await send(request: urlRequest) {
            try self.jsonDecoder.decode(HLSStatsAcknowledgement.self, from: $0)
        }
    }
}
