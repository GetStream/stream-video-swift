//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import XCTest

class ControllerTestCase: StreamVideoTestCase {

    let user = User(id: "test")
    let callId = "123"
    let callType: String = .default
    let apiKey = "123"
    let videoConfig = VideoConfig()
    var callCid: String {
        "\(callType):\(callId)"
    }

    func makeCallCoordinatorController() -> CallCoordinatorController_Mock {
        let defaultAPI = DefaultAPI(
            basePath: "https://example.com",
            transport: URLSessionTransport(urlSession: URLSession.shared),
            middlewares: [DefaultParams(apiKey: "key1")]
        )
        let callCoordinator = CallCoordinatorController_Mock(
            defaultAPI: defaultAPI,
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
