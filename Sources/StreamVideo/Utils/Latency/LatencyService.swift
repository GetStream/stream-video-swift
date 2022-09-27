//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

final class LatencyService: Sendable {
    
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func measureLatency(for endpoint: Stream_Video_Edge, tries: Int = 1) async -> [Double] {
        guard let url = URL(string: endpoint.latencyURL) else { return [Double(Int.max)] }
        var results = [Double]()
        for _ in 0..<tries {
            let startDate = Date()
            let request = URLRequest(url: url)
            do {
                _ = try await httpClient.execute(request: request)
                let diff = Double(Date().timeIntervalSince(startDate))
                results.append(diff)
            } catch {
                results.append(Double(Int.max))
            }
        }
        return results
    }
}
