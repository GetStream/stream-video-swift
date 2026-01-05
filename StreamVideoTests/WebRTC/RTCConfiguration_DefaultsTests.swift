//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCConfiguration_DefaultsTests: XCTestCase, @unchecked Sendable {

    func test_makeConfiguration_returnsCorrectlyConfiguredResult() {
        let iceServer = ICEServer(password: .unique, urls: [], username: .unique)

        let configuration = RTCConfiguration.makeConfiguration(with: [iceServer])

        XCTAssertEqual(configuration.iceServers.count, 1)
        XCTAssertEqual(configuration.iceServers[0].username, iceServer.username)
        XCTAssertEqual(configuration.iceServers[0].credential, iceServer.password)
        XCTAssertEqual(configuration.sdpSemantics, .unifiedPlan)
        XCTAssertEqual(configuration.bundlePolicy, .maxBundle)
    }
}
