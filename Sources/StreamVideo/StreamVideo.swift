//
//  StreamVideo.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 7.7.22.
//

import Foundation

public class StreamVideo {
    
    // Temporarly storing user in memory.
    private var userInfo: UserInfo?
    private var token: Token? {
        didSet {
            if let token = token {
                callCoordinatorService.update(userToken: token.rawValue)
            }
        }
    }
    // Change it to your local IP address.
    private let hostname = "http://192.168.0.132:26991"
    
    var callCoordinatorService: Stream_Video_CallCoordinatorService
    
    let apiKey: String
    let videoService = VideoService()
    
    public init(apiKey: String) {
        self.apiKey = apiKey
        self.callCoordinatorService = Stream_Video_CallCoordinatorService(
            hostname: hostname,
            token: ""
        )
        StreamVideoProviderKey.currentValue = self
    }
    
    public func connectUser(
        userInfo: UserInfo,
        token: Token
    ) async throws {
        self.userInfo = userInfo
        self.token = token
    }
    
    public func joinRoom(
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
