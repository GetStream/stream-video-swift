//
//  StreamVideo.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import Foundation

class StreamVideo {
    
    let apiKey: String
    let videoService = VideoService()
    
    init(apiKey: String) {
        self.apiKey = apiKey
        StreamVideoProviderKey.currentValue = self
    }
    
    func connect(
        url: String,
        token: String,
        options: VideoOptions
    ) async throws -> VideoRoom {
        return try await videoService.connect(
            url: url,
            token: token,
            options: options
        )
    }
    
}

/// Returns the current value for the `StreamVideo` instance.
internal struct StreamVideoProviderKey: InjectionKey {
    static var currentValue: StreamVideo?
}
