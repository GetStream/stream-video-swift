//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation

class LocationFetcher {
    
    static func getLocation() async throws -> String {
        guard let url = URL(string: "https://hint.stream-io-video.com/") else {
            throw URLError(.badURL)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
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
