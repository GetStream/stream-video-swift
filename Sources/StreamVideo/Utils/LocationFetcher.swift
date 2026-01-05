//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

enum LocationFetcher {

    private static let url = URL(string: "https://hint.stream-io-video.com/")!

    static func getLocation() async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        return try await executeTask(retryPolicy: .fastCheckValue { true }) {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let response = response as? HTTPURLResponse {
                let headerKey = "X-Amz-Cf-Pop"
                if let prefix = response.value(forHTTPHeaderField: headerKey)?.prefix(3) {
                    return String(prefix)
                }
            }
            throw FetchingLocationError()
        }
    }
}
