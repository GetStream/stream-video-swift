//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import WebRTC
import XCTest

final class RTCConfiguration_Tests: XCTestCase {

    func test_rtcConfiguration_default() {
        // Given
        let iceServer = ICEServerConfig(
            urls: ["test.com"],
            username: "martin",
            password: "martin"
        )
        
        // When
        let rtcConfiguration = RTCConfiguration.makeConfiguration(with: [iceServer])
        
        // Then
        XCTAssert(rtcConfiguration.iceServers[0].urlStrings.contains("test.com"))
        XCTAssert(rtcConfiguration.iceServers[0].username == "martin")
        XCTAssert(rtcConfiguration.iceServers[0].credential == "martin")
        XCTAssert(rtcConfiguration.sdpSemantics == .unifiedPlan)
    }
    
}
