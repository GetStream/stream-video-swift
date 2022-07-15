//
//  LatencyService.swift
//  StreamVideo
//
//  Created by Martin Mitrevski on 15.7.22.
//

import Foundation

class LatencyService {
    
    private let urlSession: URLSession
    
    init(urlSession: URLSession) {
        self.urlSession = urlSession
    }
    
    func measureLatency(for edge: Stream_Video_Edge) async -> [Float] {
        //TODO: implement
        return [0.5, 0.4, 0.2]
    }
    
}
