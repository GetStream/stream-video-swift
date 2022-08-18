//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation

class WebRTCClient {
    
    // TODO: check if this state is really needed.
    actor State {
        var connectionStatus = VideoConnectionStatus.disconnected(reason: nil)
        
        func update(connectionStatus: VideoConnectionStatus) {
            self.connectionStatus = connectionStatus
        }
    }
    
    var state = State()
    
    let httpClient: HTTPClient
    let webSocketClient: WebSocketClient
    let signalClient: SignalClient
    let eventNotificationCenter: EventNotificationCenter
    let eventsMiddleware: WebRTCEventsMiddleware
    
    init(
        apiKey: String,
        hostname: String,
        token: String,
        connectURL: URL,
        tokenProvider: @escaping TokenProvider
    ) {
        httpClient = URLSessionClient(
            urlSession: StreamVideo.makeURLSession(),
            tokenProvider: tokenProvider
        )
        
        let config = URLSessionConfiguration.default
        config.waitsForConnectivity = false
        
        let eventsMiddleware = WebRTCEventsMiddleware()
        eventNotificationCenter = {
            let center = EventNotificationCenter()
            let middlewares: [EventMiddleware] = [
                eventsMiddleware
            ]
            center.add(middlewares: middlewares)
            return center
        }()
        self.eventsMiddleware = eventsMiddleware
        
        webSocketClient = WebSocketClient(
            sessionConfiguration: config,
            eventDecoder: WebRTCEventDecoder(),
            eventNotificationCenter: eventNotificationCenter,
            connectURL: connectURL,
            requiresAuth: false
        )
        
        signalClient = SignalClient(
            webSocketClient: webSocketClient,
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
    }
    
    // TODO: connectOptions / roomOptions
    func connect() async throws {
        await cleanUp()
        await state.update(connectionStatus: .connecting)
        try await signalClient.connect(adaptiveStream: true)
    }
    
    private func cleanUp() async {}
}
