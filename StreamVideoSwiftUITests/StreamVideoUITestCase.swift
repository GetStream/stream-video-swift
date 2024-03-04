//
// Copyright © 2024 Stream.io Inc. All rights reserved.
//

@testable import StreamVideoSwiftUI
@testable import StreamVideo
import StreamSwiftTestHelpers
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
    let snapshotVariants: [SnapshotVariant] = [.defaultLight, .defaultDark]
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        let streamVideo = StreamVideo.mock(httpClient: httpClient)
        streamVideoUI = StreamVideoUI(streamVideo: streamVideo)
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await streamVideoUI?.streamVideo.disconnect()
    }
}
