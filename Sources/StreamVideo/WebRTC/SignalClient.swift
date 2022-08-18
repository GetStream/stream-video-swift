//
// Copyright © 2022 Stream.io Inc. All rights reserved.
//

import Foundation
import WebRTC

class SignalClient {
    
    let signalService: Stream_Video_SignalServer
    let webSocketClient: WebSocketClient
    
    init(
        webSocketClient: WebSocketClient,
        httpClient: HTTPClient,
        apiKey: String,
        hostname: String,
        token: String
    ) {
        signalService = Stream_Video_SignalServer(
            httpClient: httpClient,
            apiKey: apiKey,
            hostname: hostname,
            token: token
        )
        self.webSocketClient = webSocketClient
    }
    
    // TODO: reconnectMode & adaptiveStream
    func connect(adaptiveStream: Bool) async throws {
        cleanUp()
        log.debug("Connecting to hostname: \(signalService.hostname)")
        try await connectWebSocket()
        log.debug("Connected to web socket")
    }
    
    private func connectWebSocket() async throws {
        try await withCheckedThrowingContinuation { continuation in
            webSocketClient.connect()
            webSocketClient.onConnect = {
                continuation.resume(returning: ())
            }
        }
    }
    
    private func cleanUp() {}
}
