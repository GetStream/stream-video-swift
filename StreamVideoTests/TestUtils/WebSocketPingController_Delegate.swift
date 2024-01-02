//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo

// A concrete `WebSocketPingControllerDelegate` implementation allowing capturing the delegate calls
final class WebSocketPingController_Delegate: WebSocketPingControllerDelegate {

    var sendPing_calledCount = 0
    var disconnectOnNoPongReceived_calledCount = 0

    func sendPing(healthCheckEvent: SendableEvent) {
        sendPing_calledCount += 1
    }
    
    func sendPing() {
        sendPing_calledCount += 1
    }
    
    func disconnectOnNoPongReceived() {
        disconnectOnNoPongReceived_calledCount += 1
    }
}
