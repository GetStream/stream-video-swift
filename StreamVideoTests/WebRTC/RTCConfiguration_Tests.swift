//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideo
import StreamWebRTC
import XCTest

final class RTCConfiguration_Tests: XCTestCase {

    func test_rtcConfiguration_default() {
        // Given
        let iceServer = ICEServer(
            password: "martin",
            urls: ["test.com"],
            username: "martin"
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
