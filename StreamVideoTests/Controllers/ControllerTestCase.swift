//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

class ControllerTestCase: StreamVideoTestCase {

    let user = User(id: "test")
    let callId = "123"
    let callType = CallType.default
    let apiKey = "123"
    let videoConfig = VideoConfig()
    var callCid: String {
        "\(callType.name):\(callId)"
    }

    func makeCallCoordinatorController() -> CallCoordinatorController_Mock {
        let callCoordinator = CallCoordinatorController_Mock(
            httpClient: HTTPClient_Mock(),
            user: user,
            coordinatorInfo: CoordinatorInfo(
                apiKey: apiKey,
                hostname: "test.com",
                token: StreamVideo.mockToken.rawValue
            ),
            videoConfig: videoConfig
        )
        return callCoordinator
    }
}
