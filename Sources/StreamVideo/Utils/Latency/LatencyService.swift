//
//  LatencyService.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 15.7.22.
//

import Foundation

class LatencyService {
    
    private let httpClient: HTTPClient
    
    init(httpClient: HTTPClient) {
        self.httpClient = httpClient
    }
    
    func measureLatency(for edge: Stream_Video_Edge, tries: Int = 1) async -> [Float] {
        guard let url = URL(string: edge.latencyURL) else { return [Float(Int.max)] }
        var results = [Float]()
        for _ in 0..<tries {
            let startDate = Date()
            let request = URLRequest(url: url)
            do {
                _ = try await httpClient.execute(request: request)
                let diff = Float(Date().timeIntervalSince(startDate) * 1000)
                results.append(diff)
            } catch {
                results.append(Float(Int.max))
            }
        }
        return results
    }
    
}
