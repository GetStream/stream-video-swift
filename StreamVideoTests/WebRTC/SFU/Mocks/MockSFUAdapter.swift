//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC

extension SFUAdapter {
    static func mock(
        webSocketClientType: WebSocketClientType
    ) -> (
        sfuAdapter: SFUAdapter,
        mockService: MockSignalServer,
        mockWebSocketClient: MockWebSocketClient
    ) {
        let mockWebSocketClient = MockWebSocketClient(webSocketClientType: webSocketClientType)
        let mockService = MockSignalServer()
        let mockSFUAdapter = SFUAdapter(
            signalService: mockService,
            webSocket: mockWebSocketClient
        )
        return (
            sfuAdapter: mockSFUAdapter,
            mockService: mockService,
            mockWebSocketClient: mockWebSocketClient
        )
    }
}
