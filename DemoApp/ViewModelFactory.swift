//
//  ViewModelFactory.swift
//  StreamVideoSwiftUI
//
//  Created by Martin Mitrevski on 24.6.22.
//

import Foundation

class ViewModelFactory {
    
    static let shared = ViewModelFactory()
    
    private let config: Config
    private let webRTCClient: WebRTCClient
    private let signalClient: SignalingClient
    
    private init() {
        config = Config.default
        webRTCClient = WebRTCClient(iceServers: config.webRTCIceServers)
        signalClient = SignalingClient(webSocket: URLSessionWebSocket(url: config.signalingServerUrl))
    }
    
    @MainActor func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(signalClient: signalClient, webRTCClient: webRTCClient)
    }
    
    @MainActor func makeVideoViewModel() -> VideoViewModel {
        VideoViewModel(webRTCClient: webRTCClient, signalClient: signalClient)
    }
    
}
