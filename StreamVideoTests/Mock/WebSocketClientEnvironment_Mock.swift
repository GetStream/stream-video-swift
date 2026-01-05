//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

extension WebSocketClient.Environment {
    static var mock: Self {
        .init(
            createPingController: WebSocketPingController_Mock.init,
            createEngine: WebSocketEngine_Mock.init,
            eventBatcherBuilder: { EventBatcher_Mock(handler: $0) }
        )
    }
}
