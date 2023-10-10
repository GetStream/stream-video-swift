//
// Copyright © 2023 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import XCTest

class StreamVideoUITestCase: XCTestCase {
    
    var streamVideoUI: StreamVideoUI?
    let httpClient: HTTPClient = HTTPClient_Mock()
    let spotlightParticipants = [1, 2, 3, 4]
    let gridParticipants = [1, 2, 3, 4, 5, 6, 7, 8, 9]
    let connectionQuality: [ConnectionQuality] = [.unknown, .poor, .good, .excellent]
    let callId = "test"
    let callType: String = .default
    var callCid: String { "\(callType):\(callId)" }
    let sizeThatFits = CGSize(width: 100, height: 100)
    
    override func setUp() {
        super.setUp()
        
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
        CALayer.swizzleShadow()
        animations(enabled: false)
    }

    open override func tearDown() {
        CALayer.revertSwizzleShadow()
        animations(enabled: true)
        super.tearDown()
    }

    func animations(enabled: Bool) {
        UIView.setAnimationsEnabled(enabled)
    }
}
