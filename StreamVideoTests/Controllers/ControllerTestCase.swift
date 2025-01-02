//
// Copyright © 2025 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

class ControllerTestCase: StreamVideoTestCase {

    let user = User(id: "test")
    let callId = "123"
    let callType: String = .default
    let apiKey = "123"
    let videoConfig = VideoConfig.dummy()
    var callCid: String {
        "\(callType):\(callId)"
    }
}
