//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

class ControllerTestCase: StreamVideoTestCase, @unchecked Sendable {

    let user = User(id: "test")
    let callId = "123"
    let callType: String = .default
    let apiKey = "123"
    let videoConfig = VideoConfig.dummy()
    var callCid: String {
        "\(callType):\(callId)"
    }
}
